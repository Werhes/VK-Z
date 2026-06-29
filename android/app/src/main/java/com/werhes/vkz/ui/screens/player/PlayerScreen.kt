package com.werhes.vkz.ui.screens.player

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.werhes.vkz.data.model.PlayerState
import com.werhes.vkz.data.model.RepeatMode
import com.werhes.vkz.data.repository.MusicRepository
import com.werhes.vkz.player.PlayerManager
import com.werhes.vkz.ui.theme.VKColors
import kotlinx.coroutines.launch

@Composable
fun PlayerScreen() {
    val currentTrack by PlayerManager.currentTrack.collectAsState()
    val playerState by PlayerManager.playerState.collectAsState()
    val currentPosition by PlayerManager.currentPosition.collectAsState()
    val duration by PlayerManager.duration.collectAsState()
    val volume by PlayerManager.volume.collectAsState()
    val repeatMode by PlayerManager.repeatMode.collectAsState()
    val isShuffled by PlayerManager.isShuffled.collectAsState()
    val scope = rememberCoroutineScope()
    val repository = remember { MusicRepository() }

    // Glow animation
    val infiniteTransition = rememberInfiniteTransition(label = "glow")
    val glowAlpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.7f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = EaseInOutCubic),
            repeatMode = RepeatMode.Reverse
        ),
        label = "glowAlpha"
    )

    if (currentTrack == null) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "♪",
                    fontSize = 80.sp,
                    color = VKColors.textTertiary.copy(alpha = 0.3f)
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Ничего не играет",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Выберите трек из плейлиста\nили найдите через поиск",
                    fontSize = 15.sp,
                    color = VKColors.textSecondary,
                    textAlign = TextAlign.Center
                )
            }
        }
        return
    }

    val track = currentTrack!!

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        VKColors.surfaceLight,
                        VKColors.background
                    )
                )
            )
    ) {
        // Glow orbs
        Box(
            modifier = Modifier
                .size(350.dp)
                .offset(x = 50.dp, y = (-100).dp)
                .drawBehind {
                    drawCircle(
                        color = VKColors.accentBlue.copy(alpha = glowAlpha * 0.1f),
                        radius = size.width / 2,
                        center = center
                    )
                }
        )
        Box(
            modifier = Modifier
                .size(250.dp)
                .offset(x = (-30).dp, y = 300.dp)
                .drawBehind {
                    drawCircle(
                        color = VKColors.accentPurple.copy(alpha = glowAlpha * 0.08f),
                        radius = size.width / 2,
                        center = center
                    )
                }
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.weight(0.5f))

            // Cover with rotation animation
            Box(
                modifier = Modifier
                    .size(300.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .drawBehind {
                        drawCircle(
                            color = VKColors.accentBlue.copy(alpha = glowAlpha * 0.15f),
                            radius = size.width * 0.6f,
                            center = center,
                            style = Fill
                        )
                    }
            ) {
                AsyncImage(
                    model = track.coverUrl,
                    contentDescription = null,
                    modifier = Modifier
                        .fillMaxSize()
                        .clip(RoundedCornerShape(24.dp)),
                    contentScale = ContentScale.Crop
                )
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Track info
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = track.title,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground,
                        maxLines = 1
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = track.artist,
                        fontSize = 16.sp,
                        color = VKColors.textSecondary,
                        maxLines = 1
                    )

                    // Create mix button
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedButton(
                        onClick = {
                            scope.launch {
                                try {
                                    val mixTracks = repository.createMix(track.id, track.ownerId)
                                    PlayerManager.setQueue(mixTracks)
                                } catch (_: Exception) { }
                            }
                        },
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = VKColors.accentPurple
                        ),
                        shape = RoundedCornerShape(10.dp),
                        border = ButtonDefaults.outlinedButtonBorder.copy(
                            brush = Brush.linearGradient(
                                colors = listOf(VKColors.accentPurple, VKColors.accentPink)
                            )
                        )
                    ) {
                        Icon(
                            Icons.Default.Waves,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = VKColors.accentPurple
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            "Создать микс",
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Progress
            Slider(
                value = currentPosition.toFloat(),
                onValueChange = { PlayerManager.seekTo(it.toLong()) },
                valueRange = 0f..maxOf(duration.toFloat(), 1f),
                modifier = Modifier.fillMaxWidth(),
                colors = SliderDefaults.colors(
                    thumbColor = VKColors.accentBlue,
                    activeTrackColor = VKColors.accentBlue,
                    inactiveTrackColor = VKColors.textTertiary.copy(alpha = 0.3f)
                )
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = formatTime(currentPosition),
                    fontSize = 12.sp,
                    color = VKColors.textTertiary
                )
                Text(
                    text = formatTime(duration),
                    fontSize = 12.sp,
                    color = VKColors.textTertiary
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Controls
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = { PlayerManager.toggleShuffle() },
                    modifier = Modifier.size(44.dp)
                ) {
                    Icon(
                        Icons.Default.Shuffle,
                        contentDescription = null,
                        tint = if (isShuffled) VKColors.accentBlue
                        else VKColors.textTertiary,
                        modifier = Modifier.size(22.dp)
                    )
                }

                IconButton(
                    onClick = { PlayerManager.previousTrack() },
                    modifier = Modifier.size(44.dp)
                ) {
                    Icon(
                        Icons.Default.SkipPrevious,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onBackground,
                        modifier = Modifier.size(32.dp)
                    )
                }

                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(
                                colors = listOf(VKColors.accentBlue, VKColors.accentPurple)
                            )
                        )
                        .drawBehind {
                            drawCircle(
                                color = VKColors.accentBlue.copy(alpha = glowAlpha * 0.3f),
                                radius = size.width * 0.7f,
                                center = center,
                                style = Fill
                            )
                        },
                    contentAlignment = Alignment.Center
                ) {
                    IconButton(
                        onClick = { PlayerManager.togglePlayPause() },
                        modifier = Modifier.fillMaxSize()
                    ) {
                        Icon(
                            imageVector = if (playerState == PlayerState.PLAYING) Icons.Default.Pause
                            else Icons.Default.PlayArrow,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(36.dp)
                        )
                    }
                }

                IconButton(
                    onClick = { PlayerManager.nextTrack() },
                    modifier = Modifier.size(44.dp)
                ) {
                    Icon(
                        Icons.Default.SkipNext,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onBackground,
                        modifier = Modifier.size(32.dp)
                    )
                }

                IconButton(
                    onClick = { PlayerManager.toggleRepeatMode() },
                    modifier = Modifier.size(44.dp)
                ) {
                    Icon(
                        Icons.Default.Repeat,
                        contentDescription = null,
                        tint = if (repeatMode != RepeatMode.OFF) VKColors.accentBlue
                        else VKColors.textTertiary,
                        modifier = Modifier.size(22.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Volume
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.VolumeDown,
                    contentDescription = null,
                    tint = VKColors.textTertiary,
                    modifier = Modifier.size(18.dp)
                )
                Slider(
                    value = volume,
                    onValueChange = { PlayerManager.setVolume(it) },
                    modifier = Modifier.weight(1f),
                    colors = SliderDefaults.colors(
                        thumbColor = VKColors.accentBlue,
                        activeTrackColor = VKColors.accentBlue,
                        inactiveTrackColor = VKColors.textTertiary.copy(alpha = 0.3f)
                    )
                )
                Icon(
                    Icons.Default.VolumeUp,
                    contentDescription = null,
                    tint = VKColors.textTertiary,
                    modifier = Modifier.size(18.dp)
                )
            }

            Spacer(modifier = Modifier.weight(0.5f))
        }
    }
}

private fun formatTime(millis: Long): String {
    val totalSeconds = millis / 1000
    val minutes = totalSeconds / 60
    val seconds = totalSeconds % 60
    return "%d:%02d".format(minutes, seconds)
}