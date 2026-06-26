package com.werhes.vk_z

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * VK API Plugin for Android.
 *
 * Чистый VK API клиент на Kotlin.
 * Использует прямые HTTP-запросы к VK API v5.131.
 * Авторизация через Kate Mobile (bypass audio).
 *
 * API v5.131, Kate Mobile User-Agent, GET-запросы к api.vk.ru/method/
 */
class VkApiPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var accessToken: String? = null
    private var userId: Int? = null
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val API_BASE = "https://api.vk.ru/method"
        private const val API_VERSION = "5.131"
        private const val USER_AGENT = "KateMobileAndroid/56 lite-460 (Android 4.4.2; SDK 19; x86; unknown Android SDK built for x86; en)"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "vk_api")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setToken" -> {
                accessToken = call.argument<String>("token")
                userId = call.argument<Int>("userId")
                result.success(true)
            }
            "call" -> {
                val method = call.argument<String>("method") ?: run {
                    result.error("INVALID_ARGS", "method is required", null)
                    return
                }
                val params = call.argument<Map<String, String>>("params") ?: emptyMap()
                callVkApi(method, params, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun callVkApi(method: String, params: Map<String, String>, result: Result) {
        val token = accessToken
        if (token == null) {
            result.error("NOT_AUTHORIZED", "Not authorized", null)
            return
        }

        executor.execute {
            try {
                val queryParams = params.toMutableMap()
                queryParams["access_token"] = token
                queryParams["v"] = API_VERSION
                queryParams["lang"] = "ru"

                val queryString = queryParams.entries.joinToString("&") { "${it.key}=${java.net.URLEncoder.encode(it.value, "UTF-8")}" }
                val url = URL("$API_BASE/$method?$queryString")

                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.setRequestProperty("User-Agent", USER_AGENT)
                connection.setRequestProperty("Accept-Language", "ru")
                connection.connectTimeout = 30000
                connection.readTimeout = 30000

                val responseCode = connection.responseCode
                val reader = BufferedReader(
                    InputStreamReader(
                        if (responseCode == 200) connection.inputStream else connection.errorStream
                    )
                )
                val response = reader.readText()
                reader.close()
                connection.disconnect()

                if (responseCode != 200) {
                    mainHandler.post { result.error("HTTP_ERROR", "HTTP $responseCode: $response", null) }
                    return@execute
                }

                val json = JSONObject(response)
                if (json.has("error")) {
                    val error = json.getJSONObject("error")
                    val code = error.optInt("error_code", 0)
                    val msg = error.optString("error_msg", "Unknown")
                    mainHandler.post { result.error("VK_API_ERROR", "[$code] $msg", null) }
                    return@execute
                }

                val responseData = json.opt("response") ?: json
                mainHandler.post { result.success(responseData.toString()) }
            } catch (e: Exception) {
                mainHandler.post { result.error("NETWORK_ERROR", e.message, null) }
            }
        }
    }
}