package com.vkz.player.data.repository

import com.vkz.player.data.model.*
import com.vkz.player.data.network.VkApiClient
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Repository for VK audio data
 */
class VkRepository {

    private val api = VkApiClient.apiService

    /**
     * Get user's audio tracks
     */
    suspend fun getUserAudio(
        ownerId: Long? = null,
        count: Int = 50,
        offset: Int = 0
    ): Result<List<Track>> = withContext(Dispatchers.IO) {
        try {
            val response = api.getAudio(
                ownerId = ownerId,
                count = count,
                offset = offset,
                accessToken = getToken()
            )
            response.error?.let {
                return@withContext Result.failure(VkApiException(it.errorCode, it.errorMsg))
            }
            val tracks = response.response?.items?.map { Track.fromVkAudioItem(it) } ?: emptyList()
            Result.success(tracks)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Search audio tracks
     */
    suspend fun searchAudio(
        query: String,
        count: Int = 50,
        offset: Int = 0
    ): Result<List<Track>> = withContext(Dispatchers.IO) {
        try {
            val response = api.searchAudio(
                query = query,
                count = count,
                offset = offset,
                accessToken = getToken()
            )
            response.error?.let {
                return@withContext Result.failure(VkApiException(it.errorCode, it.errorMsg))
            }
            val tracks = response.response?.items?.map { Track.fromVkAudioItem(it) } ?: emptyList()
            Result.success(tracks)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get popular audio
     */
    suspend fun getPopularAudio(
        count: Int = 50,
        offset: Int = 0
    ): Result<List<Track>> = withContext(Dispatchers.IO) {
        try {
            val response = api.getPopularAudio(
                count = count,
                offset = offset,
                accessToken = getToken()
            )
            response.error?.let {
                return@withContext Result.failure(VkApiException(it.errorCode, it.errorMsg))
            }
            val tracks = response.response?.map { Track.fromVkAudioItem(it) } ?: emptyList()
            Result.success(tracks)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get recommendations
     */
    suspend fun getRecommendations(
        count: Int = 50,
        offset: Int = 0
    ): Result<List<Track>> = withContext(Dispatchers.IO) {
        try {
            val response = api.getRecommendations(
                count = count,
                offset = offset,
                accessToken = getToken()
            )
            response.error?.let {
                return@withContext Result.failure(VkApiException(it.errorCode, it.errorMsg))
            }
            val tracks = response.response?.map { Track.fromVkAudioItem(it) } ?: emptyList()
            Result.success(tracks)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get user's playlists
     */
    suspend fun getPlaylists(ownerId: Long): Result<List<VkPlaylist>> = withContext(Dispatchers.IO) {
        try {
            val response = api.getPlaylists(
                ownerId = ownerId,
                accessToken = getToken()
            )
            response.error?.let {
                return@withContext Result.failure(VkApiException(it.errorCode, it.errorMsg))
            }
            Result.success(response.response ?: emptyList())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get playlist tracks
     */
    suspend fun getPlaylistTracks(
        playlistId: Long,
        ownerId: Long,
        count: Int = 50,
        offset: Int = 0
    ): Result<List<Track>> = withContext(Dispatchers.IO) {
        try {
            val response = api.getPlaylistTracks(
                playlistId = playlistId,
                ownerId = ownerId,
                count = count,
                offset = offset,
                accessToken = getToken()
            )
            response.error?.let {
                return@withContext Result.failure(VkApiException(it.errorCode, it.errorMsg))
            }
            val tracks = response.response?.items?.map { Track.fromVkAudioItem(it) } ?: emptyList()
            Result.success(tracks)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Add audio to user's page
     */
    suspend fun addAudio(audioId: Long, ownerId: Long): Result<Long> = withContext(Dispatchers.IO) {
        try {
            val response = api.addAudio(
                audioId = audioId,
                ownerId = ownerId,
                accessToken = getToken()
            )
            response.error?.let {
                return@withContext Result.failure(VkApiException(it.errorCode, it.errorMsg))
            }
            Result.success(response.response ?: 0L)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Delete audio from user's page
     */
    suspend fun deleteAudio(audioId: Long, ownerId: Long): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val response = api.deleteAudio(
                audioId = audioId,
                ownerId = ownerId,
                accessToken = getToken()
            )
            response.error?.let {
                return@withContext Result.failure(VkApiException(it.errorCode, it.errorMsg))
            }
            Result.success(response.response == 1)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get audio catalog (mix, recommendations, new releases, etc.)
     */
    suspend fun getCatalog(): Result<List<VkAudioCatalog>> = withContext(Dispatchers.IO) {
        try {
            val response = api.getCatalog(
                accessToken = getToken()
            )
            response.error?.let {
                return@withContext Result.failure(VkApiException(it.errorCode, it.errorMsg))
            }
            Result.success(response.response ?: emptyList())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Get audio catalog with detailed blocks (playlists, recommendations)
     */
    suspend fun getCatalogExtended(): Result<CatalogData> = withContext(Dispatchers.IO) {
        try {
            val catalogResult = getCatalog()
            val recommendationsResult = getRecommendations()
            val popularResult = getPopularAudio()

            val catalog = catalogResult.getOrDefault(emptyList())
            val recommendations = recommendationsResult.getOrDefault(emptyList())
            val popular = popularResult.getOrDefault(emptyList())

            Result.success(CatalogData(catalog, recommendations, popular))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun getToken(): String {
        return SessionManager.getToken()
            ?: throw VkApiException(0, "Not authenticated. Please login first.")
    }
}

class VkApiException(val code: Int, message: String) : Exception(message)

/**
 * Simple session manager for storing VK access token
 */
object SessionManager {
    private var token: String? = null
    private var userId: Long? = null

    fun setToken(newToken: String) {
        token = newToken
    }

    fun getToken(): String? = token

    fun setUserId(id: Long) {
        userId = id
    }

    fun getUserId(): Long? = userId

    fun isLoggedIn(): Boolean = token != null

    fun logout() {
        token = null
        userId = null
    }
}