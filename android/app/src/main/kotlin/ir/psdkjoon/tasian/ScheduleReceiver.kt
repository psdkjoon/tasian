package ir.psdkjoon.tasian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ScheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Reminders.ACTION -> Unit
            DayNotifier.ACTION_GUARD -> DayNotifier.ensure(context)
            else -> DayNotifier.refresh(context)
        }
        Reminders.reschedule(context)
    }
}
