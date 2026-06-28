package com.werhes.vkz.data.repository

import com.werhes.vkz.data.api.ApiClient
import com.werhes.vkz.data.api.VKApi
import com.werhes.vkz.data.model.*

class MusicRepository {
    private val api = ApiClient.api

    private fun getToken(): String =
        com.werhes.vkz.data.api.AuthManager.getToken() ?: throw Exception("Not authenticated")

    suspend fun getAudio(offset: Int = 0, count: Int = 50): List<VKTrack> {
        val response = api.getAudio(token = getToken(), offset = offset, count = count)
        return response.response?.items ?: throw Exception(response.error?.errorMsg ?: "No data")
    }

    suspend fun getPlaylists(offset: Int = 0, count: Int = 50): List<VKPlaylist> {
        val response = api.getPlaylists(token = getToken(), offset = offset, count = count)
        return response.response?.items ?: throw Exception(response.error?.errorMsg ?: "No data")
    }

    suspend fun searchAudio(query: String, offset: Int = 0, count: Int = 50): List<VKTrack> {
        val response = api.searchAudio(query = query, token = getToken(), offset = offset, count = count)
        return response.response?.items ?: throw Exception(response.error?.errorMsg ?: "No data")
    }

    suspend fun getRecommendations(count: Int = 30): List<VKTrack> {
        val response = api.getRecommendations(token = getToken(), count = count)
        return response.response?.items ?: throw Exception(response.error?.errorMsg ?: "No data")
    }

    suspend fun getPopular(count: Int = 30): List<VKTrack> {
        val response = api.getPopular(token = getToken(), count = count)
        return response.response?.items ?: throw Exception(response.error?.errorMsg ?: "No data")
    }

    suspend fun getMixes(count: Int = 20): List<VKMix> {
        val response = api.getMixes(token = getToken(), count = count)
        return response.response?.items ?: throw Exception(response.error?.errorMsg ?: "No data")
    }

    suspend fun getMixTracks(mixId: String, count: Int = 30): List<VKTrack> {
        val response = api.getMixTracks(mixId = mixId, token = getToken(), count = count)
        return response.response?.items ?: throw Exception(response.error?.errorMsg ?: "No data")
    }

    suspend fun createMix(trackId: Int, ownerId: Int, count: Int = 30): List<VKTrack> {
        val response = api.createMix(
            trackId = trackId, ownerId = ownerId,
            token = getToken(), count = count
        )
        return response.response?.items ?: throw Exception(response.error?.errorMsg ?: "No data")
    }
}