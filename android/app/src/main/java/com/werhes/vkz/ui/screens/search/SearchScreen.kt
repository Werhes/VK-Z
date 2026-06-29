package com.werhes.vkz.ui.screens.search

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.werhes.vkz.data.model.VKTrack
import com.werhes.vkz.data.repository.MusicRepository
import com.werhes.vkz.player.PlayerManager
import com.werhes.vkz.ui.theme.VKColors
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun SearchScreen() {
    val repository = remember { MusicRepository() }
    val scope = rememberCoroutineScope()
    var searchQuery by remember { mutableStateOf("") }
    var searchResults by remember { mutableStateOf<List<VKTrack>>(emptyList()) }
    var popularTracks by remember { mutableStateOf<List<VKTrack>>(emptyList()) }
    var isSearching by remember { mutableStateOf(false) }
    var searchJob by remember { mutableStateOf<Job?>(null) }

    val genres = listOf("Рок", "Поп", "Рэп", "Электроника", "Джаз", "Классика", "Инди", "R&B", "Метал", "Lounge")

    LaunchedEffect(Unit) {
        try { popularTracks = repository.getPopular().take(20) } catch (_: Exception) { }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Search bar
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { query ->
                searchQuery = query
                searchJob?.cancel()
                if (query.isNotBlank()) {
                    searchJob = scope.launch {
                        isSearching = true
                        delay(500)
                        try {
                            searchResults = repository.searchAudio(query)
                        } catch (_: Exception) { }
                        isSearching = false
                    }
                } else {
                    searchResults = emptyList()
                    isSearching = false
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            placeholder = { Text("Поиск треков, альбомов...", color = VKColors.textTertiary) },
            leadingIcon = {
                Icon(
                    Icons.Default.Search,
                    contentDescription = null,
                    tint = VKColors.textSecondary
                )
            },
            trailingIcon = {
                if (searchQuery.isNotEmpty()) {
                    IconButton(onClick = {
                        searchQuery = ""
                        searchResults = emptyList()
                    }) {
                        Icon(
                            Icons.Default.Clear,
                            contentDescription = null,
                            tint = VKColors.textSecondary
                        )
                    }
                }
            },
            shape = RoundedCornerShape(16.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedTextColor = Color.White,
                unfocusedTextColor = Color.White,
                focusedContainerColor = VKColors.surface,
                unfocusedContainerColor = VKColors.surface,
                focusedBorderColor = VKColors.accentBlue,
                unfocusedBorderColor = VKColors.surface
            ),
            singleLine = true
        )

        if (searchQuery.isBlank()) {
            // Empty state - genres + popular
            LazyColumn {
                item {
                    Text(
                        text = "Поиск по жанрам",
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                    )
                }

                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp)
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            genres.take(5).forEach { genre ->
                                FilterChip(
                                    selected = false,
                                    onClick = { searchQuery = genre },
                                    label = { Text(genre, fontSize = 13.sp) },
                                    colors = FilterChipDefaults.filterChipColors(
                                        containerColor = VKColors.cardBackground,
                                        labelColor = VKColors.textSecondary
                                    ),
                                    shape = RoundedCornerShape(10.dp)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            genres.drop(5).forEach { genre ->
                                FilterChip(
                                    selected = false,
                                    onClick = { searchQuery = genre },
                                    label = { Text(genre, fontSize = 13.sp) },
                                    colors = FilterChipDefaults.filterChipColors(
                                        containerColor = VKColors.cardBackground,
                                        labelColor = VKColors.textSecondary
                                    ),
                                    shape = RoundedCornerShape(10.dp)
                                )
                            }
                        }
                    }
                }

                item {
                    Text(
                        text = "Популярные треки",
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground,
                        modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                    )
                }

                items(popularTracks) { track ->
                    TrackRow(track = track)
                }
            }
        } else {
            // Search results
            LazyColumn {
                if (isSearching) {
                    items(8) {
                        ShimmerTrackRow()
                    }
                } else if (searchResults.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier.fillMaxSize().padding(top = 60.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    text = "🔍",
                                    fontSize = 48.sp
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                Text(
                                    text = "Ничего не найдено",
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = VKColors.textSecondary
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "Попробуйте изменить запрос",
                                    fontSize = 14.sp,
                                    color = VKColors.textTertiary
                                )
                            }
                        }
                    }
                } else {
                    item {
                        Text(
                            text = "Результаты поиска",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onBackground,
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
                        )
                    }
                    items(searchResults) { track ->
                        TrackRow(track = track)
                    }
                }
            }
        }
    }
}

@Composable
fun TrackRow(track: VKTrack) {
    Card(
        onClick = { PlayerManager.setQueue(listOf(track)) },
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = VKColors.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            AsyncImage(
                model = track.coverUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(10.dp)),
                contentScale = ContentScale.Crop
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = track.title,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = track.artist,
                    fontSize = 13.sp,
                    color = VKColors.textSecondary,
                    maxLines = 1
                )
            }
            Text(
                text = track.formattedDuration,
                fontSize = 12.sp,
                color = VKColors.textTertiary
            )
        }
    }
}

@Composable
fun ShimmerTrackRow() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp)
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(VKColors.cardBackground)
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(0.6f)
                    .height(12.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(VKColors.cardBackground)
            )
            Spacer(modifier = Modifier.height(6.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth(0.4f)
                    .height(10.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(VKColors.cardBackground)
            )
        }
    }
}