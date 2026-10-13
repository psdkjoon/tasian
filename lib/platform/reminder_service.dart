import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tasian/core/date_format.dart';
import 'package:tasian/events/event_item.dart';
import 'package:tasian/events/events_controller.dart';
import 'package:tasian/settings/app_settings.dart';

abstract class ReminderService {
  static const _channel = MethodChannel('tasian/reminders');
  static const _delay = Duration(milliseconds: 400);
  static const int _maxReminders = 300;

  static Timer? _timer;

  static void follow(AppSettings settings, EventsController events) {
    if (!Platform.isAndroid) return;
    Listenable.merge([settings, events]).addListener(() {
      _timer?.cancel();
      _timer = Timer(_delay, () => unawaited(_push(settings, events)));
    });
    unawaited(_push(settings, events));
  }

  static Future<void> _push(
    AppSettings settings,
    EventsController events,
  ) async {
    final now = DateTime.now();
    final minute = settings.timelessMinute;
    final due = <({DateTime at, EventItem item})>[];
    for (final item in events.all) {
      final at = item.remindAt(minute);
      if (at != null && at.isAfter(now)) due.add((at: at, item: item));
    }
    due.sort((a, b) => a.at.compareTo(b.at));
    try {
      await _channel.invokeMethod<void>('sync', {
        'reminders': [
          for (final entry in due.take(_maxReminders))
            {
              'id': entry.item.id,
              'at': entry.at.millisecondsSinceEpoch,
              'title': entry.item.title,
              'body': _body(entry.item, settings),
            },
        ],
      });
    } on PlatformException {
      return;
    }
  }

  static String _body(EventItem item, AppSettings settings) {
    final day = DateFormatter.fullOn(
      settings.mainCalendar,
      item.jdn,
      persian: settings.persianDigits,
    );
    final minute = item.minute;
    final when = minute == null ? day : '$day, ${DateFormatter.time(minute)}';
    return item.note.isEmpty ? when : '$when\n${item.note}';
  }
}
