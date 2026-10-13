package ir.psdkjoon.tasian

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import org.json.JSONArray
import org.json.JSONObject

object Reminders {
    const val ACTION = "ir.psdkjoon.tasian.REMINDER"

    private const val CHANNEL = "events"
    private const val PREFS = "reminders"
    private const val MISSED_GRACE_MS = 12L * 60 * 60 * 1000
    private const val EARLY_MS = 1000L

    private class Item(val id: Long, val at: Long, val title: String, val body: String)

    fun sync(context: Context, reminders: List<Map<String, Any>>) {
        val array = JSONArray()
        for (reminder in reminders) array.put(JSONObject(reminder))
        prefs(context).edit().putString("items", array.toString()).apply()
        reschedule(context)
    }

    fun reschedule(context: Context) {
        val now = System.currentTimeMillis()
        val pending = ArrayList<Item>()
        for (item in load(context)) {
            if (item.at <= now + EARLY_MS) {
                if (now - item.at <= MISSED_GRACE_MS) post(context, item)
            } else {
                pending.add(item)
            }
        }
        val array = JSONArray()
        for (item in pending) {
            array.put(
                JSONObject()
                    .put("id", item.id)
                    .put("at", item.at)
                    .put("title", item.title)
                    .put("body", item.body),
            )
        }
        prefs(context).edit().putString("items", array.toString()).apply()

        val next = pending.minByOrNull { it.at }
        if (next == null) {
            NotificationHelper.cancelAlarm(context, alarmIntent(context))
        } else {
            NotificationHelper.alarm(context, next.at, alarmIntent(context))
        }
    }

    private fun load(context: Context): List<Item> {
        val items = ArrayList<Item>()
        try {
            val array = JSONArray(prefs(context).getString("items", "[]"))
            for (i in 0 until array.length()) {
                val json = array.getJSONObject(i)
                items.add(
                    Item(
                        json.getLong("id"),
                        json.getLong("at"),
                        json.optString("title"),
                        json.optString("body"),
                    ),
                )
            }
        } catch (_: Exception) {
        }
        return items
    }

    private fun post(context: Context, item: Item) {
        NotificationHelper.ensureChannel(
            context,
            CHANNEL,
            context.getString(R.string.reminder_channel),
            NotificationManager.IMPORTANCE_HIGH,
        )
        val builder = NotificationHelper.builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_tile)
            .setContentTitle(item.title)
            .setContentIntent(NotificationHelper.openApp(context))
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_EVENT)
        if (item.body.isNotEmpty()) {
            builder
                .setContentText(item.body.lineSequence().first())
                .setStyle(Notification.BigTextStyle().bigText(item.body))
        }
        val id = (item.id xor (item.id ushr 32)).toInt()
        NotificationHelper.post(context, id, builder.build())
    }

    private fun alarmIntent(context: Context): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            2,
            Intent(context, ScheduleReceiver::class.java).setAction(ACTION),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
