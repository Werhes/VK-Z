package com.vkz.player.data.cache

import android.content.Context
import android.os.SystemClock
import com.vkz.player.data.model.Track
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.Flow
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.TimeUnit

/**
 * Manages downloading audio files for offline playback
 */
class DownloadManager(private val context: Context) {

    private val db = AppDatabase.getInstance(context)
    private val dao = db.cacheDao()
    private val cacheManager = CacheManager.getInstance(context)

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .followRedirects(true)
        .build()

    private val downloadJobs = mutableMapOf<String, Job>()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    companion object {
        @Volatile
        private var INSTANCE: DownloadManager? = null

        fun getInstance(context: Context): DownloadManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: DownloadManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    /**
     * Get download queue as Flow
     */
    fun getDownloadQueue(): Flow<List<DownloadQueueEntity>> = dao.getDownloadQueue()

    /**
     * Get pending download count
     */
    fun getPendingDownloadCount(): Flow<Int> = dao.getPendingDownloadCount()

    /**
     * Start downloading a single track
     */
    fun downloadTrack(track: Track, onProgress: ((Int) -> Unit)? = null): Job {
        val key = track.getUniqueKey()

        // Cancel existing download for this track
        downloadJobs[key]?.cancel()

        val job = scope.launch {
            try {
                // Add to queue
                val queueItem = DownloadQueueEntity(
                    uniqueKey = key,
                    trackId = track.id,
                    ownerId = track.ownerId,
                    title = track.title,
                    artist = track.artist,
                    url = track.url,
                    coverUrl = track.coverUrl,
                    duration = track.duration,
                    status = DownloadStatus.DOWNLOADING.name,
                    progress = 0
                )
                dao.addToQueue(queueItem)

                // Cache metadata first
                cacheManager.cacheTrackMetadata(track)

                // Download the file
                val request = Request.Builder()
                    .url(track.url)
                    .addHeader("User-Agent", "VKZ-Android/1.0")
                    .build()

                val response = client.newCall(request).execute()

                if (!response.isSuccessful) {
                    throw Exception("Download failed: HTTP ${response.code}")
                }

                val body = response.body ?: throw Exception("Empty response body")
                val contentLength = body.contentLength()
                val inputStream = body.byteStream()

                val targetFile = cacheManager.getTrackFile(track)
                val outputStream = FileOutputStream(targetFile)

                val buffer = ByteArray(8192)
                var bytesRead: Int
                var totalBytesRead = 0L
                var lastProgress = 0

                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    outputStream.write(buffer, 0, bytesRead)
                    totalBytesRead += bytesRead

                    if (contentLength > 0) {
                        val progress = ((totalBytesRead * 100) / contentLength).toInt()
                        if (progress != lastProgress) {
                            lastProgress = progress
                            withContext(Dispatchers.Main) {
                                onProgress?.invoke(progress)
                            }
                            dao.updateDownloadProgress(key, DownloadStatus.DOWNLOADING.name, progress)
                        }
                    }
                }

                outputStream.flush()
                outputStream.close()
                inputStream.close()

                // Update database
                dao.updateDownloadStatus(key, true, targetFile.absolutePath)
                dao.updateDownloadProgress(key, DownloadStatus.COMPLETED.name, 100)
                dao.removeFromQueue(key)

            } catch (e: CancellationException) {
                // Download was cancelled
                dao.updateDownloadProgress(key, DownloadStatus.CANCELLED.name, 0)
                dao.removeFromQueue(key)
                throw e
            } catch (e: Exception) {
                // Download failed
                dao.updateDownloadProgress(key, DownloadStatus.FAILED.name, 0)
                withContext(Dispatchers.Main) {
                    onProgress?.invoke(-1)
                }
            } finally {
                downloadJobs.remove(key)
            }
        }

        downloadJobs[key] = job
        return job
    }

    /**
     * Download multiple tracks
     */
    fun downloadTracks(
        tracks: List<Track>,
        onTrackProgress: ((Track, Int) -> Unit)? = null,
        onComplete: (() -> Unit)? = null
    ): Job {
        return scope.launch {
            tracks.forEachIndexed { index, track ->
                val job = downloadTrack(track) { progress ->
                    onTrackProgress?.invoke(track, progress)
                }
                job.join()
            }
            withContext(Dispatchers.Main) {
                onComplete?.invoke()
            }
        }
    }

    /**
     * Cancel download for a track
     */
    fun cancelDownload(track: Track) {
        val key = track.getUniqueKey()
        downloadJobs[key]?.cancel()
        downloadJobs.remove(key)
        scope.launch {
            dao.updateDownloadProgress(key, DownloadStatus.CANCELLED.name, 0)
            dao.removeFromQueue(key)
        }
    }

    /**
     * Cancel all downloads
     */
    fun cancelAllDownloads() {
        downloadJobs.values.forEach { it.cancel() }
        downloadJobs.clear()
        scope.launch {
            dao.clearQueue()
        }
    }

    /**
     * Delete a downloaded track
     */
    suspend fun deleteDownloadedTrack(track: Track) = withContext(Dispatchers.IO) {
        val file = cacheManager.getTrackFile(track)
        if (file.exists()) file.delete()
        dao.updateDownloadStatus(track.getUniqueKey(), false, null)
    }

    /**
     * Check if track is currently downloading
     */
    fun isDownloading(track: Track): Boolean {
        return downloadJobs.containsKey(track.getUniqueKey())
    }

    /**
     * Clean up
     */
    fun destroy() {
        scope.cancel()
    }
}