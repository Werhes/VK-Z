package com.vkz.player.ui.mix

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.IBinder
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.asLiveData
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.LinearSnapHelper
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.vkz.player.R
import com.vkz.player.VkZApplication
import com.vkz.player.data.model.Track
import com.vkz.player.service.AudioPlaybackService
import com.vkz.player.ui.components.HorizontalTrackAdapter
import com.vkz.player.ui.components.PlayerControlView
import com.vkz.player.viewmodel.CatalogBlock
import com.vkz.player.viewmodel.MixViewModel

class MixFragment : Fragment() {

    private lateinit var viewModel: MixViewModel
    private lateinit var swipeRefresh: SwipeRefreshLayout
    private lateinit var blocksRecyclerView: RecyclerView
    private lateinit var playerControl: PlayerControlView
    private lateinit var loadingView: View
    private lateinit var emptyView: View

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
        val view = inflater.inflate(R.layout.fragment_mix, container, false)

        viewModel = ViewModelProvider(requireActivity())[MixViewModel::class.java]

        swipeRefresh = view.findViewById(R.id.swipe_refresh_mix)
        blocksRecyclerView = view.findViewById(R.id.rv_mix_blocks)
        playerControl = view.findViewById(R.id.player_control)
        loadingView = view.findViewById(R.id.view_mix_loading)
        emptyView = view.findViewById(R.id.view_mix_empty)

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
        blocksRecyclerView.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = CatalogBlocksAdapter()
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
        viewModel.catalogBlocks.observe(viewLifecycleOwner) { blocks ->
            (blocksRecyclerView.adapter as? CatalogBlocksAdapter)?.submitBlocks(blocks)
            emptyView.visibility = if (blocks.isEmpty() && !viewModel.isLoading.value!!) View.VISIBLE else View.GONE
        }

        viewModel.isLoading.observe(viewLifecycleOwner) { loading ->
            loadingView.visibility = if (loading) View.VISIBLE else View.GONE
            if (!loading) {
                swipeRefresh.isRefreshing = false
            }
        }

        viewModel.isRefreshing.observe(viewLifecycleOwner) { refreshing ->
            swipeRefresh.isRefreshing = refreshing
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

    private fun updatePlayerFavoriteState(track: Track) {
        favoritesManager.isFavoriteFlow(track.getUniqueKey()).asLiveData().observe(viewLifecycleOwner) { isFav: Boolean ->
            playerControl.updateFavoriteState(isFav)
        }
    }

    private fun toggleFavorite(track: Track, currentlyFavorited: Boolean) {
        favoritesManager.toggleFavorite(track, currentlyFavorited)
        val message = if (currentlyFavorited) R.string.favorites_removed else R.string.favorites_added
        android.widget.Toast.makeText(requireContext(), message, android.widget.Toast.LENGTH_SHORT).show()
    }

    private fun playTrack(track: Track, tracks: List<Track>, index: Int) {
        val intent = Intent(requireContext(), AudioPlaybackService::class.java).apply {
            action = AudioPlaybackService.ACTION_PLAY
            putExtra(AudioPlaybackService.EXTRA_TRACK, track as java.io.Serializable)
            putExtra(AudioPlaybackService.EXTRA_INDEX, index)
            putExtra(AudioPlaybackService.EXTRA_PLAYLIST, ArrayList(tracks) as java.io.Serializable)
        }
        requireActivity().startForegroundService(intent)
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

    /**
     * Adapter for catalog blocks (vertical list of horizontal track rows)
     */
    inner class CatalogBlocksAdapter : RecyclerView.Adapter<CatalogBlocksAdapter.BlockViewHolder>() {

        private var blocks: List<CatalogBlock> = emptyList()

        fun submitBlocks(newBlocks: List<CatalogBlock>) {
            blocks = newBlocks
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): BlockViewHolder {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.item_catalog_block, parent, false)
            return BlockViewHolder(view)
        }

        override fun onBindViewHolder(holder: BlockViewHolder, position: Int) {
            holder.bind(blocks[position])
        }

        override fun getItemCount(): Int = blocks.size

        inner class BlockViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
            private val blockTitle: TextView = itemView.findViewById(R.id.tv_block_title)
            private val tracksRecyclerView: RecyclerView = itemView.findViewById(R.id.rv_block_tracks)

            fun bind(block: CatalogBlock) {
                blockTitle.text = block.title

                val adapter = HorizontalTrackAdapter(
                    onTrackClick = { track, index ->
                        playTrack(track, block.tracks, index)
                    }
                )

                tracksRecyclerView.apply {
                    layoutManager = LinearLayoutManager(
                        itemView.context,
                        LinearLayoutManager.HORIZONTAL,
                        false
                    )
                    this@apply.adapter = adapter
                    // Snap helper for smooth horizontal scrolling
                    LinearSnapHelper().attachToRecyclerView(this)
                }

                adapter.submitList(block.tracks)
            }
        }
    }
}