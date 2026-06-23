package com.vkz.player.data.model

import com.google.gson.annotations.SerializedName
import java.io.Serializable

/**
 * Catalog data wrapper for the Mix page
 */
data class CatalogData(
    val catalog: List<VkAudioCatalog> = emptyList(),
    val recommendations: List<Track> = emptyList(),
    val popular: List<Track> = emptyList()
)

/**
 * Catalog block types for UI rendering
 */
enum class CatalogBlockType {
    RECOMMENDATIONS,
    POPULAR,
    PLAYLISTS,
    NEW_RELEASES,
    MIX,
    DEFAULT
}

/**
 * VK API response wrapper
 */
data class VkResponse<T>(
    @SerializedName("response")
    val response: T? = null,

    @SerializedName("error")
    val error: VkError? = null
)

data class VkError(
    @SerializedName("error_code")
    val errorCode: Int = 0,

    @SerializedName("error_msg")
    val errorMsg: String = ""
)

/**
 * Audio track from VK API
 */
data class VkAudioItem(
    @SerializedName("id")
    val id: Long = 0,

    @SerializedName("owner_id")
    val ownerId: Long = 0,

    @SerializedName("artist")
    val artist: String = "",

    @SerializedName("title")
    val title: String = "",

    @SerializedName("duration")
    val duration: Int = 0,

    @SerializedName("url")
    val url: String = "",

    @SerializedName("album_id")
    val albumId: Long? = null,

    @SerializedName("album")
    val album: VkAlbum? = null,

    @SerializedName("genre_id")
    val genreId: Int = 0,

    @SerializedName("date")
    val date: Long = 0,

    @SerializedName("is_hq")
    val isHq: Boolean = false,

    @SerializedName("track_covers")
    val trackCovers: List<String>? = null,

    @SerializedName("main_artists")
    val mainArtists: List<VkArtist>? = null,

    @SerializedName("featured_artists")
    val featuredArtists: List<VkArtist>? = null
) {
    /**
     * Get best available cover URL
     */
    fun getCoverUrl(): String? {
        trackCovers?.let { if (it.isNotEmpty()) return it.last() }
        album?.thumb?.getBestUrl()?.let { return it }
        return null
    }

    /**
     * Unique key for the track
     */
    fun getUniqueKey(): String = "${ownerId}_${id}"
}

data class VkAlbum(
    @SerializedName("id")
    val id: Long = 0,

    @SerializedName("title")
    val title: String = "",

    @SerializedName("thumb")
    val thumb: VkPhoto? = null
)

data class VkPhoto(
    @SerializedName("id")
    val id: Long = 0,

    @SerializedName("album_id")
    val albumId: Long = 0,

    @SerializedName("owner_id")
    val ownerId: Long = 0,

    @SerializedName("sizes")
    val sizes: List<VkPhotoSize>? = null
) {
    fun getBestUrl(): String? {
        sizes?.let {
            if (it.isNotEmpty()) {
                // Return the largest size
                return it.last().url
            }
        }
        return null
    }
}

data class VkPhotoSize(
    @SerializedName("height")
    val height: Int = 0,

    @SerializedName("url")
    val url: String = "",

    @SerializedName("type")
    val type: String = "",

    @SerializedName("width")
    val width: Int = 0
)

data class VkArtist(
    @SerializedName("id")
    val id: Long = 0,

    @SerializedName("name")
    val name: String = "",

    @SerializedName("domain")
    val domain: String = ""
)

/**
 * Audio catalog block (playlists, recommendations, etc.)
 */
data class VkAudioCatalog(
    @SerializedName("id")
    val id: String = "",

    @SerializedName("type")
    val type: String = "",

    @SerializedName("title")
    val title: String = "",

    @SerializedName("items")
    val items: List<VkAudioItem>? = null,

    @SerializedName("audios")
    val audios: List<VkAudioItem>? = null,

    @SerializedName("playlists")
    val playlists: List<VkPlaylist>? = null
)

/**
 * VK Playlist
 */
data class VkPlaylist(
    @SerializedName("id")
    val id: Long = 0,

    @SerializedName("owner_id")
    val ownerId: Long = 0,

    @SerializedName("title")
    val title: String = "",

    @SerializedName("description")
    val description: String = "",

    @SerializedName("count")
    val count: Int = 0,

    @SerializedName("plays")
    val plays: Int = 0,

    @SerializedName("photo")
    val photo: VkPhoto? = null,

    @SerializedName("thumb")
    val thumb: VkPhoto? = null,

    @SerializedName("listeners")
    val listeners: Int = 0,

    @SerializedName("genre")
    val genre: String = "",

    @SerializedName("access_key")
    val accessKey: String? = null
) {
    fun getCoverUrl(): String? {
        photo?.getBestUrl()?.let { return it }
        thumb?.getBestUrl()?.let { return it }
        return null
    }
}

/**
 * Audio catalog response
 */
data class VkAudioCatalogResponse(
    @SerializedName("items")
    val items: List<VkAudioCatalog>? = null,

    @SerializedName("next_from")
    val nextFrom: String? = null
)

/**
 * Audio search results
 */
data class VkAudioSearchResponse(
    @SerializedName("items")
    val items: List<VkAudioItem> = emptyList(),

    @SerializedName("count")
    val count: Int = 0,

    @SerializedName("next_from")
    val nextFrom: String? = null
)

/**
 * User's audio list
 */
data class VkAudioGetResponse(
    @SerializedName("items")
    val items: List<VkAudioItem> = emptyList(),

    @SerializedName("count")
    val count: Int = 0,

    @SerializedName("next_from")
    val nextFrom: String? = null
)

/**
 * Local representation of a track with playback state
 */
data class Track(
    val id: Long,
    val ownerId: Long,
    val title: String,
    val artist: String,
    val duration: Int,
    val url: String,
    val coverUrl: String?,
    val albumTitle: String? = null,
    val isHq: Boolean = false,
    val isPlaying: Boolean = false,
    val isLiked: Boolean = false
) : Serializable {
    companion object {
        fun fromVkAudioItem(item: VkAudioItem): Track {
            return Track(
                id = item.id,
                ownerId = item.ownerId,
                title = item.title,
                artist = item.artist,
                duration = item.duration,
                url = item.url,
                coverUrl = item.getCoverUrl(),
                albumTitle = item.album?.title,
                isHq = item.isHq
            )
        }
    }

    fun getUniqueKey(): String = "${ownerId}_${id}"

    /**
     * Format duration as mm:ss
     */
    fun getFormattedDuration(): String {
        val minutes = duration / 60
        val seconds = duration % 60
        return String.format("%d:%02d", minutes, seconds)
    }
}

/**
 * Playback state
 */
enum class PlaybackState {
    IDLE,
    LOADING,
    PLAYING,
    PAUSED,
    ERROR
}

/**
 * Repeat mode
 */
enum class RepeatMode {
    NONE,
    ALL,
    ONE
}

/**
 * Shuffle mode
 */
data class ShuffleState(
    val isShuffled: Boolean = false,
    val shuffledOrder: List<Int> = emptyList()
)