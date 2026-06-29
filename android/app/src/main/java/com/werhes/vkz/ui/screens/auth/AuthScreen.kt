package com.werhes.vkz.ui.screens.auth

import android.annotation.SuppressLint
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.werhes.vkz.data.api.AuthManager
import com.werhes.vkz.ui.theme.VKColors
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine

@Composable
fun AuthScreen() {
    var showWebView by remember { mutableStateOf(false) }
    var isAuthenticated by remember { mutableStateOf(AuthManager.isAuthenticated()) }
    var authMode by remember { mutableStateOf(0) }
    var tokenInput by remember { mutableStateOf("") }
    var phoneInput by remember { mutableStateOf("") }
    var passwordInput by remember { mutableStateOf("") }
    var twoFactorCode by remember { mutableStateOf("") }
    var showTwoFactor by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var twoFactorContinuation by remember { mutableStateOf<((String) -> Unit)?>(null) }
    val scope = rememberCoroutineScope()

    // Glow animation
    val infiniteTransition = rememberInfiniteTransition(label = "glow")
    val glowAlpha by infiniteTransition.animateFloat(
        initialValue = 0.4f,
        targetValue = 0.8f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = EaseInOutCubic),
            repeatMode = RepeatMode.Reverse
        ),
        label = "glowAlpha"
    )

    if (isAuthenticated) return

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(VKColors.authGradient)
    ) {
        // Glow orbs
        Box(
            modifier = Modifier
                .size(250.dp)
                .offset(x = (-50).dp, y = (-80).dp)
                .drawBehind {
                    drawCircle(
                        color = VKColors.accentBlue.copy(alpha = glowAlpha * 0.15f),
                        radius = size.width / 2,
                        center = center
                    )
                }
        )
        Box(
            modifier = Modifier
                .size(300.dp)
                .offset(x = 180.dp, y = 400.dp)
                .drawBehind {
                    drawCircle(
                        color = VKColors.accentPurple.copy(alpha = glowAlpha * 0.12f),
                        radius = size.width / 2,
                        center = center
                    )
                }
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(60.dp))

            // Logo
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .clip(RoundedCornerShape(24.dp))
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
                Text(
                    text = "♪",
                    fontSize = 36.sp,
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "VK Z",
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Музыка ВКонтакте\nбез ограничений",
                style = MaterialTheme.typography.bodyLarge,
                color = VKColors.textSecondary,
                textAlign = TextAlign.Center,
                lineHeight = 22.sp
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Auth mode tabs
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = VKColors.surface.copy(alpha = 0.6f)
                )
            ) {
                Column {
                    TabRow(
                        selectedTabIndex = authMode,
                        containerColor = Color.Transparent,
                        contentColor = Color.White,
                        indicator = { tabPositions ->
                            TabRowDefaults.SecondaryIndicator(
                                modifier = Modifier.tabIndicatorOffset(tabPositions[authMode]),
                                height = 3.dp,
                                color = VKColors.accentBlue
                            )
                        },
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    ) {
                        Tab(
                            selected = authMode == 0,
                            onClick = { authMode = 0; errorMessage = null; showTwoFactor = false },
                            text = {
                                Text(
                                    "По токену",
                                    fontWeight = if (authMode == 0) FontWeight.SemiBold else FontWeight.Normal,
                                    color = if (authMode == 0) Color.White else VKColors.textSecondary
                                )
                            }
                        )
                        Tab(
                            selected = authMode == 1,
                            onClick = { authMode = 1; errorMessage = null; showTwoFactor = false },
                            text = {
                                Text(
                                    "По телефону",
                                    fontWeight = if (authMode == 1) FontWeight.SemiBold else FontWeight.Normal,
                                    color = if (authMode == 1) Color.White else VKColors.textSecondary
                                )
                            }
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Token input
                    if (authMode == 0) {
                        Text(
                            text = "Введите токен доступа",
                            style = MaterialTheme.typography.bodyMedium,
                            color = VKColors.textSecondary,
                            modifier = Modifier.padding(horizontal = 16.dp)
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        OutlinedTextField(
                            value = tokenInput,
                            onValueChange = { tokenInput = it },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedBorderColor = VKColors.accentBlue,
                                unfocusedBorderColor = VKColors.textTertiary,
                                focusedContainerColor = VKColors.cardBackground.copy(alpha = 0.5f),
                                unfocusedContainerColor = VKColors.cardBackground.copy(alpha = 0.3f)
                            ),
                            visualTransformation = PasswordVisualTransformation(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )
                    }

                    // Phone + Password input
                    if (authMode == 1) {
                        OutlinedTextField(
                            value = phoneInput,
                            onValueChange = { phoneInput = it },
                            label = { Text("Номер телефона", color = VKColors.textSecondary) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedBorderColor = VKColors.accentBlue,
                                unfocusedBorderColor = VKColors.textTertiary,
                                focusedContainerColor = VKColors.cardBackground.copy(alpha = 0.5f),
                                unfocusedContainerColor = VKColors.cardBackground.copy(alpha = 0.3f)
                            ),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        OutlinedTextField(
                            value = passwordInput,
                            onValueChange = { passwordInput = it },
                            label = { Text("Пароль", color = VKColors.textSecondary) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedBorderColor = VKColors.accentBlue,
                                unfocusedBorderColor = VKColors.textTertiary,
                                focusedContainerColor = VKColors.cardBackground.copy(alpha = 0.5f),
                                unfocusedContainerColor = VKColors.cardBackground.copy(alpha = 0.3f)
                            ),
                            visualTransformation = PasswordVisualTransformation(),
                            singleLine = true,
                            shape = RoundedCornerShape(12.dp)
                        )

                        // 2FA Code Input
                        AnimatedVisibility(visible = showTwoFactor) {
                            Column {
                                Spacer(modifier = Modifier.height(12.dp))

                                Text(
                                    text = "Код двухфакторной авторизации",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = VKColors.accentOrange,
                                    modifier = Modifier.padding(horizontal = 16.dp)
                                )

                                Spacer(modifier = Modifier.height(4.dp))

                                OutlinedTextField(
                                    value = twoFactorCode,
                                    onValueChange = { twoFactorCode = it },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 16.dp),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedTextColor = Color.White,
                                        unfocusedTextColor = Color.White,
                                        focusedBorderColor = VKColors.accentOrange,
                                        unfocusedBorderColor = VKColors.textTertiary,
                                        focusedContainerColor = VKColors.cardBackground.copy(alpha = 0.5f),
                                        unfocusedContainerColor = VKColors.cardBackground.copy(alpha = 0.3f)
                                    ),
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                                    singleLine = true,
                                    shape = RoundedCornerShape(12.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    // OAuth button (only for token mode)
                    if (authMode == 0) {
                        Button(
                            onClick = { showWebView = true },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(52.dp)
                                .padding(horizontal = 16.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = VKColors.accentBlue
                            ),
                            shape = RoundedCornerShape(14.dp)
                        ) {
                            Text(
                                text = "Войти через VK",
                                style = MaterialTheme.typography.titleMedium,
                                color = Color.White,
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))
                    }

                    // Login button
                    Button(
                        onClick = {
                            if (authMode == 0) {
                                val token = tokenInput.trim()
                                if (token.isEmpty()) {
                                    errorMessage = "Введите токен доступа"
                                    return@Button
                                }
                                AuthManager.saveToken(token, 0)
                                isAuthenticated = true
                            } else {
                                if (showTwoFactor) {
                                    val code = twoFactorCode.trim()
                                    if (code.isEmpty()) {
                                        errorMessage = "Введите код двухфакторной авторизации"
                                        return@Button
                                    }
                                    twoFactorContinuation?.invoke(code)
                                    twoFactorContinuation = null
                                    isLoading = false
                                    return@Button
                                }

                                val phone = phoneInput.trim()
                                val password = passwordInput
                                if (phone.isEmpty() || password.isEmpty()) {
                                    errorMessage = "Введите номер телефона и пароль"
                                    return@Button
                                }

                                isLoading = true
                                errorMessage = null
                                scope.launch {
                                    try {
                                        AuthManager.authorizeWithLogin(
                                            login = phone,
                                            password = password,
                                            onTwoFactorRequired = { sid ->
                                                showTwoFactor = true
                                                isLoading = false
                                                suspendCancellableCoroutine { cont ->
                                                    twoFactorContinuation = { code ->
                                                        cont.resume(code)
                                                    }
                                                }
                                            }
                                        )
                                        isAuthenticated = true
                                    } catch (e: Exception) {
                                        errorMessage = e.message ?: "Ошибка авторизации"
                                    } finally {
                                        isLoading = false
                                    }
                                }
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp)
                            .padding(horizontal = 16.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (showTwoFactor) VKColors.accentOrange else VKColors.accentBlue.copy(alpha = 0.85f)
                        ),
                        shape = RoundedCornerShape(14.dp),
                        enabled = !isLoading
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(
                                color = Color.White,
                                modifier = Modifier.size(22.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text(
                                text = when {
                                    showTwoFactor -> "Отправить код 2FA"
                                    authMode == 0 -> "Войти по токену"
                                    else -> "Войти"
                                },
                                style = MaterialTheme.typography.titleMedium,
                                color = Color.White,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    if (errorMessage != null) {
                        Text(
                            text = errorMessage!!,
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color(0xFFFF4444),
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(horizontal = 16.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            Text(
                text = "v1.0 · by Werhes",
                style = MaterialTheme.typography.bodySmall,
                color = VKColors.textTertiary.copy(alpha = 0.6f)
            )

            Spacer(modifier = Modifier.height(20.dp))
        }
    }

    if (showWebView) {
        AuthWebView(
            onTokenReceived = {
                showWebView = false
                isAuthenticated = true
            }
        )
    }
}

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun AuthWebView(onTokenReceived: () -> Unit) {
    var webView by remember { mutableStateOf<WebView?>(null) }

    AlertDialog(
        onDismissRequest = { },
        modifier = Modifier.fillMaxSize(),
        confirmButton = {},
        text = {
            AndroidView(
                factory = { context ->
                    WebView(context).apply {
                        settings.javaScriptEnabled = true
                        webViewClient = object : WebViewClient() {
                            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                                if (url?.startsWith("vk://vkz/auth") == true) {
                                    if (AuthManager.handleAuthUrl(url)) {
                                        onTokenReceived()
                                    }
                                    return true
                                }
                                return false
                            }
                        }
                        loadUrl(AuthManager.getAuthUrl())
                        webView = this
                    }
                },
                modifier = Modifier.fillMaxSize()
            )
        }
    )
}