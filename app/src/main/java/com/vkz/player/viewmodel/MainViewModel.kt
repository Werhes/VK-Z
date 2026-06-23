package com.vkz.player.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.vkz.player.data.model.Track
import com.vkz.player.data.repository.SessionManager
import com.vkz.player.data.repository.VkRepository
import kotlinx.coroutines.launch

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = VkRepository()

    private val _tracks = MutableLiveData<List<Track>>(emptyList())
    val tracks: LiveData<List<Track>> = _tracks

    private val _isLoading = MutableLiveData(false)
    val isLoading: LiveData<Boolean> = _isLoading

    private val _error = MutableLiveData<String?>(null)
    val error: LiveData<String?> = _error

    private val _isRefreshing = MutableLiveData(false)
    val isRefreshing: LiveData<Boolean> = _isRefreshing

    private val _isLoggedIn = MutableLiveData(SessionManager.isLoggedIn())
    val isLoggedIn: LiveData<Boolean> = _isLoggedIn

    fun clearError() {
        _error.value = null
    }

    init {
        if (SessionManager.isLoggedIn()) {
            loadUserAudio()
        }
    }

    fun loadUserAudio() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null

            val result = repository.getUserAudio(
                ownerId = SessionManager.getUserId()
            )

            result.onSuccess { tracks ->
                _tracks.value = tracks
            }.onFailure { e ->
                _error.value = e.message ?: "Failed to load tracks"
            }

            _isLoading.value = false
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _isRefreshing.value = true
            _error.value = null

            val result = repository.getUserAudio(
                ownerId = SessionManager.getUserId()
            )

            result.onSuccess { tracks ->
                _tracks.value = tracks
            }.onFailure { e ->
                _error.value = e.message ?: "Failed to refresh"
            }

            _isRefreshing.value = false
        }
    }

    fun login(token: String, userId: Long) {
        SessionManager.setToken(token)
        SessionManager.setUserId(userId)
        _isLoggedIn.value = true
        loadUserAudio()
    }

    fun logout() {
        SessionManager.logout()
        _isLoggedIn.value = false
        _tracks.value = emptyList()
    }

    fun getTrackAt(index: Int): Track? {
        return _tracks.value?.getOrNull(index)
    }
}