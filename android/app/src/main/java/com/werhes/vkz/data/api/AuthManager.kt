package com.werhes.vkz.data.api

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume

object AuthManager {
    private const val PREFS_NAME = "vkz_prefs"
    private const val KEY_TOKEN = "vk_access_token"
    private const val KEY_USER_ID = "vk_user_id"

    private var prefs: SharedPreferences? = null
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun saveToken(token: String, userId: Int) {
        prefs?.edit()?.apply {
            putString(KEY_TOKEN, token)
            putInt(KEY_USER_ID, userId)
            apply()
        }
    }

    fun getToken(): String? = prefs?.getString(KEY_TOKEN, null)

    fun getUserId(): Int = prefs?.getInt(KEY_USER_ID, 0) ?: 0

    fun isAuthenticated(): Boolean = getToken() != null

    fun logout() {
        prefs?.edit()?.apply {
            remove(KEY_TOKEN)
            remove(KEY_USER_ID)
            apply()
        }
    }

    fun getAuthUrl(): String {
        return Uri.Builder()
            .scheme("https")
            .authority("oauth.vk.com")
            .path("authorize")
            .appendQueryParameter("client_id", VKApi.CLIENT_ID)
            .appendQueryParameter("display", "mobile")
            .appendQueryParameter("redirect_uri", "vk://vkz/auth")
            .appendQueryParameter("scope", "audio,offline")
            .appendQueryParameter("response_type", "token")
            .appendQueryParameter("v", VKApi.API_VERSION)
            .build()
            .toString()
    }

    fun handleAuthUrl(url: String): Boolean {
        val uri = Uri.parse(url)
        val fragment = uri.fragment ?: return false

        val params = fragment.split("&").associate {
            val parts = it.split("=")
            parts[0] to parts.getOrElse(1) { "" }
        }

        val token = params["access_token"] ?: return false
        val userId = params["user_id"]?.toIntOrNull() ?: return false

        saveToken(token, userId)
        return true
    }

    // Auth by phone + password + 2FA
    suspend fun authorizeWithLogin(
        login: String,
        password: String,
        onTwoFactorRequired: suspend (String) -> String
    ): Boolean = withContext(Dispatchers.IO) {
        val url = "https://api.vk.com/method/auth.login"
        
        // First attempt without 2FA
        var response = makeAuthRequest(url, login, password, null)
        
        // Check if 2FA is required
        if (response.optString("error") == "need_validation" || 
            response.optString("validation_type") == "2fa") {
            
            val sid = response.optString("validation_sid")
            val code = onTwoFactorRequired(sid)
            
            response = makeAuthRequest(url, login, password, code)
        }
        
        val accessToken = response.optString("access_token")
        val userId = response.optInt("user_id")
        
        if (accessToken.isNotEmpty() && userId > 0) {
            saveToken(accessToken, userId)
            true
        } else {
            throw Exception(response.optString("error", "Unknown auth error"))
        }
    }

    private fun makeAuthRequest(
        url: String,
        login: String,
        password: String,
        code: String?
    ): JSONObject {
        val formBuilder = FormBody.Builder()
            .add("client_id", VKApi.CLIENT_ID)
            .add("client_secret", VKApi.CLIENT_SECRET)
            .add("username", login)
            .add("password", password)
            .add("v", VKApi.API_VERSION)
            .add("scope", "audio,offline")
            .add("grant_type", "password")
        
        if (code != null) {
            formBuilder.add("code", code)
        }
        
        val request = Request.Builder()
            .url(url)
            .addHeader("User-Agent", "VK-Z/1.0 (Android 14; Scale/2.0)")
            .addHeader("Content-Type", "application/x-www-form-urlencoded")
            .post(formBuilder.build())
            .build()
        
        val response = httpClient.newCall(request).execute()
        val body = response.body?.string() ?: "{}"
        return JSONObject(body)
    }
}