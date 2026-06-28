package com.werhes.vkz.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val VkBackground = Color(0xFF0D0F1F)
val VkCardBackground = Color(0xFF1A1F33)
val VkSurface = Color(0xFF262E47)
val VkAccentBlue = Color(0xFF3F7AFF)
val VkAccentPurple = Color(0xFF7C4DFF)
val VkTextPrimary = Color.White
val VkTextSecondary = Color(0xFF9E9E9E)

private val DarkColorScheme = darkColorScheme(
    primary = VkAccentBlue,
    secondary = VkAccentPurple,
    background = VkBackground,
    surface = VkCardBackground,
    surfaceVariant = VkSurface,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = VkTextPrimary,
    onSurface = VkTextPrimary,
    onSurfaceVariant = VkTextSecondary
)

@Composable
fun VKZTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography(),
        content = content
    )
}