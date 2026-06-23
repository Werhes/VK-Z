package com.vkz.player.viewmodel

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.vkz.player.data.model.CatalogBlockType
import com.vkz.player.data.model.CatalogData
import com.vkz.player.data.model.Track
import com.vkz.player.data.model.VkAudioCatalog
import com.vkz.player.data.model.VkPlaylist
import com.vkz.player.data.repository.SessionManager
import com.vkz.player.data.repository.VkRepository
import kotlinx.coroutines.launch

/**
 * Catalog block for UI display
 */
data class CatalogBlock(
    val id: String,
    val title: String,
    val type: CatalogBlockType,
    val tracks: List<Track> = emptyList(),
    val playlists: List<VkPlaylist> = emptyList()
)

class MixViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = VkRepository()
    private val prefs = application.getSharedPreferences("vkz_settings", Context.MODE_PRIVATE)

    private val _catalogBlocks = MutableLiveData<List<CatalogBlock>>(emptyList())
    val catalogBlocks: LiveData<List<CatalogBlock>> = _catalogBlocks

    private val _isLoading = MutableLiveData(false)
    val isLoading: LiveData<Boolean> = _isLoading

    private val _isRefreshing = MutableLiveData(false)
    val isRefreshing: LiveData<Boolean> = _isRefreshing

    private val _error = MutableLiveData<String?>(null)
    val error: LiveData<String?> = _error

    fun clearError() {
        _error.value = null
    }

    init {
        if (SessionManager.isLoggedIn()) {
            loadMix()
        }
    }

    fun loadMix() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null

            val result = repository.getCatalogExtended()

            result.onSuccess { catalogData ->
                _catalogBlocks.value = buildCatalogBlocks(catalogData)
            }.onFailure { e ->
                _error.value = e.message ?: "Failed to load mix"
            }

            _isLoading.value = false
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _isRefreshing.value = true
            _error.value = null

            val result = repository.getCatalogExtended()

            result.onSuccess { catalogData ->
                _catalogBlocks.value = buildCatalogBlocks(catalogData)
            }.onFailure { e ->
                _error.value = e.message ?: "Failed to refresh"
            }

            _isRefreshing.value = false
        }
    }

    private fun loadSettings(): MixSettings {
        return MixSettings(
            showRecommendations = prefs.getBoolean("show_recommendations", true),
            showPopular = prefs.getBoolean("show_popular", true),
            showNewReleases = prefs.getBoolean("show_new_releases", true),
            showPlaylists = prefs.getBoolean("show_playlists", true),
            maxTracksPerBlock = prefs.getInt("max_tracks_per_block", 20)
        )
    }

    private fun buildCatalogBlocks(catalogData: CatalogData): List<CatalogBlock> {
        val settings = loadSettings()
        val blocks = mutableListOf<CatalogBlock>()
        val maxTracks = settings.maxTracksPerBlock

        // 1. Recommendations block (Микс)
        if (settings.showRecommendations && catalogData.recommendations.isNotEmpty()) {
            blocks.add(
                CatalogBlock(
                    id = "recommendations",
                    title = "Рекомендации для вас",
                    type = CatalogBlockType.RECOMMENDATIONS,
                    tracks = catalogData.recommendations.take(maxTracks)
                )
            )
        }

        // 2. Popular block (Популярное)
        if (settings.showPopular && catalogData.popular.isNotEmpty()) {
            blocks.add(
                CatalogBlock(
                    id = "popular",
                    title = "Популярное",
                    type = CatalogBlockType.POPULAR,
                    tracks = catalogData.popular.take(maxTracks)
                )
            )
        }

        // 3. Process catalog blocks from VK API
        catalogData.catalog.forEach { catalog ->
            val tracks = (catalog.items ?: catalog.audios) ?: emptyList()
            val trackModels = tracks.map { Track.fromVkAudioItem(it) }

            if (trackModels.isNotEmpty()) {
                val blockType = when {
                    catalog.title.contains("микс", ignoreCase = true) ||
                            catalog.title.contains("mix", ignoreCase = true) ->
                        CatalogBlockType.MIX
                    catalog.title.contains("популяр", ignoreCase = true) ||
                            catalog.title.contains("chart", ignoreCase = true) ->
                        CatalogBlockType.POPULAR
                    catalog.title.contains("новин", ignoreCase = true) ||
                            catalog.title.contains("new", ignoreCase = true) ->
                        CatalogBlockType.NEW_RELEASES
                    catalog.playlists != null && catalog.playlists!!.isNotEmpty() ->
                        CatalogBlockType.PLAYLISTS
                    else -> CatalogBlockType.DEFAULT
                }

                // Apply filters based on block type
                val shouldShow = when (blockType) {
                    CatalogBlockType.NEW_RELEASES -> settings.showNewReleases
                    CatalogBlockType.PLAYLISTS -> settings.showPlaylists
                    CatalogBlockType.POPULAR -> settings.showPopular
                    CatalogBlockType.MIX -> settings.showRecommendations
                    CatalogBlockType.RECOMMENDATIONS -> settings.showRecommendations
                    CatalogBlockType.DEFAULT -> true // Always show default/unknown blocks
                }

                if (shouldShow) {
                    blocks.add(
                        CatalogBlock(
                            id = catalog.id,
                            title = catalog.title,
                            type = blockType,
                            tracks = trackModels.take(maxTracks),
                            playlists = catalog.playlists ?: emptyList()
                        )
                    )
                }
            }
        }

        return blocks
    }

    fun getTrackAt(blockIndex: Int, trackIndex: Int): Track? {
        return _catalogBlocks.value?.getOrNull(blockIndex)?.tracks?.getOrNull(trackIndex)
    }
}