package com.vkz.player.ui.components

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
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

/**
 * Horizontal track adapter for catalog blocks (Mix page)
 * Shows tracks as cards with cover art
 */
class HorizontalTrackAdapter(
    private val onTrackClick: (Track, Int) -> Unit
) : ListAdapter<Track, HorizontalTrackAdapter.HorizontalTrackViewHolder>(TrackDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): HorizontalTrackViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_track_horizontal, parent, false)
        return HorizontalTrackViewHolder(view)
    }

    override fun onBindViewHolder(holder: HorizontalTrackViewHolder, position: Int) {
        holder.bind(getItem(position), position)
    }

    inner class HorizontalTrackViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val coverImage: ImageView = itemView.findViewById(R.id.iv_track_cover)
        private val titleText: TextView = itemView.findViewById(R.id.tv_track_title)
        private val artistText: TextView = itemView.findViewById(R.id.tv_track_artist)

        fun bind(track: Track, position: Int) {
            titleText.text = track.title
            artistText.text = track.artist

            track.coverUrl?.let { url ->
                Glide.with(itemView.context)
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

            itemView.setOnClickListener {
                onTrackClick(track, position)
            }
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
}