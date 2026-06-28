package com.werhes.vkz.data.api

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri

object AuthManager {
    private const val PREFS_NAME = "vkz_prefs"
    private const val KEY_TOKEN = "vk_access_token"
    private const val KEY_USER_ID = "vk_user_id"

    private var prefs: SharedPreferences? = null

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
}