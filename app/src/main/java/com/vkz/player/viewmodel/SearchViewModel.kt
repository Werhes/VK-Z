package com.vkz.player.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.vkz.player.data.model.Track
import com.vkz.player.data.repository.VkRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class SearchViewModel(application: Application) : AndroidViewModel(application) {

    private val repository = VkRepository()

    private val _searchResults = MutableLiveData<List<Track>>(emptyList())
    val searchResults: LiveData<List<Track>> = _searchResults

    private val _isSearching = MutableLiveData(false)
    val isSearching: LiveData<Boolean> = _isSearching

    private val _error = MutableLiveData<String?>(null)
    val error: LiveData<String?> = _error

    fun clearError() {
        _error.value = null
    }

    private var searchJob: Job? = null

    fun search(query: String) {
        searchJob?.cancel()

        if (query.isBlank()) {
            _searchResults.value = emptyList()
            return
        }

        searchJob = viewModelScope.launch {
            // Debounce 300ms
            delay(300)

            _isSearching.value = true
            _error.value = null

            val result = repository.searchAudio(query = query)

            result.onSuccess { tracks ->
                _searchResults.value = tracks
            }.onFailure { e ->
                _error.value = e.message ?: "Search failed"
            }

            _isSearching.value = false
        }
    }

    fun clearResults() {
        _searchResults.value = emptyList()
        _error.value = null
    }
}