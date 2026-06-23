package com.vkz.player.ui.components

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.SeekBar
import android.widget.TextView
import com.bumptech.glide.Glide
import com.bumptech.glide.load.resource.bitmap.RoundedCorners
import com.bumptech.glide.request.RequestOptions
import com.vkz.player.R
import com.vkz.player.data.model.PlaybackState
import com.vkz.player.data.model.RepeatMode
import com.vkz.player.data.model.Track

class PlayerControlView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private var coverImage: ImageView
    private var titleText: TextView
    private var artistText: TextView
    private var playPauseButton: ImageButton
    private var nextButton: ImageButton
    private var prevButton: ImageButton
    private var seekBar: SeekBar
    private var currentTimeText: TextView
    private var totalTimeText: TextView
    private var repeatButton: ImageButton
    private var shuffleButton: ImageButton
    private var favoriteButton: ImageButton
    private var playerContent: View

    private var onPlayPauseClick: (() -> Unit)? = null
    private var onNextClick: (() -> Unit)? = null
    private var onPrevClick: (() -> Unit)? = null
    private var onSeek: ((Long) -> Unit)? = null
    private var onRepeatClick: (() -> Unit)? = null
    private var onShuffleClick: (() -> Unit)? = null
    private var onPlayerExpand: (() -> Unit)? = null
    private var onFavoriteClick: ((Boolean) -> Unit)? = null
    private var isUserSeeking = false
    private var currentTrack: Track? = null

    init {
        val view = LayoutInflater.from(context)
            .inflate(R.layout.view_player_controls, this, true)

        coverImage = view.findViewById(R.id.iv_player_cover)
        titleText = view.findViewById(R.id.tv_player_title)
        artistText = view.findViewById(R.id.tv_player_artist)
        playPauseButton = view.findViewById(R.id.btn_play_pause)
        nextButton = view.findViewById(R.id.btn_next)
        prevButton = view.findViewById(R.id.btn_previous)
        seekBar = view.findViewById(R.id.seek_bar)
        currentTimeText = view.findViewById(R.id.tv_current_time)
        totalTimeText = view.findViewById(R.id.tv_total_time)
        repeatButton = view.findViewById(R.id.btn_repeat)
        shuffleButton = view.findViewById(R.id.btn_shuffle)
        favoriteButton = view.findViewById(R.id.btn_favorite)
        playerContent = view.findViewById(R.id.player_content)

        setupListeners()
    }

    private fun setupListeners() {
        playPauseButton.setOnClickListener { onPlayPauseClick?.invoke() }
        nextButton.setOnClickListener { onNextClick?.invoke() }
        prevButton.setOnClickListener { onPrevClick?.invoke() }
        repeatButton.setOnClickListener { onRepeatClick?.invoke() }
        shuffleButton.setOnClickListener { onShuffleClick?.invoke() }
        playerContent.setOnClickListener { onPlayerExpand?.invoke() }
        favoriteButton.setOnClickListener {
            val isFav = favoriteButton.tag == "favorited"
            onFavoriteClick?.invoke(isFav as Boolean)
        }

        seekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    currentTimeText.text = formatDuration(progress.toLong())
                }
            }

            override fun onStartTrackingTouch(seekBar: SeekBar?) {
                isUserSeeking = true
            }

            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                isUserSeeking = false
                onSeek?.invoke(seekBar?.progress?.toLong() ?: 0L)
            }
        })
    }

    fun setOnPlayPauseClickListener(listener: () -> Unit) {
        onPlayPauseClick = listener
    }

    fun setOnNextClickListener(listener: () -> Unit) {
        onNextClick = listener
    }

    fun setOnPrevClickListener(listener: () -> Unit) {
        onPrevClick = listener
    }

    fun setOnSeekListener(listener: (Long) -> Unit) {
        onSeek = listener
    }

    fun setOnRepeatClickListener(listener: () -> Unit) {
        onRepeatClick = listener
    }

    fun setOnShuffleClickListener(listener: () -> Unit) {
        onShuffleClick = listener
    }

    fun setOnPlayerExpandListener(listener: () -> Unit) {
        onPlayerExpand = listener
    }

    fun setOnFavoriteClickListener(listener: (Boolean) -> Unit) {
        onFavoriteClick = listener
    }

    fun updateTrack(track: Track?) {
        currentTrack = track
        if (track == null) {
            visibility = View.GONE
            return
        }
        visibility = View.VISIBLE
        titleText.text = track.title
        artistText.text = track.artist

        track.coverUrl?.let { url ->
            Glide.with(context)
                .load(url)
                .apply(
                    RequestOptions()
                        .placeholder(R.drawable.ic_music_note)
                        .error(R.drawable.ic_music_note)
                        .transform(RoundedCorners(12))
                )
                .into(coverImage)
        } ?: run {
            coverImage.setImageResource(R.drawable.ic_music_note)
        }

        seekBar.max = track.duration * 1000
        totalTimeText.text = track.getFormattedDuration()
    }

    fun updateFavoriteState(isFavorite: Boolean) {
        favoriteButton.setImageResource(
            if (isFavorite) R.drawable.ic_favorite else R.drawable.ic_favorite_outline
        )
        favoriteButton.tag = if (isFavorite) "favorited" else "not_favorited"
    }

    fun updatePlaybackState(state: PlaybackState) {
        when (state) {
            PlaybackState.PLAYING -> {
                playPauseButton.setImageResource(R.drawable.ic_pause)
            }
            PlaybackState.PAUSED, PlaybackState.IDLE -> {
                playPauseButton.setImageResource(R.drawable.ic_play)
            }
            PlaybackState.LOADING -> {
                playPauseButton.setImageResource(R.drawable.ic_pause)
            }
            PlaybackState.ERROR -> {
                playPauseButton.setImageResource(R.drawable.ic_play)
            }
        }
    }

    fun updatePosition(position: Long) {
        if (!isUserSeeking) {
            seekBar.progress = position.toInt()
            currentTimeText.text = formatDuration(position)
        }
    }

    fun updateDuration(duration: Long) {
        seekBar.max = duration.toInt()
        totalTimeText.text = formatDuration(duration)
    }

    fun updateRepeatMode(mode: RepeatMode) {
        when (mode) {
            RepeatMode.NONE -> {
                repeatButton.setImageResource(R.drawable.ic_repeat)
                repeatButton.alpha = 0.5f
            }
            RepeatMode.ALL -> {
                repeatButton.setImageResource(R.drawable.ic_repeat)
                repeatButton.alpha = 1.0f
            }
            RepeatMode.ONE -> {
                repeatButton.setImageResource(R.drawable.ic_repeat_one)
                repeatButton.alpha = 1.0f
            }
        }
    }

    fun updateShuffleState(isShuffled: Boolean) {
        shuffleButton.alpha = if (isShuffled) 1.0f else 0.5f
    }

    fun showMiniPlayer(track: Track?) {
        if (track != null) {
            visibility = View.VISIBLE
            updateTrack(track)
        } else {
            visibility = View.GONE
        }
    }

    private fun formatDuration(millis: Long): String {
        val totalSeconds = millis / 1000
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return String.format("%d:%02d", minutes, seconds)
    }
}