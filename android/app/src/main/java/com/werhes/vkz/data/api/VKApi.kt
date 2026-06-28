package com.werhes.vkz.data.api

import com.werhes.vkz.data.model.*
import retrofit2.http.POST
import retrofit2.http.Query

interface VKApi {
    @POST("audio.get")
    suspend fun getAudio(
        @Query("owner_id") ownerId: Int? = null,
        @Query("offset") offset: Int = 0,
        @Query("count") count: Int = 50,
        @Query("access_token") token: String,
        @Query("v") v: String = API_VERSION
    ): VKApiResponse<VKMusicResponse>

    @POST("audio.get_playlists")
    suspend fun getPlaylists(
        @Query("owner_id") ownerId: Int? = null,
        @Query("offset") offset: Int = 0,
        @Query("count") count: Int = 50,
        @Query("access_token") token: String,
        @Query("v") v: String = API_VERSION
    ): VKApiResponse<VKPlaylistsResponse>

    @POST("audio.search")
    suspend fun searchAudio(
        @Query("q") query: String,
        @Query("offset") offset: Int = 0,
        @Query("count") count: Int = 50,
        @Query("autocomplete") autocomplete: Int = 1,
        @Query("sort") sort: Int = 2,
        @Query("access_token") token: String,
        @Query("v") v: String = API_VERSION
    ): VKApiResponse<VKSearchResponse>

    @POST("audio.get_recommendations")
    suspend fun getRecommendations(
        @Query("count") count: Int = 30,
        @Query("access_token") token: String,
        @Query("v") v: String = API_VERSION
    ): VKApiResponse<VKMusicResponse>

    @POST("audio.get_popular")
    suspend fun getPopular(
        @Query("count") count: Int = 30,
        @Query("access_token") token: String,
        @Query("v") v: String = API_VERSION
    ): VKApiResponse<VKMusicResponse>

    @POST("audio.get_mixes")
    suspend fun getMixes(
        @Query("count") count: Int = 20,
        @Query("access_token") token: String,
        @Query("v") v: String = API_VERSION
    ): VKApiResponse<VKMixResponse>

    @POST("audio.get_mix_tracks")
    suspend fun getMixTracks(
        @Query("mix_id") mixId: String,
        @Query("count") count: Int = 30,
        @Query("access_token") token: String,
        @Query("v") v: String = API_VERSION
    ): VKApiResponse<VKMixTracksResponse>

    @POST("audio.create_mix")
    suspend fun createMix(
        @Query("track_id") trackId: Int,
        @Query("owner_id") ownerId: Int,
        @Query("count") count: Int = 30,
        @Query("access_token") token: String,
        @Query("v") v: String = API_VERSION
    ): VKApiResponse<VKMixTracksResponse>

    companion object {
        const val API_VERSION = "5.199"
        const val BASE_URL = "https://api.vk.com/method/"
        const val CLIENT_ID = "51632119"
        const val CLIENT_SECRET = "hTZ3mHq8vKpL5xR7wNfJ2gBc4sYdA6eU"
    }
}