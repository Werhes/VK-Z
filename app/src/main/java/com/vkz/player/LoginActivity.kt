package com.vkz.player

import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.view.View
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.ProgressBar
import androidx.appcompat.app.AppCompatActivity
import com.vkz.player.data.network.VkApiClient
import com.vkz.player.data.network.VkApiService
import com.vkz.player.data.repository.SessionManager

/**
 * VK OAuth login activity
 * Uses VK OAuth 2.0 implicit flow to get access token
 */
class LoginActivity : AppCompatActivity() {

    private lateinit var webView: WebView
    private lateinit var progressBar: ProgressBar

    companion object {
        // Replace with your VK app credentials
        private const val VK_CLIENT_ID = "YOUR_VK_APP_ID"
        private const val VK_REDIRECT_URI = "https://oauth.vk.com/blank.html"
        private const val VK_SCOPE = "audio,offline"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)

        webView = findViewById(R.id.webview_login)
        progressBar = findViewById(R.id.progress_login)

        setupWebView()
        loadAuthUrl()
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView() {
        webView.apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowContentAccess = true
            settings.setSupportMultipleWindows(false)

            webViewClient = object : WebViewClient() {
                override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                    super.onPageStarted(view, url, favicon)
                    progressBar.visibility = View.VISIBLE
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    progressBar.visibility = View.GONE
                }

                override fun shouldOverrideUrlLoading(
                    view: WebView?,
                    url: String?
                ): Boolean {
                    return handleUrl(url)
                }
            }
        }
    }

    private fun loadAuthUrl() {
        val authUrl = buildString {
            append("https://oauth.vk.com/authorize?")
            append("client_id=$VK_CLIENT_ID")
            append("&display=mobile")
            append("&redirect_uri=$VK_REDIRECT_URI")
            append("&scope=$VK_SCOPE")
            append("&response_type=token")
            append("&v=${VkApiService.VK_API_VERSION}")
            append("&revoke=1")
        }
        webView.loadUrl(authUrl)
    }

    private fun handleUrl(url: String?): Boolean {
        if (url == null) return false

        // Check if we got redirected to the redirect URI with token
        if (url.startsWith(VK_REDIRECT_URI)) {
            if (url.contains("access_token=")) {
                // Extract token from URL fragment
                val fragment = url.substringAfter("#")
                val params = fragment.split("&").associate {
                    val parts = it.split("=", limit = 2)
                    parts[0] to parts.getOrElse(1) { "" }
                }

                val token = params["access_token"] ?: ""
                val userId = params["user_id"]?.toLongOrNull() ?: 0L

                if (token.isNotEmpty()) {
                    VkApiClient.setToken(token)
                    SessionManager.setToken(token)
                    SessionManager.setUserId(userId)

                    // Navigate to main activity
                    val intent = Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    }
                    startActivity(intent)
                    finish()
                    return true
                }
            } else if (url.contains("error=")) {
                // Handle error
                val errorMsg = url.substringAfter("error_description=").substringBefore("&")
                runOnUiThread {
                    android.widget.Toast.makeText(
                        this,
                        "Auth error: ${errorMsg.replace("+", " ")}",
                        android.widget.Toast.LENGTH_LONG
                    ).show()
                }
            }
            return true
        }
        return false
    }

    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}