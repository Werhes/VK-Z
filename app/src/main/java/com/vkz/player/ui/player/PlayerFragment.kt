package com.vkz.player.ui.player

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
import androidx.lifecycle.asLiveData
import com.bumptech.glide.Glide
import com.bumptech.glide.load.resource.bitmap.RoundedCorners
import com.bumptech.glide.request.RequestOptions
import com.vkz.player.R
import com.vkz.player.VkZApplication
import com.vkz.player.data.model.PlaybackState
import com.vkz.player.data.model.RepeatMode
import com.vkz.player.data.model.Track
import com.vkz.player.service.AudioPlaybackService
import com.vkz.player.ui.components.PlayerControlView

class PlayerFragment : Fragment() {

    private lateinit var playerControl: PlayerControlView
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
        val view = inflater.inflate(R.layout.fragment_player, container, false)

        playerControl = view.findViewById(R.id.player_control_expanded)

        setupPlayerControl()

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
                    RepeatMode.NONE -> RepeatMode.ALL
                    RepeatMode.ALL -> RepeatMode.ONE
                    RepeatMode.ONE -> RepeatMode.NONE
                    else -> RepeatMode.NONE
                }
                service.setRepeatMode(nextMode)
            }
        }
        playerControl.setOnShuffleClickListener {
            playbackService?.toggleShuffle()
        }
        playerControl.setOnFavoriteClickListener { isFav ->
            val currentTrack = playbackService?.currentTrack?.value
            if (currentTrack != null) {
                toggleFavorite(currentTrack, isFav)
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

    private fun bindPlaybackService() {
        val intent = Intent(requireContext(), AudioPlaybackService::class.java)
        requireActivity().bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }
}