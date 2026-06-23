package com.vkz.player.data.cache

import android.content.Context
import com.vkz.player.data.model.Track
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import java.io.File

/**
 * Manages offline cache for track metadata and audio files
 */
class CacheManager(private val context: Context) {

    private val db = AppDatabase.getInstance(context)
    private val dao = db.cacheDao()

    companion object {
        private const val CACHE_DIR = "audio_cache"
        private const val MAX_CACHE_SIZE_MB = 512L // 512 MB max cache

        @Volatile
        private var INSTANCE: CacheManager? = null

        fun getInstance(context: Context): CacheManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: CacheManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    /**
     * Get the audio cache directory
     */
    private fun getCacheDir(): File {
        val dir = File(context.cacheDir, CACHE_DIR)
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    /**
     * Generate local file name for a track
     */
    private fun getTrackFileName(track: Track): String {
        val safeName = "${track.ownerId}_${track.id}".replace("[^a-zA-Z0-9_]".toRegex(), "_")
        return "$safeName.mp3"
    }

    /**
     * Get local file for a track
     */
    fun getTrackFile(track: Track): File {
        return File(getCacheDir(), getTrackFileName(track))
    }

    // ===== Metadata Cache =====

    /**
     * Cache track metadata in Room database
     */
    suspend fun cacheTrackMetadata(track: Track) = withContext(Dispatchers.IO) {
        val entity = CachedTrackEntity(
            uniqueKey = track.getUniqueKey(),
            trackId = track.id,
            ownerId = track.ownerId,
            title = track.title,
            artist = track.artist,
            duration = track.duration,
            url = track.url,
            coverUrl = track.coverUrl,
            albumTitle = track.albumTitle,
            isHq = track.isHq,
            isDownloaded = false,
            localFilePath = null,
            dateAdded = System.currentTimeMillis()
        )
        dao.insertTrack(entity)
    }

    /**
     * Cache multiple tracks metadata
     */
    suspend fun cacheTracksMetadata(tracks: List<Track>) = withContext(Dispatchers.IO) {
        val entities = tracks.map { track ->
            CachedTrackEntity(
                uniqueKey = track.getUniqueKey(),
                trackId = track.id,
                ownerId = track.ownerId,
                title = track.title,
                artist = track.artist,
                duration = track.duration,
                url = track.url,
                coverUrl = track.coverUrl,
                albumTitle = track.albumTitle,
                isHq = track.isHq,
                isDownloaded = false,
                localFilePath = null,
                dateAdded = System.currentTimeMillis()
            )
        }
        dao.insertTracks(entities)
    }

    /**
     * Get cached track metadata
     */
    suspend fun getCachedTrack(uniqueKey: String): CachedTrackEntity? = withContext(Dispatchers.IO) {
        dao.getCachedTrack(uniqueKey)
    }

    /**
     * Get all cached tracks as Flow
     */
    fun getAllCachedTracks(): Flow<List<CachedTrackEntity>> = dao.getAllCachedTracks()

    /**
     * Get downloaded tracks as Flow
     */
    fun getDownloadedTracks(): Flow<List<CachedTrackEntity>> = dao.getDownloadedTracks()

    /**
     * Update play stats when track is played
     */
    suspend fun updatePlayStats(uniqueKey: String) = withContext(Dispatchers.IO) {
        dao.updatePlayStats(uniqueKey, System.currentTimeMillis())
    }

    /**
     * Check if track is cached locally
     */
    suspend fun isTrackDownloaded(track: Track): Boolean = withContext(Dispatchers.IO) {
        val cached = dao.getCachedTrack(track.getUniqueKey())
        cached?.isDownloaded == true && cached.localFilePath?.let { File(it).exists() } == true
    }

    /**
     * Get local file path for downloaded track
     */
    suspend fun getLocalTrackPath(track: Track): String? = withContext(Dispatchers.IO) {
        val cached = dao.getCachedTrack(track.getUniqueKey())
        if (cached?.isDownloaded == true && cached.localFilePath != null) {
            val file = File(cached.localFilePath)
            if (file.exists()) file.absolutePath else null
        } else null
    }

    // ===== Cache Management =====

    /**
     * Get total cache size
     */
    fun getCacheSize(): Long {
        return getCacheDir().walkTopDown().filter { it.isFile }.sumOf { it.length() }
    }

    /**
     * Get cache size in MB
     */
    fun getCacheSizeMb(): Long = getCacheSize() / (1024 * 1024)

    /**
     * Get max cache size in MB
     */
    fun getMaxCacheSizeMb(): Long = MAX_CACHE_SIZE_MB

    /**
     * Clear all cached audio files
     */
    suspend fun clearAudioCache() = withContext(Dispatchers.IO) {
        getCacheDir().listFiles()?.forEach { it.delete() }
        // Update database - mark all as not downloaded
        dao.getAllCachedTracks().collect { tracks ->
            tracks.forEach { track ->
                if (track.isDownloaded) {
                    dao.updateDownloadStatus(track.uniqueKey, false, null)
                }
            }
        }
    }

    /**
     * Clear all cached metadata
     */
    suspend fun clearMetadataCache() = withContext(Dispatchers.IO) {
        dao.clearMetadataOnly()
    }

    /**
     * Clear everything
     */
    suspend fun clearAll() = withContext(Dispatchers.IO) {
        clearAudioCache()
        dao.clearAllTracks()
        dao.clearAllPlaylists()
        dao.clearQueue()
    }

    /**
     * Get track count
     */
    fun getTrackCount(): Flow<Int> = dao.getTrackCount()

    /**
     * Get downloaded track count
     */
    fun getDownloadedCount(): Flow<Int> = dao.getDownloadedCount()
}