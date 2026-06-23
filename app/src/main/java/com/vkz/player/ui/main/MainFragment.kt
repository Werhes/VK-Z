package com.vkz.player.ui.main

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.asLiveData
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.vkz.player.R
import com.vkz.player.VkZApplication
import com.vkz.player.data.model.Track
import com.vkz.player.service.AudioPlaybackService
import com.vkz.player.ui.components.PlayerControlView
import com.vkz.player.ui.components.TrackAdapter
import com.vkz.player.viewmodel.MainViewModel

class MainFragment : Fragment() {

    private lateinit var viewModel: MainViewModel
    private lateinit var trackAdapter: TrackAdapter
    private lateinit var recyclerView: RecyclerView
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var playerControl: PlayerControlView
    private lateinit var emptyView: View
    private lateinit var loadingView: View

    private var playbackService: AudioPlaybackService? = null
    private var serviceBound = false

    private val favoritesManager get() = VkZApplication.instance.favoritesManager

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as AudioPlaybackService.AudioBinder
            playbackService = binder.getService()
            serviceBound = true
            observePlaybackService()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            playbackService = null
            serviceBound = false
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val view = inflater.inflate(R.layout.fragment_main, container, false)

        viewModel = ViewModelProvider(requireActivity())[MainViewModel::class.java]

        recyclerView = view.findViewById(R.id.rv_tracks)
        swipeRefresh = view.findViewById(R.id.swipe_refresh)
        playerControl = view.findViewById(R.id.player_control)
        emptyView = view.findViewById(R.id.view_empty)
        loadingView = view.findViewById(R.id.view_loading)

        setupRecyclerView()
        setupSwipeRefresh()
        setupPlayerControl()
        observeViewModel()

        return view
    }

    override fun onStart() {
        super.onStart()
        bindPlaybackService()
    }

    override fun onStop() {
        super.onStop()
        if (serviceBound) {
            requireActivity().unbindService(serviceConnection)
            serviceBound = false
        }
    }

    private fun setupRecyclerView() {
        trackAdapter = TrackAdapter(
            onTrackClick = { track, index ->
                playTrack(track, index)
            },
            onTrackMenuClick = { track, index ->
                showTrackMenu(track, index)
            },
            onFavoriteClick = { track, _, isFav ->
                toggleFavorite(track, isFav)
            }
        )

        recyclerView.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = trackAdapter
            setHasFixedSize(true)
        }
    }

    private fun setupSwipeRefresh() {
        swipeRefresh.setOnRefreshListener {
            viewModel.refresh()
        }
        swipeRefresh.setColorSchemeResources(
            R.color.vk_blue,
            R.color.vk_blue_dark,
            R.color.accent
        )
    }

    private fun setupPlayerControl() {
        playerControl.setOnPlayPauseClickListener {
            playbackService?.togglePlayPause()
        }
        playerControl.setOnNextClickListener {
            playbackService?.playNext()
        }
        playerControl.setOnPrevClickListener {
            playbackService?.playPrevious()
        }
        playerControl.setOnSeekListener { position ->
            playbackService?.seekTo(position)
        }
        playerControl.setOnRepeatClickListener {
            playbackService?.let { service ->
                val currentMode = service.repeatMode.value
                val nextMode = when (currentMode) {
                    com.vkz.player.data.model.RepeatMode.NONE -> com.vkz.player.data.model.RepeatMode.ALL
                    com.vkz.player.data.model.RepeatMode.ALL -> com.vkz.player.data.model.RepeatMode.ONE
                    com.vkz.player.data.model.RepeatMode.ONE -> com.vkz.player.data.model.RepeatMode.NONE
                    else -> com.vkz.player.data.model.RepeatMode.NONE
                }
                service.setRepeatMode(nextMode)
            }
        }
        playerControl.setOnShuffleClickListener {
            playbackService?.toggleShuffle()
        }
        playerControl.setOnPlayerExpandListener {
            openPlayerFragment()
        }
        playerControl.setOnFavoriteClickListener { isFav ->
            val currentTrack = playbackService?.currentTrack?.value
            if (currentTrack != null) {
                toggleFavorite(currentTrack, isFav)
            }
        }
    }

    private fun observeViewModel() {
        viewModel.tracks.observe(viewLifecycleOwner) { tracks ->
            trackAdapter.submitList(tracks)
            emptyView.visibility = if (tracks.isEmpty() && !viewModel.isLoading.value!!) View.VISIBLE else View.GONE
            // Load favorite states for all tracks
            loadFavoriteStates(tracks)
        }

        viewModel.isLoading.observe(viewLifecycleOwner) { loading ->
            loadingView.visibility = if (loading && trackAdapter.itemCount == 0) View.VISIBLE else View.GONE
            if (!loading) {
                swipeRefresh.isRefreshing = false
            }
        }

        viewModel.error.observe(viewLifecycleOwner) { error ->
            error?.let {
                android.widget.Toast.makeText(requireContext(), it, android.widget.Toast.LENGTH_LONG).show()
                viewModel.clearError()
            }
        }
    }

    private fun observePlaybackService() {
        playbackService?.let { service ->
            service.currentTrack.observe(viewLifecycleOwner) { track ->
                playerControl.updateTrack(track)
                trackAdapter.setCurrentPlaying(track?.getUniqueKey())
                // Update favorite state in player control
                track?.let { updatePlayerFavoriteState(it) }
            }

            service.playbackState.observe(viewLifecycleOwner) { state ->
                playerControl.updatePlaybackState(state)
            }

            service.currentPosition.observe(viewLifecycleOwner) { position ->
                playerControl.updatePosition(position)
            }

            service.currentDuration.observe(viewLifecycleOwner) { duration ->
                playerControl.updateDuration(duration)
            }

            service.repeatMode.observe(viewLifecycleOwner) { mode ->
                playerControl.updateRepeatMode(mode)
            }

            service.isShuffled.observe(viewLifecycleOwner) { shuffled ->
                playerControl.updateShuffleState(shuffled)
            }
        }
    }

    private fun loadFavoriteStates(tracks: List<Track>) {
        for (track in tracks) {
            val key = track.getUniqueKey()
            favoritesManager.isFavoriteFlow(key).asLiveData().observe(viewLifecycleOwner) { isFav: Boolean ->
                trackAdapter.updateFavoriteState(key, isFav)
            }
        }
    }

    private fun updatePlayerFavoriteState(track: Track) {
        favoritesManager.isFavoriteFlow(track.getUniqueKey()).asLiveData().observe(viewLifecycleOwner) { isFav: Boolean ->
            playerControl.updateFavoriteState(isFav)
        }
    }

    private fun playTrack(track: Track, index: Int) {
        val tracks = viewModel.tracks.value ?: return

        val intent = Intent(requireContext(), AudioPlaybackService::class.java).apply {
            action = AudioPlaybackService.ACTION_PLAY
            putExtra(AudioPlaybackService.EXTRA_TRACK, track as java.io.Serializable)
            putExtra(AudioPlaybackService.EXTRA_INDEX, index)
            putExtra(AudioPlaybackService.EXTRA_PLAYLIST, ArrayList(tracks) as java.io.Serializable)
        }
        requireActivity().startForegroundService(intent)
    }

    private fun toggleFavorite(track: Track, currentlyFavorited: Boolean) {
        favoritesManager.toggleFavorite(track, currentlyFavorited)
        val message = if (currentlyFavorited) R.string.favorites_removed else R.string.favorites_added
        android.widget.Toast.makeText(requireContext(), message, android.widget.Toast.LENGTH_SHORT).show()
    }

    private fun showTrackMenu(track: Track, index: Int) {
        // Simple menu dialog for track options
        val options = arrayOf(
            if (track.isLiked) "Remove from favorites" else "Add to favorites",
            "Share",
            "Add to playlist"
        )

        androidx.appcompat.app.AlertDialog.Builder(requireContext())
            .setTitle(track.title)
            .setItems(options) { _, which ->
                when (which) {
                    0 -> toggleLike(track)
                    1 -> shareTrack(track)
                    2 -> addToPlaylist(track)
                }
            }
            .show()
    }

    private fun toggleLike(track: Track) {
        // Use the favorites manager instead of the old placeholder
        favoritesManager.isFavoriteFlow(track.getUniqueKey()).asLiveData().observe(viewLifecycleOwner) { isFav: Boolean ->
            toggleFavorite(track, isFav)
        }
    }

    private fun shareTrack(track: Track) {
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, "Listen to ${track.title} by ${track.artist} on VK Z")
            putExtra(Intent.EXTRA_SUBJECT, "${track.title} - ${track.artist}")
        }
        startActivity(Intent.createChooser(shareIntent, "Share track"))
    }

    private fun addToPlaylist(track: Track) {
        android.widget.Toast.makeText(
            requireContext(),
            "Add to playlist - coming soon",
            android.widget.Toast.LENGTH_SHORT
        ).show()
    }

    private fun openPlayerFragment() {
        parentFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, com.vkz.player.ui.player.PlayerFragment())
            .addToBackStack("player")
            .commit()
    }

    private fun bindPlaybackService() {
        val intent = Intent(requireContext(), AudioPlaybackService::class.java)
        requireActivity().bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }
}