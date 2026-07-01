package com.werhes.vkz.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class VKTrack(
    val id: Int,
    @SerialName("owner_id") val ownerId: Int,
    val artist: String,
    val title: String,
    val duration: Int,
    val url: String? = null,
    @SerialName("album_id") val albumId: Int? = null,
    @SerialName("album_title") val albumTitle: String? = null,
    @SerialName("track_covers") val trackCovers: List<String>? = null,
    @SerialName("is_explicit") val isExplicit: Boolean? = null,
    @SerialName("is_hq") val isHq: Boolean? = null
) {
    val coverUrl: String? get() = trackCovers?.lastOrNull()
    val formattedDuration: String
        get() {
            val minutes = duration / 60
            val seconds = duration % 60
            return "%d:%02d".format(minutes, seconds)
        }
}

@Serializable
data class VKPlaylist(
    val id: Int,
    @SerialName("owner_id") val ownerId: Int,
    val title: String,
    val description: String? = null,
    val tracks: List<VKTrack>? = null,
    @SerialName("track_count") val trackCount: Int,
    @SerialName("photo_url") val photoUrl: String? = null,
    @SerialName("access_key") val accessKey: String? = null
) {
    val coverUrl: String? get() = photoUrl
}

@Serializable
data class VKMix(
    val id: String,
    val title: String,
    val subtitle: String? = null,
    val description: String? = null,
    @SerialName("cover_url") val coverUrl: String? = null,
    val color: String? = null,
    val tracks: List<VKTrack>? = null,
    @SerialName("track_count") val trackCount: Int? = null,
    val artists: List<String>? = null
)

@Serializable
data class VKApiResponse<T>(
    val response: T? = null,
    val error: VKApiError? = null
)

@Serializable
data class VKApiError(
    @SerialName("error_code") val errorCode: Int,
    @SerialName("error_msg") val errorMsg: String
)

@Serializable
data class VKMusicResponse(
    val count: Int,
    val items: List<VKTrack>
)

@Serializable
data class VKPlaylistsResponse(
    val count: Int,
    val items: List<VKPlaylist>
)

@Serializable
data class VKSearchResponse(
    val count: Int,
    val items: List<VKTrack>
)

@Serializable
data class VKMixResponse(
    val count: Int,
    val items: List<VKMix>
)

@Serializable
data class VKMixTracksResponse(
    val count: Int,
    val items: List<VKTrack>
)

enum class PlayerState {
    STOPPED, PLAYING, PAUSED, LOADING
}

enum class RepeatMode {
    OFF, ALL, ONE
}