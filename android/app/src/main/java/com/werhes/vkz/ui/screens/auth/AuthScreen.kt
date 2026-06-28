package com.werhes.vkz.ui.screens.auth

import android.annotation.SuppressLint
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.werhes.vkz.data.api.AuthManager

@Composable
fun AuthScreen() {
    var showWebView by remember { mutableStateOf(false) }
    var isAuthenticated by remember { mutableStateOf(AuthManager.isAuthenticated()) }

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
                .padding(40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Spacer(modifier = Modifier.weight(1f))

            Text(
                text = "♪",
                fontSize = 80.sp,
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

            Spacer(modifier = Modifier.weight(1f))

            Button(
                onClick = { showWebView = true },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
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

            Spacer(modifier = Modifier.height(30.dp))

            Text(
                text = "v1.0 · by Werhes",
                style = MaterialTheme.typography.bodySmall,
                color = Color.Gray.copy(alpha = 0.6f)
            )
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