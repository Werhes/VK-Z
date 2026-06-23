package com.vkz.player.service

import android.app.PendingIntent
import android.content.Intent
import android.graphics.Bitmap
import android.os.Binder
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.bumptech.glide.Glide
import com.vkz.player.MainActivity
import com.vkz.player.R
import com.vkz.player.VkZApplication
import com.vkz.player.data.model.PlaybackState
import com.vkz.player.data.model.RepeatMode
import com.vkz.player.data.model.Track
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit

class AudioPlaybackService : BaseAudioService() {

    private val binder = AudioBinder()
    private var exoPlayer: ExoPlayer? = null
    private var mediaSession: MediaSession? = null

    private val _playbackState = MutableLiveData(PlaybackState.IDLE)
    val playbackState: LiveData<PlaybackState> = _playbackState

    private val _currentTrack = MutableLiveData<Track?>()
    val currentTrack: LiveData<Track?> = _currentTrack

    private val _currentPosition = MutableLiveData(0L)
    val currentPosition: LiveData<Long> = _currentPosition

    private val _currentDuration = MutableLiveData(0L)
    val currentDuration: LiveData<Long> = _currentDuration

    private val _playlist = MutableLiveData<List<Track>>(emptyList())
    val playlist: LiveData<List<Track>> = _playlist

    private val _currentIndex = MutableLiveData(-1)
    val currentIndex: LiveData<Int> = _currentIndex

    private val _repeatMode = MutableLiveData(RepeatMode.NONE)
    val repeatMode: LiveData<RepeatMode> = _repeatMode

    private val _isShuffled = MutableLiveData(false)
    val isShuffled: LiveData<Boolean> = _isShuffled

    private var positionUpdateJob: Job? = null
    private var currentCoverBitmap: Bitmap? = null
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    inner class AudioBinder : Binder() {
        fun getService(): AudioPlaybackService = this@AudioPlaybackService
    }

    override fun onCreate() {
        super.onCreate()
        initializePlayer()
        initializeMediaSession()
    }

    private fun initializePlayer() {
        exoPlayer = ExoPlayer.Builder(this).build().apply {
            addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(state: Int) {
                    when (state) {
                        Player.STATE_IDLE -> _playbackState.postValue(PlaybackState.IDLE)
                        Player.STATE_BUFFERING -> _playbackState.postValue(PlaybackState.LOADING)
                        Player.STATE_READY -> {
                            if (playWhenReady) {
                                _playbackState.postValue(PlaybackState.PLAYING)
                            } else {
                                _playbackState.postValue(PlaybackState.PAUSED)
                            }
                        }
                        Player.STATE_ENDED -> {
                            onTrackEnded()
                        }
                    }
                }

                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    if (isPlaying) {
                        startPositionUpdates()
                    } else {
                        stopPositionUpdates()
                    }
                    updateNotification()
                }

                override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
                    val index = exoPlayer?.currentMediaItemIndex ?: return
                    if (index in _playlist.value?.indices ?: emptyList<Int>()) {
                        _currentIndex.postValue(index)
                        _currentTrack.postValue(_playlist.value?.get(index))
                        _currentDuration.postValue(exoPlayer?.duration ?: 0L)
                        loadCoverForNotification(_playlist.value?.get(index))
                        updateNotification()
                    }
                }
            })
        }
    }

    private fun initializeMediaSession() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        exoPlayer?.let { player ->
            mediaSession = MediaSession.Builder(this, player)
                .setSessionActivity(pendingIntent)
                .build()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY -> {
                val track = intent.getSerializableExtra(EXTRA_TRACK) as? Track
                @Suppress("UNCHECKED_CAST")
                val playlist = intent.getSerializableExtra(EXTRA_PLAYLIST) as? List<Track>
                val startIndex = intent.getIntExtra(EXTRA_INDEX, 0)
                if (track != null) {
                    playTrack(track, playlist ?: listOf(track), startIndex)
                }
            }
            ACTION_TOGGLE -> togglePlayPause()
            ACTION_NEXT -> playNext()
            ACTION_PREVIOUS -> playPrevious()
            ACTION_STOP -> stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder = binder

    fun playTrack(track: Track, tracks: List<Track>, index: Int) {
        _playlist.value = tracks
        _currentIndex.value = index
        _currentTrack.value = track
        _currentDuration.value = track.duration * 1000L

        // Acquire WakeLock to keep CPU running when screen is off
        acquireWakeLock()

        // Cache track metadata in background
        serviceScope.launch {
            VkZApplication.instance.cacheManager.cacheTrackMetadata(track)
        }

        exoPlayer?.apply {
            stop()
            clearMediaItems()

            tracks.forEach { t ->
                // Check if track is cached locally
                val uri = runBlocking {
                    val localPath = VkZApplication.instance.cacheManager.getLocalTrackPath(t)
                    if (localPath != null) {
                        android.net.Uri.fromFile(java.io.File(localPath))
                    } else {
                        android.net.Uri.parse(t.url)
                    }
                }

                val mediaItem = MediaItem.Builder()
                    .setMediaId(t.getUniqueKey())
                    .setUri(uri)
                    .setMediaMetadata(
                        MediaMetadata.Builder()
                            .setTitle(t.title)
                            .setArtist(t.artist)
                            .build()
                    )
                    .build()
                addMediaItem(mediaItem)
            }

            seekTo(index, 0)
            prepare()
            play()
        }

        // Update play stats
        serviceScope.launch {
            VkZApplication.instance.cacheManager.updatePlayStats(track.getUniqueKey())
        }

        startForeground(NOTIFICATION_ID, createNotification(track))
    }

    fun togglePlayPause() {
        exoPlayer?.let {
            if (it.isPlaying) {
                it.pause()
                // Release WakeLock when pausing
                releaseWakeLock()
            } else {
                // Re-acquire WakeLock when resuming
                acquireWakeLock()
                it.play()
            }
        }
    }

    fun resume() {
        // Re-acquire WakeLock when resuming playback
        acquireWakeLock()
        exoPlayer?.play()
    }

    fun pause() {
        exoPlayer?.pause()
        // Release WakeLock when paused to save battery
        releaseWakeLock()
    }

    fun playNext() {
        exoPlayer?.let { player ->
            val nextIndex = player.currentMediaItemIndex + 1
            if (nextIndex < player.mediaItemCount) {
                player.seekTo(nextIndex, 0)
            } else {
                when (_repeatMode.value) {
                    RepeatMode.ALL -> player.seekTo(0, 0)
                    RepeatMode.ONE -> player.seekTo(player.currentMediaItemIndex, 0)
                    RepeatMode.NONE -> {
                        pause()
                        seekTo(0)
                        _playbackState.postValue(PlaybackState.IDLE)
                    }
                    else -> {
                        pause()
                        seekTo(0)
                        _playbackState.postValue(PlaybackState.IDLE)
                    }
                }
            }
        }
    }

    fun playPrevious() {
        exoPlayer?.let { player ->
            val prevIndex = player.currentMediaItemIndex - 1
            if (prevIndex >= 0) {
                player.seekTo(prevIndex, 0)
            } else {
                player.seekTo(0, 0)
            }
        }
    }

    fun seekTo(position: Long) {
        exoPlayer?.seekTo(position)
        _currentPosition.postValue(position)
    }

    fun setRepeatMode(mode: RepeatMode) {
        _repeatMode.value = mode
        exoPlayer?.repeatMode = when (mode) {
            RepeatMode.NONE -> Player.REPEAT_MODE_OFF
            RepeatMode.ALL -> Player.REPEAT_MODE_ALL
            RepeatMode.ONE -> Player.REPEAT_MODE_ONE
        }
    }

    fun toggleShuffle() {
        exoPlayer?.let { player ->
            val newState = !(_isShuffled.value ?: false)
            player.shuffleModeEnabled = newState
            _isShuffled.value = newState
        }
    }

    fun setPlaylist(tracks: List<Track>, startIndex: Int = 0) {
        if (tracks.isNotEmpty()) {
            playTrack(tracks[startIndex], tracks, startIndex)
        }
    }

    private fun onTrackEnded() {
        when (_repeatMode.value) {
            RepeatMode.ONE -> {
                exoPlayer?.seekTo(0)
                exoPlayer?.play()
            }
            else -> playNext()
        }
    }

    private fun startPositionUpdates() {
        positionUpdateJob?.cancel()
        positionUpdateJob = serviceScope.launch {
            while (isActive) {
                exoPlayer?.let {
                    _currentPosition.postValue(it.currentPosition)
                    _currentDuration.postValue(it.duration)
                }
                delay(250)
            }
        }
    }

    private fun stopPositionUpdates() {
        positionUpdateJob?.cancel()
    }

    private fun loadCoverForNotification(track: Track?) {
        track?.coverUrl?.let { url ->
            serviceScope.launch {
                try {
                    val bitmap = withContext(Dispatchers.IO) {
                        Glide.with(this@AudioPlaybackService)
                            .asBitmap()
                            .load(url)
                            .submit(300, 300)
                            .get()
                    }
                    currentCoverBitmap = bitmap
                    updateNotification()
                } catch (e: Exception) {
                    currentCoverBitmap = null
                }
            }
        } ?: run { currentCoverBitmap = null }
    }

    private fun createNotification(track: Track): android.app.Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val prevIntent = Intent(this, AudioPlaybackService::class.java).apply {
            action = ACTION_PREVIOUS
        }
        val prevPendingIntent = PendingIntent.getService(
            this, 1, prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val toggleIntent = Intent(this, AudioPlaybackService::class.java).apply {
            action = ACTION_TOGGLE
        }
        val togglePendingIntent = PendingIntent.getService(
            this, 2, toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val nextIntent = Intent(this, AudioPlaybackService::class.java).apply {
            action = ACTION_NEXT
        }
        val nextPendingIntent = PendingIntent.getService(
            this, 3, nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, AudioPlaybackService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 4, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val isPlaying = exoPlayer?.isPlaying == true

        return NotificationCompat.Builder(this, VkZApplication.NOTIFICATION_CHANNEL_ID)
            .setContentTitle(track.title)
            .setContentText(track.artist)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(isPlaying)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setLargeIcon(currentCoverBitmap)
            .addAction(R.drawable.ic_skip_previous, "Previous", prevPendingIntent)
            .addAction(
                if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play,
                if (isPlaying) "Pause" else "Play",
                togglePendingIntent
            )
            .addAction(R.drawable.ic_skip_next, "Next", nextPendingIntent)
            .addAction(R.drawable.ic_close, "Stop", stopPendingIntent)
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(mediaSession?.sessionCompatToken)
                    .setShowActionsInCompactView(0, 1, 2)
                    .setShowCancelButton(true)
                    .setCancelButtonIntent(stopPendingIntent)
            )
            .build()
    }

    private fun updateNotification() {
        _currentTrack.value?.let { track ->
            val notification = createNotification(track)
            val notificationManager = getSystemService(android.app.NotificationManager::class.java)
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        positionUpdateJob?.cancel()
        serviceScope.cancel()
        mediaSession?.release()
        mediaSession = null
        exoPlayer?.release()
        exoPlayer = null
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    companion object {
        const val ACTION_PLAY = "com.vkz.player.action.PLAY"
        const val ACTION_TOGGLE = "com.vkz.player.action.TOGGLE"
        const val ACTION_NEXT = "com.vkz.player.action.NEXT"
        const val ACTION_PREVIOUS = "com.vkz.player.action.PREVIOUS"
        const val ACTION_STOP = "com.vkz.player.action.STOP"
        const val EXTRA_TRACK = "extra_track"
        const val EXTRA_PLAYLIST = "extra_playlist"
        const val EXTRA_INDEX = "extra_index"
        const val NOTIFICATION_ID = 1001
    }
}