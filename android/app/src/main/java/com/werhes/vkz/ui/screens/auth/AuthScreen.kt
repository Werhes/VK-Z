package com.werhes.vkz.ui.screens.auth

import android.annotation.SuppressLint
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.werhes.vkz.data.api.AuthManager
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine

@Composable
fun AuthScreen() {
    var showWebView by remember { mutableStateOf(false) }
    var isAuthenticated by remember { mutableStateOf(AuthManager.isAuthenticated()) }
    var authMode by remember { mutableStateOf(0) } // 0 = token, 1 = phone
    var tokenInput by remember { mutableStateOf("") }
    var phoneInput by remember { mutableStateOf("") }
    var passwordInput by remember { mutableStateOf("") }
    var twoFactorCode by remember { mutableStateOf("") }
    var showTwoFactor by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var twoFactorContinuation by remember { mutableStateOf<((String) -> Unit)?>(null) }
    val scope = rememberCoroutineScope()

    if (isAuthenticated) return

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF263040),
                        Color(0xFF0D0F1F)
                    )
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(40.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(40.dp))

            Text(
                text = "♪",
                fontSize = 60.sp,
                color = Color(0xFF3F7AFF)
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "VK Z",
                style = MaterialTheme.typography.headlineLarge,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Музыка ВКонтакте\nбез ограничений",
                style = MaterialTheme.typography.bodyLarge,
                color = Color.Gray,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Auth mode tabs
            TabRow(
                selectedTabIndex = authMode,
                containerColor = Color.Transparent,
                contentColor = Color.White,
                modifier = Modifier.fillMaxWidth()
            ) {
                Tab(
                    selected = authMode == 0,
                    onClick = { authMode = 0; errorMessage = null; showTwoFactor = false },
                    text = { Text("По токену") }
                )
                Tab(
                    selected = authMode == 1,
                    onClick = { authMode = 1; errorMessage = null; showTwoFactor = false },
                    text = { Text("По телефону") }
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Token input
            if (authMode == 0) {
                Text(
                    text = "Введите токен доступа",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.Gray
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = tokenInput,
                    onValueChange = { tokenInput = it },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = Color(0xFF3F7AFF),
                        unfocusedBorderColor = Color.Gray
                    ),
                    visualTransformation = PasswordVisualTransformation(),
                    singleLine = true
                )
            }

            // Phone + Password input
            if (authMode == 1) {
                OutlinedTextField(
                    value = phoneInput,
                    onValueChange = { phoneInput = it },
                    label = { Text("Номер телефона", color = Color.Gray) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = Color(0xFF3F7AFF),
                        unfocusedBorderColor = Color.Gray
                    ),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = passwordInput,
                    onValueChange = { passwordInput = it },
                    label = { Text("Пароль", color = Color.Gray) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = Color(0xFF3F7AFF),
                        unfocusedBorderColor = Color.Gray
                    ),
                    visualTransformation = PasswordVisualTransformation(),
                    singleLine = true
                )

                // 2FA Code Input
                if (showTwoFactor) {
                    Spacer(modifier = Modifier.height(12.dp))

                    Text(
                        text = "Код двухфакторной авторизации",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color(0xFFFFA500)
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    OutlinedTextField(
                        value = twoFactorCode,
                        onValueChange = { twoFactorCode = it },
                        modifier = Modifier.fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedBorderColor = Color(0xFFFFA500),
                            unfocusedBorderColor = Color.Gray
                        ),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                        singleLine = true
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // OAuth button (only for token mode)
            if (authMode == 0) {
                Button(
                    onClick = { showWebView = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF3F7AFF)
                    ),
                    shape = MaterialTheme.shapes.medium
                ) {
                    Text(
                        text = "Войти через VK",
                        style = MaterialTheme.typography.titleMedium,
                        color = Color.White
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
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (showTwoFactor) Color(0xFFFFA500) else Color(0xFF3F7AFF).copy(alpha = 0.7f)
                ),
                shape = MaterialTheme.shapes.medium,
                enabled = !isLoading
            ) {
                Text(
                    text = when {
                        isLoading -> "Авторизация..."
                        showTwoFactor -> "Отправить код 2FA"
                        authMode == 0 -> "Войти по токену"
                        else -> "Войти"
                    },
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White
                )
            }

            if (isLoading) {
                Spacer(modifier = Modifier.height(12.dp))
                CircularProgressIndicator(color = Color.White)
            }

            if (errorMessage != null) {
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = errorMessage!!,
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.Red,
                    textAlign = TextAlign.Center
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            Text(
                text = "v1.0 · by Werhes",
                style = MaterialTheme.typography.bodySmall,
                color = Color.Gray.copy(alpha = 0.6f)
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