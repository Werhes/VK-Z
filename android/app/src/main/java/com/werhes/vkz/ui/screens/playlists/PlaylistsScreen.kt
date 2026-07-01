package com.werhes.vkz.ui.screens.playlists

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.werhes.vkz.data.model.VKPlaylist
import com.werhes.vkz.data.model.VKTrack
import com.werhes.vkz.data.repository.MusicRepository
import com.werhes.vkz.player.PlayerManager
import com.werhes.vkz.ui.theme.VKColors
import kotlinx.coroutines.launch

@Composable
fun PlaylistsScreen() {
    val scope = rememberCoroutineScope()
    val repository = remember { MusicRepository() }

    var playlists by remember { mutableStateOf<List<VKPlaylist>>(emptyList()) }
    var recommendations by remember { mutableStateOf<List<VKTrack>>(emptyList()) }
    var popular by remember { mutableStateOf<List<VKTrack>>(emptyList()) }
    var recentTracks by remember { mutableStateOf<List<VKTrack>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        scope.launch {
            try {
                playlists = repository.getPlaylists()
                recommendations = repository.getRecommendations().take(10)
                popular = repository.getPopular().take(10)
                recentTracks = repository.getAudio().take(10)
            } catch (_: Exception) { }
            isLoading = false
        }
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 16.dp)
    ) {
        item {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Моя музыка",
                fontSize = 34.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp)
            )
            Text(
                text = "${recentTracks.size} треков",
                fontSize = 15.sp,
                color = VKColors.textSecondary,
                modifier = Modifier.padding(horizontal = 20.dp)
            )
        }

        if (isLoading) {
            items(5) {
                ShimmerTrackRow()
            }
        } else {
            // Recommendations
            if (recommendations.isNotEmpty()) {
                item {
                    SectionHeader(title = "Для вас")
                }
                item {
                    LazyRow(
                        contentPadding = PaddingValues(horizontal = 20.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(recommendations) { track ->
                            TrackCard(track = track)
                        }
                    }
                }
            }

            // Popular
            if (popular.isNotEmpty()) {
                item {
                    SectionHeader(title = "Популярное")
                }
                item {
                    LazyRow(
                        contentPadding = PaddingValues(horizontal = 20.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(popular) { track ->
                            TrackCard(track = track)
                        }
                    }
                }
            }

            // Playlists
            if (playlists.isNotEmpty()) {
                item {
                    SectionHeader(title = "Плейлисты")
                }
                item {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        contentPadding = PaddingValues(horizontal = 20.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.height(((playlists.size / 2 + 1) * 260).dp)
                    ) {
                        items(playlists.take(6)) { playlist ->
                            PlaylistCard(playlist = playlist)
                        }
                    }
                }
            }

            // Recent
            if (recentTracks.isNotEmpty()) {
                item {
                    SectionHeader(title = "Недавно добавленные")
                }
                item {
                    LazyRow(
                        contentPadding = PaddingValues(horizontal = 20.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(recentTracks) { track ->
                            TrackCard(track = track)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun SectionHeader(title: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
        TextButton(onClick = { }) {
            Text(
                "Все",
                color = VKColors.accentBlue,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

@Composable
fun TrackCard(track: VKTrack) {
    Card(
        onClick = { PlayerManager.setQueue(listOf(track)) },
        modifier = Modifier.width(160.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = VKColors.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column {
            Box {
                AsyncImage(
                    model = track.coverUrl,
                    contentDescription = null,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(160.dp)
                        .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)),
                    contentScale = ContentScale.Crop
                )
                // Gradient overlay at bottom
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(60.dp)
                        .align(Alignment.BottomCenter)
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    VKColors.surface.copy(alpha = 0.9f)
                                )
                            )
                        )
                )
            }
            Column(modifier = Modifier.padding(10.dp)) {
                Text(
                    text = track.title,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = track.artist,
                    fontSize = 12.sp,
                    color = VKColors.textSecondary,
                    maxLines = 1
                )
            }
        }
    }
}

@Composable
fun PlaylistCard(playlist: VKPlaylist) {
    Card(
        onClick = { },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = VKColors.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column {
            Box {
                AsyncImage(
                    model = playlist.coverUrl,
                    contentDescription = null,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(170.dp)
                        .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)),
                    contentScale = ContentScale.Crop
                )
                // Gradient overlay
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(80.dp)
                        .align(Alignment.BottomCenter)
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    VKColors.surface.copy(alpha = 0.9f)
                                )
                            )
                        )
                )
            }
            Column(modifier = Modifier.padding(10.dp)) {
                Text(
                    text = playlist.title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = "${playlist.trackCount} треков",
                    fontSize = 12.sp,
                    color = VKColors.textSecondary
                )
            }
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
                .size(60.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(VKColors.cardBackground)
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column {
            Box(
                modifier = Modifier
                    .width(150.dp)
                    .height(14.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(VKColors.cardBackground)
            )
            Spacer(modifier = Modifier.height(6.dp))
            Box(
                modifier = Modifier
                    .width(100.dp)
                    .height(12.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(VKColors.cardBackground)
            )
        }
    }
}