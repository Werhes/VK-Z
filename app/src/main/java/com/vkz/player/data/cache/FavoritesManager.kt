package com.vkz.player.data.cache

import com.vkz.player.data.model.Track
import com.vkz.player.data.repository.VkRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch

/**
 * Manages favorite tracks with local Room storage and VK API sync.
 * Provides reactive [Flow]s for UI observation.
 */
class FavoritesManager(private val dao: CacheDao) {

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val repository = VkRepository()

    /**
     * All favorite tracks as a Flow, ordered by date added (newest first).
     */
    val allFavorites: Flow<List<FavoriteTrackEntity>> = dao.getAllFavorites()

    /**
     * Count of favorite tracks.
     */
    val favoriteCount: Flow<Int> = dao.getFavoriteCount()

    /**
     * Check if a track is favorited (reactive).
     */
    fun isFavoriteFlow(uniqueKey: String): Flow<Boolean> = dao.isFavoriteFlow(uniqueKey)

    /**
     * Check if a track is favorited (one-shot).
     */
    suspend fun isFavorite(uniqueKey: String): Boolean = dao.isFavorite(uniqueKey)

    /**
     * Add a track to favorites locally and sync with VK API.
     * Returns true if the operation was successful (at least locally).
     */
    fun addFavorite(track: Track) {
        scope.launch {
            // Save locally first
            val entity = FavoriteTrackEntity(
                uniqueKey = track.getUniqueKey(),
                trackId = track.id,
                ownerId = track.ownerId,
                title = track.title,
                artist = track.artist,
                duration = track.duration,
                url = track.url,
                coverUrl = track.coverUrl,
                albumTitle = track.albumTitle,
                dateAdded = System.currentTimeMillis()
            )
            dao.addFavorite(entity)

            // Sync with VK API (add to user's page)
            val result = repository.addAudio(track.id, track.ownerId)
            if (result.isFailure) {
                // Log error but don't remove from local - user can retry
                android.util.Log.e("FavoritesManager", "Failed to sync addFavorite to VK API: ${result.exceptionOrNull()?.message}")
            }
        }
    }

    /**
     * Remove a track from favorites locally and sync with VK API.
     */
    fun removeFavorite(track: Track) {
        scope.launch {
            // Remove locally first
            dao.removeFavorite(track.getUniqueKey())

            // Sync with VK API (remove from user's page)
            val result = repository.deleteAudio(track.id, track.ownerId)
            if (result.isFailure) {
                android.util.Log.e("FavoritesManager", "Failed to sync removeFavorite to VK API: ${result.exceptionOrNull()?.message}")
            }
        }
    }

    /**
     * Remove a track from favorites by unique key.
     */
    fun removeFavoriteByKey(uniqueKey: String) {
        scope.launch {
            dao.removeFavorite(uniqueKey)
        }
    }

    /**
     * Toggle favorite state for a track.
     * Returns the new state (true = favorited, false = unfavorited).
     */
    fun toggleFavorite(track: Track, currentlyFavorited: Boolean) {
        if (currentlyFavorited) {
            removeFavorite(track)
        } else {
            addFavorite(track)
        }
    }

    /**
     * Clear all favorites locally.
     */
    fun clearAll() {
        scope.launch {
            dao.clearAllFavorites()
        }
    }
}