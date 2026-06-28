package com.werhes.vkz.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.werhes.vkz.player.PlayerManager
import com.werhes.vkz.ui.screens.auth.AuthScreen
import com.werhes.vkz.ui.screens.mix.MixScreen
import com.werhes.vkz.ui.screens.player.PlayerScreen
import com.werhes.vkz.ui.screens.playlists.PlaylistsScreen
import com.werhes.vkz.ui.screens.search.SearchScreen

sealed class Screen(val route: String, val title: String, val icon: ImageVector, val selectedIcon: ImageVector) {
    data object Playlists : Screen("playlists", "Моя музыка", Icons.Outlined.QueueMusic, Icons.Filled.QueueMusic)
    data object Mix : Screen("mix", "Микс", Icons.Outlined.Waves, Icons.Filled.Waves)
    data object Search : Screen("search", "Поиск", Icons.Outlined.Search, Icons.Filled.Search)
    data object Player : Screen("player", "Сейчас", Icons.Outlined.PlayCircle, Icons.Filled.PlayCircle)
}

val bottomNavItems = listOf(
    Screen.Playlists,
    Screen.Mix,
    Screen.Search,
    Screen.Player
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainNavigation(isAuthenticated: Boolean) {
    val navController = rememberNavController()
    val playerState by PlayerManager.playerState.collectAsState()
    val currentTrack by PlayerManager.currentTrack.collectAsState()

    if (!isAuthenticated) {
        AuthScreen()
        return
    }

    Scaffold(
        bottomBar = {
            Column {
                // Mini Player
                if (currentTrack != null) {
                    MiniPlayerBar(
                        onClick = {
                            navController.navigate(Screen.Player.route) {
                                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }

                NavigationBar(
                    containerColor = MaterialTheme.colorScheme.background
                ) {
                    val navBackStackEntry by navController.currentBackStackEntryAsState()
                    val currentDestination = navBackStackEntry?.destination

                    bottomNavItems.forEach { screen ->
                        val selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true
                        NavigationBarItem(
                            icon = {
                                Icon(
                                    imageVector = if (selected) screen.selectedIcon else screen.icon,
                                    contentDescription = screen.title
                                )
                            },
                            label = { Text(screen.title, style = MaterialTheme.typography.labelSmall) },
                            selected = selected,
                            onClick = {
                                navController.navigate(screen.route) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = Screen.Playlists.route,
            modifier = Modifier.padding(paddingValues)
        ) {
            composable(Screen.Playlists.route) { PlaylistsScreen() }
            composable(Screen.Mix.route) { MixScreen() }
            composable(Screen.Search.route) { SearchScreen() }
            composable(Screen.Player.route) { PlayerScreen() }
        }
    }
}

@Composable
fun MiniPlayerBar(onClick: () -> Unit) {
    val currentTrack by PlayerManager.currentTrack.collectAsState()
    val playerState by PlayerManager.playerState.collectAsState()

    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        // Mini player content
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Cover
            AsyncImage(
                model = currentTrack?.coverUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(8.dp)),
                contentScale = ContentScale.Crop
            )

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = currentTrack?.title ?: "",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1
                )
                Text(
                    text = currentTrack?.artist ?: "",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1
                )
            }

            IconButton(onClick = { PlayerManager.togglePlayPause() }) {
                Icon(
                    imageVector = if (playerState == com.werhes.vkz.data.model.PlayerState.PLAYING)
                        Icons.Filled.Pause else Icons.Filled.PlayArrow,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }

            IconButton(onClick = { PlayerManager.nextTrack() }) {
                Icon(
                    imageVector = Icons.Filled.SkipNext,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}

// Required imports for MiniPlayerBar
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage