package com.vkz.player.viewmodel

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.vkz.player.data.repository.SessionManager
import kotlinx.coroutines.launch

/**
 * Settings for VK Mix content filtering.
 * Stored in SharedPreferences for persistence.
 */
data class MixSettings(
    val showRecommendations: Boolean = true,
    val showPopular: Boolean = true,
    val showNewReleases: Boolean = true,
    val showPlaylists: Boolean = true,
    val maxTracksPerBlock: Int = 20,
    val audioQuality: AudioQuality = AudioQuality.NORMAL
)

enum class AudioQuality(val value: String, val label: String) {
    LOW("low", "Low (economy)"),
    NORMAL("normal", "Normal"),
    HIGH("high", "High quality")
}

class SettingsViewModel(application: Application) : AndroidViewModel(application) {

    private val prefs = application.getSharedPreferences("vkz_settings", Context.MODE_PRIVATE)

    private val _mixSettings = MutableLiveData(loadMixSettings())
    val mixSettings: LiveData<MixSettings> = _mixSettings

    private val _isLoggedOut = MutableLiveData(false)
    val isLoggedOut: LiveData<Boolean> = _isLoggedOut

    private fun loadMixSettings(): MixSettings {
        return MixSettings(
            showRecommendations = prefs.getBoolean("show_recommendations", true),
            showPopular = prefs.getBoolean("show_popular", true),
            showNewReleases = prefs.getBoolean("show_new_releases", true),
            showPlaylists = prefs.getBoolean("show_playlists", true),
            maxTracksPerBlock = prefs.getInt("max_tracks_per_block", 20),
            audioQuality = try {
                AudioQuality.valueOf(prefs.getString("audio_quality", AudioQuality.NORMAL.name) ?: AudioQuality.NORMAL.name)
            } catch (e: Exception) {
                AudioQuality.NORMAL
            }
        )
    }

    fun updateShowRecommendations(show: Boolean) {
        prefs.edit().putBoolean("show_recommendations", show).apply()
        _mixSettings.value = loadMixSettings()
    }

    fun updateShowPopular(show: Boolean) {
        prefs.edit().putBoolean("show_popular", show).apply()
        _mixSettings.value = loadMixSettings()
    }

    fun updateShowNewReleases(show: Boolean) {
        prefs.edit().putBoolean("show_new_releases", show).apply()
        _mixSettings.value = loadMixSettings()
    }

    fun updateShowPlaylists(show: Boolean) {
        prefs.edit().putBoolean("show_playlists", show).apply()
        _mixSettings.value = loadMixSettings()
    }

    fun updateMaxTracksPerBlock(max: Int) {
        prefs.edit().putInt("max_tracks_per_block", max.coerceIn(5, 50)).apply()
        _mixSettings.value = loadMixSettings()
    }

    fun updateAudioQuality(quality: AudioQuality) {
        prefs.edit().putString("audio_quality", quality.name).apply()
        _mixSettings.value = loadMixSettings()
    }

    fun logout() {
        viewModelScope.launch {
            SessionManager.logout()
            _isLoggedOut.value = true
        }
    }
}