package com.vkz.player.data.network

import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

/**
 * Retrofit client for VK API
 */
object VkApiClient {

    private var accessToken: String = ""

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val authInterceptor = Interceptor { chain ->
        val original = chain.request()
        val url = original.url.newBuilder()
            .addQueryParameter("access_token", accessToken)
            .addQueryParameter("v", VkApiService.VK_API_VERSION)
            .build()
        val request = original.newBuilder()
            .url(url)
            .addHeader("User-Agent", "VKZ-Android/1.0")
            .build()
        chain.proceed(request)
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(authInterceptor)
        .addInterceptor(loggingInterceptor)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl(VkApiService.BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    val apiService: VkApiService = retrofit.create(VkApiService::class.java)

    /**
     * Set VK access token
     */
    fun setToken(token: String) {
        accessToken = token
    }

    /**
     * Check if token is set
     */
    fun hasToken(): Boolean = accessToken.isNotEmpty()
}