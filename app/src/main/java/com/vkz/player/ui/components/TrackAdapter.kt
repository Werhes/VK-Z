package com.vkz.player.ui.components

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.bumptech.glide.load.resource.bitmap.RoundedCorners
import com.bumptech.glide.request.RequestOptions
import com.vkz.player.R
import com.vkz.player.data.model.Track

class TrackAdapter(
    private val onTrackClick: (Track, Int) -> Unit,
    private val onTrackMenuClick: ((Track, Int) -> Unit)? = null,
    private val onFavoriteClick: ((Track, Int, Boolean) -> Unit)? = null
) : ListAdapter<Track, TrackAdapter.TrackViewHolder>(TrackDiffCallback()) {

    private var currentPlayingId: String? = null
    private val favoriteStates = mutableMapOf<String, Boolean>()

    fun setCurrentPlaying(trackKey: String?) {
        val oldKey = currentPlayingId
        currentPlayingId = trackKey
        if (oldKey != trackKey) {
            notifyItemRangeChanged(0, itemCount, PAYLOAD_PLAYING_STATE)
        }
    }

    fun updateFavoriteState(uniqueKey: String, isFavorite: Boolean) {
        favoriteStates[uniqueKey] = isFavorite
        for (i in 0 until itemCount) {
            if (getItem(i).getUniqueKey() == uniqueKey) {
                notifyItemChanged(i, PAYLOAD_FAVORITE_STATE)
                break
            }
        }
    }

    fun updateFavoriteStates(states: Map<String, Boolean>) {
        favoriteStates.putAll(states)
        notifyItemRangeChanged(0, itemCount, PAYLOAD_FAVORITE_STATE)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TrackViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_track, parent, false)
        return TrackViewHolder(view)
    }

    override fun onBindViewHolder(holder: TrackViewHolder, position: Int) {
        holder.bind(getItem(position), position)
    }

    override fun onBindViewHolder(
        holder: TrackViewHolder,
        position: Int,
        payloads: MutableList<Any>
    ) {
        if (payloads.contains(PAYLOAD_PLAYING_STATE)) {
            holder.updatePlayingState(getItem(position))
        } else if (payloads.contains(PAYLOAD_FAVORITE_STATE)) {
            holder.updateFavoriteIcon(getItem(position))
        } else {
            holder.bind(getItem(position), position)
        }
    }

    inner class TrackViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val coverImage: ImageView = itemView.findViewById(R.id.iv_track_cover)
        private val titleText: TextView = itemView.findViewById(R.id.tv_track_title)
        private val artistText: TextView = itemView.findViewById(R.id.tv_track_artist)
        private val durationText: TextView = itemView.findViewById(R.id.tv_track_duration)
        private val menuButton: ImageButton = itemView.findViewById(R.id.btn_track_menu)
        private val favoriteButton: ImageButton = itemView.findViewById(R.id.btn_track_favorite)
        private val playingIndicator: View = itemView.findViewById(R.id.view_playing_indicator)

        fun bind(track: Track, position: Int) {
            titleText.text = track.title
            artistText.text = track.artist
            durationText.text = track.getFormattedDuration()

            // Load cover image
            track.coverUrl?.let { url ->
                Glide.with(itemView.context)
                    .load(url)
                    .apply(
                        RequestOptions()
                            .placeholder(R.drawable.ic_music_note)
                            .error(R.drawable.ic_music_note)
                            .transform(RoundedCorners(8))
                    )
                    .into(coverImage)
            } ?: run {
                coverImage.setImageResource(R.drawable.ic_music_note)
            }

            updatePlayingState(track)
            updateFavoriteIcon(track)

            itemView.setOnClickListener {
                onTrackClick(track, position)
            }

            menuButton.setOnClickListener {
                onTrackMenuClick?.invoke(track, position)
            }

            favoriteButton.setOnClickListener {
                val isFav = favoriteStates[track.getUniqueKey()] ?: false
                onFavoriteClick?.invoke(track, position, isFav)
            }
        }

        fun updatePlayingState(track: Track) {
            val isPlaying = track.getUniqueKey() == currentPlayingId
            playingIndicator.visibility = if (isPlaying) View.VISIBLE else View.GONE
            titleText.alpha = if (isPlaying) 1.0f else 0.87f
        }

        fun updateFavoriteIcon(track: Track) {
            val isFav = favoriteStates[track.getUniqueKey()] ?: false
            favoriteButton.setImageResource(
                if (isFav) R.drawable.ic_favorite else R.drawable.ic_favorite_outline
            )
        }
    }

    class TrackDiffCallback : DiffUtil.ItemCallback<Track>() {
        override fun areItemsTheSame(oldItem: Track, newItem: Track): Boolean {
            return oldItem.getUniqueKey() == newItem.getUniqueKey()
        }

        override fun areContentsTheSame(oldItem: Track, newItem: Track): Boolean {
            return oldItem == newItem
        }
    }

    companion object {
        private const val PAYLOAD_PLAYING_STATE = "playing_state"
        private const val PAYLOAD_FAVORITE_STATE = "favorite_state"
    }
}