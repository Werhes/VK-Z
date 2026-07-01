package com.werhes.vkz.player

import android.content.Context
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import com.werhes.vkz.data.model.PlayerState
import com.werhes.vkz.data.model.RepeatMode
import com.werhes.vkz.data.model.VKTrack
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

object PlayerManager {
    private var exoPlayer: ExoPlayer? = null
    private var positionJob: kotlinx.coroutines.Job? = null

    private val _currentTrack = MutableStateFlow<VKTrack?>(null)
    val currentTrack: StateFlow<VKTrack?> = _currentTrack.asStateFlow()

    private val _playerState = MutableStateFlow(PlayerState.STOPPED)
    val playerState: StateFlow<PlayerState> = _playerState.asStateFlow()

    private val _currentPosition = MutableStateFlow(0L)
    val currentPosition: StateFlow<Long> = _currentPosition.asStateFlow()

    private val _duration = MutableStateFlow(0L)
    val duration: StateFlow<Long> = _duration.asStateFlow()

    private val _queue = MutableStateFlow<List<VKTrack>>(emptyList())
    val queue: StateFlow<List<VKTrack>> = _queue.asStateFlow()

    private val _currentIndex = MutableStateFlow(0)
    val currentIndex: StateFlow<Int> = _currentIndex.asStateFlow()

    private val _repeatMode = MutableStateFlow(RepeatMode.ALL)
    val repeatMode: StateFlow<RepeatMode> = _repeatMode.asStateFlow()

    private val _isShuffled = MutableStateFlow(false)
    val isShuffled: StateFlow<Boolean> = _isShuffled.asStateFlow()

    private val _volume = MutableStateFlow(1f)
    val volume: StateFlow<Float> = _volume.asStateFlow()

    fun init(context: Context) {
        exoPlayer = ExoPlayer.Builder(context).build().apply {
            addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(state: Int) {
                    _playerState.value = when (state) {
                        Player.STATE_READY -> PlayerState.PLAYING
                        Player.STATE_BUFFERING -> PlayerState.LOADING
                        Player.STATE_ENDED -> {
                            handleTrackEnd()
                            PlayerState.STOPPED
                        }
                        else -> PlayerState.STOPPED
                    }
                }

                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    _playerState.value = if (isPlaying) PlayerState.PLAYING else PlayerState.PAUSED
                }
            })
        }

        // Position updates
        positionJob = CoroutineScope(Dispatchers.Main).launch {
            while (true) {
                delay(500)
                _currentPosition.value = exoPlayer?.currentPosition ?: 0
                _duration.value = exoPlayer?.duration ?: 0
            }
        }
    }

    fun playTrack(track: VKTrack) {
        _currentTrack.value = track
        _playerState.value = PlayerState.LOADING

        val mediaItem = MediaItem.fromUri(track.url ?: return)
        exoPlayer?.apply {
            setMediaItem(mediaItem)
            prepare()
            play()
        }
    }

    fun play() {
        exoPlayer?.play()
        _playerState.value = PlayerState.PLAYING
    }

    fun pause() {
        exoPlayer?.pause()
        _playerState.value = PlayerState.PAUSED
    }

    fun togglePlayPause() {
        if (exoPlayer?.isPlaying == true) pause() else play()
    }

    fun nextTrack() {
        val q = _queue.value
        if (q.isEmpty()) return

        val idx = if (_isShuffled.value) (0 until q.size).random()
        else (_currentIndex.value + 1) % q.size

        _currentIndex.value = idx
        playTrack(q[idx])
    }

    fun previousTrack() {
        val q = _queue.value
        if (q.isEmpty()) return

        if (_currentPosition.value > 3000) {
            exoPlayer?.seekTo(0)
            return
        }

        val idx = (_currentIndex.value - 1 + q.size) % q.size
        _currentIndex.value = idx
        playTrack(q[idx])
    }

    fun seekTo(position: Long) {
        exoPlayer?.seekTo(position)
    }

    fun setQueue(tracks: List<VKTrack>, startIndex: Int = 0) {
        _queue.value = tracks
        _currentIndex.value = startIndex
        if (tracks.isNotEmpty()) playTrack(tracks[startIndex])
    }

    fun addToQueue(track: VKTrack) {
        _queue.value = _queue.value + track
    }

    fun removeFromQueue(index: Int) {
        val q = _queue.value.toMutableList()
        if (index >= q.size) return
        q.removeAt(index)
        _queue.value = q
        if (index < _currentIndex.value) _currentIndex.value--
    }

    fun clearQueue() {
        _queue.value = emptyList()
        _currentIndex.value = 0
        exoPlayer?.stop()
        _currentTrack.value = null
        _playerState.value = PlayerState.STOPPED
    }

    fun toggleShuffle() {
        _isShuffled.value = !_isShuffled.value
    }

    fun toggleRepeatMode() {
        _repeatMode.value = when (_repeatMode.value) {
            RepeatMode.OFF -> RepeatMode.ALL
            RepeatMode.ALL -> RepeatMode.ONE
            RepeatMode.ONE -> RepeatMode.OFF
        }
    }

    fun setVolume(vol: Float) {
        _volume.value = vol
        exoPlayer?.volume = vol
    }

    private fun handleTrackEnd() {
        when (_repeatMode.value) {
            RepeatMode.ONE -> exoPlayer?.seekTo(0)
            RepeatMode.ALL -> nextTrack()
            RepeatMode.OFF -> {
                if (_currentIndex.value < _queue.value.size - 1) nextTrack()
                else _playerState.value = PlayerState.STOPPED
            }
        }
    }

    fun release() {
        positionJob?.cancel()
        exoPlayer?.release()
        exoPlayer = null
    }
}