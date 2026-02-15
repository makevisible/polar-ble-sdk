package com.polar.polarsensordatacollector.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.content.ContextCompat
import com.polar.polarsensordatacollector.R

/**
 * Foreground service that keeps the app process alive and the CPU awake
 * while OHR automation is running. This ensures the coroutine-based timer
 * continues to tick even when the screen is off / device enters Doze mode.
 */
class OhrAutomationService : Service() {

    companion object {
        private const val TAG = "OhrAutoService"
        private const val NOTIFICATION_ID = 2
        private const val CHANNEL_ID = "ohr_automation_channel"
        private const val CHANNEL_NAME = "OHR Automation"
        private const val WAKE_LOCK_TAG = "psdc:ohr_automation_wake_lock"

        fun startService(context: Context) {
            Log.d(TAG, "Starting OHR automation service")
            val intent = Intent(context.applicationContext, OhrAutomationService::class.java)
            ContextCompat.startForegroundService(context.applicationContext, intent)
        }

        fun stopService(context: Context) {
            Log.d(TAG, "Stopping OHR automation service")
            val intent = Intent(context.applicationContext, OhrAutomationService::class.java)
            context.applicationContext.stopService(intent)
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        acquireWakeLock()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        releaseWakeLock()
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                WAKE_LOCK_TAG
            ).apply {
                acquire()
            }
            Log.d(TAG, "WakeLock acquired")
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
                Log.d(TAG, "WakeLock released")
            }
        }
        wakeLock = null
    }

    private fun createNotification(): Notification {
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "OHR data logging automation in progress"
        }
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.createNotificationChannel(channel)

        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("OHR Automation Running")
            .setContentText("Recording and downloading OHR data")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
    }
}
