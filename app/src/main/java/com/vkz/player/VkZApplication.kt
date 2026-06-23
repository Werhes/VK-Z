package com.vkz.player

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import com.vkz.player.data.cache.AppDatabase
import com.vkz.player.data.cache.CacheManager
import com.vkz.player.data.cache.DownloadManager
import com.vkz.player.data.cache.FavoritesManager
import com.vkz.player.data.network.VkApiClient

class VkZApplication : Application() {

    lateinit var cacheManager: CacheManager
        private set
    lateinit var downloadManager: DownloadManager
        private set
    lateinit var favoritesManager: FavoritesManager
        private set

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "vkz_playback"
        const val NOTIFICATION_CHANNEL_NAME = "VK Z Playback"
        lateinit var instance: VkZApplication
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()

        // Initialize cache system
        val db = AppDatabase.getInstance(this)
        cacheManager = CacheManager.getInstance(this)
        downloadManager = DownloadManager.getInstance(this)
        favoritesManager = FavoritesManager(db.cacheDao())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                NOTIFICATION_CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Music playback controls"
                setShowBadge(false)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}