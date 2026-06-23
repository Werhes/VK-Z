package com.vkz.player.data.cache

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Room entity for cached track metadata
 */
@Entity(
    tableName = "cached_tracks",
    indices = [Index(value = ["unique_key"], unique = true)]
)
data class CachedTrackEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    @ColumnInfo(name = "unique_key")
    val uniqueKey: String,

    @ColumnInfo(name = "track_id")
    val trackId: Long,

    @ColumnInfo(name = "owner_id")
    val ownerId: Long,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "artist")
    val artist: String,

    @ColumnInfo(name = "duration")
    val duration: Int,

    @ColumnInfo(name = "url")
    val url: String,

    @ColumnInfo(name = "cover_url")
    val coverUrl: String?,

    @ColumnInfo(name = "album_title")
    val albumTitle: String?,

    @ColumnInfo(name = "is_hq")
    val isHq: Boolean = false,

    @ColumnInfo(name = "is_downloaded")
    val isDownloaded: Boolean = false,

    @ColumnInfo(name = "local_file_path")
    val localFilePath: String? = null,

    @ColumnInfo(name = "date_added")
    val dateAdded: Long = System.currentTimeMillis(),

    @ColumnInfo(name = "last_played")
    val lastPlayed: Long? = null,

    @ColumnInfo(name = "play_count")
    val playCount: Int = 0
)

/**
 * Room entity for cached playlists
 */
@Entity(
    tableName = "cached_playlists",
    indices = [Index(value = ["playlist_key"], unique = true)]
)
data class CachedPlaylistEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    @ColumnInfo(name = "playlist_key")
    val playlistKey: String,

    @ColumnInfo(name = "playlist_id")
    val playlistId: Long,

    @ColumnInfo(name = "owner_id")
    val ownerId: Long,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "description")
    val description: String?,

    @ColumnInfo(name = "cover_url")
    val coverUrl: String?,

    @ColumnInfo(name = "track_count")
    val trackCount: Int = 0,

    @ColumnInfo(name = "date_cached")
    val dateCached: Long = System.currentTimeMillis()
)

/**
 * Room entity for download queue
 */
@Entity(
    tableName = "download_queue",
    indices = [Index(value = ["unique_key"], unique = true)]
)
data class DownloadQueueEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    @ColumnInfo(name = "unique_key")
    val uniqueKey: String,

    @ColumnInfo(name = "track_id")
    val trackId: Long,

    @ColumnInfo(name = "owner_id")
    val ownerId: Long,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "artist")
    val artist: String,

    @ColumnInfo(name = "url")
    val url: String,

    @ColumnInfo(name = "cover_url")
    val coverUrl: String?,

    @ColumnInfo(name = "duration")
    val duration: Int,

    @ColumnInfo(name = "status")
    val status: String = DownloadStatus.PENDING.name,

    @ColumnInfo(name = "progress")
    val progress: Int = 0,

    @ColumnInfo(name = "date_added")
    val dateAdded: Long = System.currentTimeMillis()
)

enum class DownloadStatus {
    PENDING,
    DOWNLOADING,
    COMPLETED,
    FAILED,
    CANCELLED
}

/**
 * Room entity for favorite tracks
 */
@Entity(
    tableName = "favorite_tracks",
    indices = [Index(value = ["unique_key"], unique = true)]
)
data class FavoriteTrackEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    @ColumnInfo(name = "unique_key")
    val uniqueKey: String,

    @ColumnInfo(name = "track_id")
    val trackId: Long,

    @ColumnInfo(name = "owner_id")
    val ownerId: Long,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "artist")
    val artist: String,

    @ColumnInfo(name = "duration")
    val duration: Int,

    @ColumnInfo(name = "url")
    val url: String,

    @ColumnInfo(name = "cover_url")
    val coverUrl: String?,

    @ColumnInfo(name = "album_title")
    val albumTitle: String?,

    @ColumnInfo(name = "date_added")
    val dateAdded: Long = System.currentTimeMillis()
)