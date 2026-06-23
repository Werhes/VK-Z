package com.vkz.player.data.network

import com.vkz.player.data.model.VkAudioGetResponse
import com.vkz.player.data.model.VkAudioItem
import com.vkz.player.data.model.VkAudioSearchResponse
import com.vkz.player.data.model.VkResponse
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query

/**
 * VK API interface for audio methods
 * Documentation: https://dev.vk.com/method/audio
 */
interface VkApiService {

    /**
     * Get user's audio tracks
     */
    @POST("method/audio.get")
    suspend fun getAudio(
        @Query("owner_id") ownerId: Long? = null,
        @Query("album_id") albumId: Long? = null,
        @Query("count") count: Int = 50,
        @Query("offset") offset: Int = 0,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<VkAudioGetResponse>

    /**
     * Search audio tracks
     */
    @POST("method/audio.search")
    suspend fun searchAudio(
        @Query("q") query: String,
        @Query("count") count: Int = 50,
        @Query("offset") offset: Int = 0,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<VkAudioSearchResponse>

    /**
     * Get audio by ID
     */
    @POST("method/audio.getById")
    suspend fun getAudioById(
        @Query("audios") audios: String,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<List<VkAudioItem>>

    /**
     * Get popular audio
     */
    @POST("method/audio.getPopular")
    suspend fun getPopularAudio(
        @Query("count") count: Int = 50,
        @Query("offset") offset: Int = 0,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<List<VkAudioItem>>

    /**
     * Get recommendations
     */
    @POST("method/audio.getRecommendations")
    suspend fun getRecommendations(
        @Query("count") count: Int = 50,
        @Query("offset") offset: Int = 0,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<List<VkAudioItem>>

    /**
     * Add audio to user's page
     */
    @POST("method/audio.add")
    suspend fun addAudio(
        @Query("audio_id") audioId: Long,
        @Query("owner_id") ownerId: Long,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<Long>

    /**
     * Delete audio from user's page
     */
    @POST("method/audio.delete")
    suspend fun deleteAudio(
        @Query("audio_id") audioId: Long,
        @Query("owner_id") ownerId: Long,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<Int>

    /**
     * Get user's playlists
     */
    @POST("method/audio.getPlaylists")
    suspend fun getPlaylists(
        @Query("owner_id") ownerId: Long,
        @Query("count") count: Int = 50,
        @Query("offset") offset: Int = 0,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<List<com.vkz.player.data.model.VkPlaylist>>

    /**
     * Get playlist tracks
     */
    @POST("method/audio.getPlaylistTracks")
    suspend fun getPlaylistTracks(
        @Query("playlist_id") playlistId: Long,
        @Query("owner_id") ownerId: Long,
        @Query("count") count: Int = 50,
        @Query("offset") offset: Int = 0,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<VkAudioGetResponse>

    /**
     * Get audio catalog (recommendations, new releases, etc.)
     */
    @POST("method/audio.getCatalog")
    suspend fun getCatalog(
        @Query("count") count: Int = 10,
        @Query("access_token") accessToken: String,
        @Query("v") apiVersion: String = VK_API_VERSION
    ): VkResponse<List<com.vkz.player.data.model.VkAudioCatalog>>

    companion object {
        const val VK_API_VERSION = "5.199"
        const val BASE_URL = "https://api.vk.com/"
    }
}