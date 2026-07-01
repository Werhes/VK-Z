package com.werhes.vkz.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

// MARK: - Colors
object VKColors {
    // Backgrounds
    val background = Color(0xFF0A0C1A)
    val surface = Color(0xFF141829)
    val surfaceLight = Color(0xFF1E263D)
    val cardBackground = Color(0xFF1A1F33)
    val elevatedBackground = Color(0xFF242B45)

    // Accent
    val accentBlue = Color(0xFF3F85FF)
    val accentBlueLight = Color(0xFF5A9EFF)
    val accentPurple = Color(0xFF8C5AFF)
    val accentPink = Color(0xFFFF5AA6)
    val accentGreen = Color(0xFF33D97A)
    val accentOrange = Color(0xFFFF9933)

    // Text
    val textPrimary = Color.White
    val textSecondary = Color(0xFF8E94A6)
    val textTertiary = Color(0xFF5A5F72)

    // Gradients
    val primaryGradient = Brush.linearGradient(
        colors = listOf(accentBlue, accentPurple),
        start = androidx.compose.ui.geometry.Offset.Zero,
        end = androidx.compose.ui.geometry.Offset(100f, 100f)
    )

    val warmGradient = Brush.linearGradient(
        colors = listOf(accentOrange, accentPink),
        start = androidx.compose.ui.geometry.Offset.Zero,
        end = androidx.compose.ui.geometry.Offset(100f, 100f)
    )

    val coolGradient = Brush.linearGradient(
        colors = listOf(accentBlue, accentGreen),
        start = androidx.compose.ui.geometry.Offset.Zero,
        end = androidx.compose.ui.geometry.Offset(100f, 100f)
    )

    val authGradient = Brush.verticalGradient(
        colors = listOf(
            Color(0xFF2E354A),
            Color(0xFF0A0C1A)
        )
    )

    val glassGradient = Brush.verticalGradient(
        colors = listOf(
            Color.White.copy(alpha = 0.08f),
            Color.White.copy(alpha = 0.02f)
        )
    )
}

// MARK: - Custom Shapes
val VKShapes = Shapes(
    small = RoundedCornerShape(8.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(20.dp)
)

private val DarkColorScheme = darkColorScheme(
    primary = VKColors.accentBlue,
    secondary = VKColors.accentPurple,
    tertiary = VKColors.accentPink,
    background = VKColors.background,
    surface = VKColors.surface,
    surfaceVariant = VKColors.cardBackground,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = VKColors.textPrimary,
    onSurface = VKColors.textPrimary,
    onSurfaceVariant = VKColors.textSecondary,
    outline = VKColors.textTertiary
)

@Composable
fun VKZTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography(),
        shapes = VKShapes,
        content = content
    )
}