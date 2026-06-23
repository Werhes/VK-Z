package com.vkz.player.data.cache

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface CacheDao {

    // ===== Cached Tracks =====

    @Query("SELECT * FROM cached_tracks ORDER BY date_added DESC")
    fun getAllCachedTracks(): Flow<List<CachedTrackEntity>>

    @Query("SELECT * FROM cached_tracks WHERE is_downloaded = 1 ORDER BY date_added DESC")
    fun getDownloadedTracks(): Flow<List<CachedTrackEntity>>

    @Query("SELECT * FROM cached_tracks WHERE unique_key = :uniqueKey LIMIT 1")
    suspend fun getCachedTrack(uniqueKey: String): CachedTrackEntity?

    @Query("SELECT * FROM cached_tracks WHERE unique_key = :uniqueKey LIMIT 1")
    fun getCachedTrackFlow(uniqueKey: String): Flow<CachedTrackEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTrack(track: CachedTrackEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTracks(tracks: List<CachedTrackEntity>)

    @Update
    suspend fun updateTrack(track: CachedTrackEntity)

    @Query("UPDATE cached_tracks SET is_downloaded = :downloaded, local_file_path = :filePath WHERE unique_key = :uniqueKey")
    suspend fun updateDownloadStatus(uniqueKey: String, downloaded: Boolean, filePath: String?)

    @Query("UPDATE cached_tracks SET last_played = :timestamp, play_count = play_count + 1 WHERE unique_key = :uniqueKey")
    suspend fun updatePlayStats(uniqueKey: String, timestamp: Long)

    @Delete
    suspend fun deleteTrack(track: CachedTrackEntity)

    @Query("DELETE FROM cached_tracks WHERE unique_key = :uniqueKey")
    suspend fun deleteTrackByKey(uniqueKey: String)

    @Query("DELETE FROM cached_tracks WHERE is_downloaded = 0")
    suspend fun clearMetadataOnly()

    @Query("DELETE FROM cached_tracks")
    suspend fun clearAllTracks()

    @Query("SELECT COUNT(*) FROM cached_tracks")
    fun getTrackCount(): Flow<Int>

    @Query("SELECT COUNT(*) FROM cached_tracks WHERE is_downloaded = 1")
    fun getDownloadedCount(): Flow<Int>

    @Query("SELECT SUM(duration) FROM cached_tracks WHERE is_downloaded = 1")
    fun getTotalDownloadedDuration(): Flow<Long?>

    // ===== Cached Playlists =====

    @Query("SELECT * FROM cached_playlists ORDER BY date_cached DESC")
    fun getAllCachedPlaylists(): Flow<List<CachedPlaylistEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPlaylist(playlist: CachedPlaylistEntity)

    @Query("DELETE FROM cached_playlists")
    suspend fun clearAllPlaylists()

    // ===== Download Queue =====

    @Query("SELECT * FROM download_queue ORDER BY date_added ASC")
    fun getDownloadQueue(): Flow<List<DownloadQueueEntity>>

    @Query("SELECT * FROM download_queue WHERE status = :status ORDER BY date_added ASC")
    fun getDownloadsByStatus(status: String): Flow<List<DownloadQueueEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addToQueue(item: DownloadQueueEntity)

    @Query("UPDATE download_queue SET status = :status, progress = :progress WHERE unique_key = :uniqueKey")
    suspend fun updateDownloadProgress(uniqueKey: String, status: String, progress: Int)

    @Query("DELETE FROM download_queue WHERE unique_key = :uniqueKey")
    suspend fun removeFromQueue(uniqueKey: String)

    @Query("DELETE FROM download_queue")
    suspend fun clearQueue()

    @Query("SELECT COUNT(*) FROM download_queue WHERE status = 'DOWNLOADING' OR status = 'PENDING'")
    fun getPendingDownloadCount(): Flow<Int>

    // ===== Favorite Tracks =====

    @Query("SELECT * FROM favorite_tracks ORDER BY date_added DESC")
    fun getAllFavorites(): Flow<List<FavoriteTrackEntity>>

    @Query("SELECT * FROM favorite_tracks ORDER BY date_added DESC")
    suspend fun getAllFavoritesList(): List<FavoriteTrackEntity>

    @Query("SELECT * FROM favorite_tracks WHERE unique_key = :uniqueKey LIMIT 1")
    suspend fun getFavorite(uniqueKey: String): FavoriteTrackEntity?

    @Query("SELECT EXISTS(SELECT 1 FROM favorite_tracks WHERE unique_key = :uniqueKey)")
    fun isFavoriteFlow(uniqueKey: String): Flow<Boolean>

    @Query("SELECT EXISTS(SELECT 1 FROM favorite_tracks WHERE unique_key = :uniqueKey)")
    suspend fun isFavorite(uniqueKey: String): Boolean

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addFavorite(track: FavoriteTrackEntity)

    @Query("DELETE FROM favorite_tracks WHERE unique_key = :uniqueKey")
    suspend fun removeFavorite(uniqueKey: String)

    @Query("DELETE FROM favorite_tracks")
    suspend fun clearAllFavorites()

    @Query("SELECT COUNT(*) FROM favorite_tracks")
    fun getFavoriteCount(): Flow<Int>
}