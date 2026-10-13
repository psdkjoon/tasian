package ir.psdkjoon.tasian

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object NotificationHelper {
    fun manager(context: Context): NotificationManager? =
        context.getSystemService(NotificationManager::class.java)

    fun ensureChannel(context: Context, id: String, name: String, importance: Int) {
        if (Build.VERSION.SDK_INT < 26) return
        val channel = NotificationChannel(id, name, importance)
        if (importance <= NotificationManager.IMPORTANCE_LOW) {
            channel.setShowBadge(false)
            channel.setSound(null, null)
            channel.enableVibration(false)
            channel.enableLights(false)
        }
        manager(context)?.createNotificationChannel(channel)
    }

    fun builder(context: Context, channel: String): Notification.Builder {
        return if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, channel)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
    }

    fun openApp(context: Context): PendingIntent {
        return PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    fun post(context: Context, id: Int, notification: Notification) {
        try {
            manager(context)?.notify(id, notification)
        } catch (_: SecurityException) {
        }
    }

    fun alarm(context: Context, atMillis: Long, intent: PendingIntent) {
        val manager = context.getSystemService(android.app.AlarmManager::class.java) ?: return
        val exact = Build.VERSION.SDK_INT < 31 || manager.canScheduleExactAlarms()
        try {
            when {
                Build.VERSION.SDK_INT < 23 ->
                    manager.setExact(android.app.AlarmManager.RTC_WAKEUP, atMillis, intent)
                exact ->
                    manager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, atMillis, intent)
                else ->
                    manager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, atMillis, intent)
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= 23) {
                manager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, atMillis, intent)
            }
        }
    }

    fun inexactAlarm(context: Context, atMillis: Long, intent: PendingIntent) {
        val manager = context.getSystemService(android.app.AlarmManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= 23) {
            manager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, atMillis, intent)
        } else {
            manager.set(android.app.AlarmManager.RTC_WAKEUP, atMillis, intent)
        }
    }

    fun cancelAlarm(context: Context, intent: PendingIntent) {
        context.getSystemService(android.app.AlarmManager::class.java)?.cancel(intent)
    }
}
