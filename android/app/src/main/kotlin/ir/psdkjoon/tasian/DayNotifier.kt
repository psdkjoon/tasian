package ir.psdkjoon.tasian

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale

object DayNotifier {
    const val ACTION = "ir.psdkjoon.tasian.DAY_TICK"
    const val ACTION_RESTORE = "ir.psdkjoon.tasian.DAY_RESTORE"
    const val ACTION_GUARD = "ir.psdkjoon.tasian.DAY_GUARD"

    private const val CHANNEL = "day_silent"
    private const val OLD_CHANNEL = "day"
    private const val NOTIFICATION_ID = 1
    private const val PREFS = "day_notifier"
    private const val BADGE_SIZE = 96
    private const val GUARD_INTERVAL = 15 * 60 * 1000L

    fun sync(context: Context, enabled: Boolean, entries: List<Map<String, String>>) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!enabled) {
            prefs.edit().clear().apply()
            NotificationHelper.manager(context)?.cancel(NOTIFICATION_ID)
            NotificationHelper.cancelAlarm(context, tick(context))
            NotificationHelper.cancelAlarm(context, guard(context))
            return
        }
        val array = JSONArray()
        for (entry in entries) array.put(JSONObject(entry))
        prefs.edit()
            .putBoolean("enabled", true)
            .putString("entries", array.toString())
            .apply()
        refresh(context)
    }

    fun refresh(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean("enabled", false)) return
        val key = todayKey()
        var today: JSONObject? = null
        try {
            val array = JSONArray(prefs.getString("entries", "[]"))
            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)
                if (item.optString("date") == key) {
                    today = item
                    break
                }
            }
        } catch (_: Exception) {
        }
        if (today == null) {
            NotificationHelper.manager(context)?.cancel(NOTIFICATION_ID)
        } else {
            show(
                context,
                today.optString("title"),
                today.optString("body"),
                today.optString("badge"),
            )
        }
        scheduleNextMidnight(context)
        scheduleGuard(context)
    }

    fun ensure(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean("enabled", false)) return
        var visible = false
        if (Build.VERSION.SDK_INT >= 23) {
            try {
                visible = NotificationHelper.manager(context)
                    ?.activeNotifications
                    ?.any { it.id == NOTIFICATION_ID } == true
            } catch (_: Exception) {
            }
        }
        if (visible) scheduleGuard(context) else refresh(context)
    }

    private fun show(context: Context, title: String, body: String, badge: String) {
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationHelper.manager(context)?.deleteNotificationChannel(OLD_CHANNEL)
        }
        NotificationHelper.ensureChannel(
            context,
            CHANNEL,
            context.getString(R.string.day_channel),
            NotificationManager.IMPORTANCE_LOW,
        )
        val builder = NotificationHelper.builder(context, CHANNEL)
        if (Build.VERSION.SDK_INT >= 23 && badge.isNotEmpty()) {
            builder.setSmallIcon(Icon.createWithBitmap(badgeBitmap(badge)))
        } else {
            builder.setSmallIcon(R.drawable.ic_tile)
        }
        builder
            .setContentTitle(title)
            .setContentIntent(NotificationHelper.openApp(context))
            .setOngoing(true)
            .setAutoCancel(false)
            .setDeleteIntent(restore(context))
            .setOnlyAlertOnce(true)
            .setPriority(android.app.Notification.PRIORITY_LOW)
            .setSound(null)
            .setVibrate(null)
            .setShowWhen(false)
            .setVisibility(android.app.Notification.VISIBILITY_PUBLIC)
        if (body.isNotEmpty()) {
            builder
                .setContentText(body.lineSequence().first())
                .setStyle(android.app.Notification.BigTextStyle().bigText(body))
        }
        NotificationHelper.post(context, NOTIFICATION_ID, builder.build())
    }

    private fun badgeBitmap(text: String): Bitmap {
        val bitmap = Bitmap.createBitmap(BADGE_SIZE, BADGE_SIZE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = Color.WHITE
        paint.typeface = Typeface.DEFAULT_BOLD
        paint.textAlign = Paint.Align.CENTER
        paint.textSize = if (text.length > 2) 52f else 76f
        val y = BADGE_SIZE / 2f - (paint.descent() + paint.ascent()) / 2f
        canvas.drawText(text, BADGE_SIZE / 2f, y, paint)
        return bitmap
    }

    private fun todayKey(): String {
        val now = Calendar.getInstance()
        return String.format(
            Locale.US,
            "%04d-%02d-%02d",
            now.get(Calendar.YEAR),
            now.get(Calendar.MONTH) + 1,
            now.get(Calendar.DAY_OF_MONTH),
        )
    }

    private fun tick(context: Context): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            1,
            Intent(context, ScheduleReceiver::class.java).setAction(ACTION),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun restore(context: Context): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            2,
            Intent(context, ScheduleReceiver::class.java).setAction(ACTION_RESTORE),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun guard(context: Context): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            3,
            Intent(context, ScheduleReceiver::class.java).setAction(ACTION_GUARD),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun scheduleGuard(context: Context) {
        NotificationHelper.inexactAlarm(
            context,
            System.currentTimeMillis() + GUARD_INTERVAL,
            guard(context),
        )
    }

    private fun scheduleNextMidnight(context: Context) {
        val next = Calendar.getInstance()
        next.add(Calendar.DAY_OF_YEAR, 1)
        next.set(Calendar.HOUR_OF_DAY, 0)
        next.set(Calendar.MINUTE, 0)
        next.set(Calendar.SECOND, 1)
        next.set(Calendar.MILLISECOND, 0)
        NotificationHelper.alarm(context, next.timeInMillis, tick(context))
    }
}
