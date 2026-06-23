package com.vkz.player.service

import android.app.Service
import android.content.Intent
import android.os.PowerManager

/**
 * Base class for audio service to handle audio focus, WakeLock, and lifecycle.
 * Acquires a PARTIAL_WAKE_LOCK to allow playback when the screen is off.
 */
abstract class BaseAudioService : Service() {

    private var wakeLock: PowerManager.WakeLock? = null

    /**
     * Acquire a partial WakeLock to keep CPU running for background playback.
     */
    protected fun acquireWakeLock() {
        if (wakeLock == null || wakeLock?.isHeld == false) {
            val powerManager = getSystemService(PowerManager::class.java)
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "VKZ:AudioPlaybackWakeLock"
            ).apply {
                acquire()
            }
        }
    }

    /**
     * Release the WakeLock when playback is paused or stopped.
     */
    protected fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // Stop service when app is swiped away from recents
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        releaseWakeLock()
    }
}