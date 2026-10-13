import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tasian/calendar/today_controller.dart';
import 'package:tasian/core/day_notification_builder.dart';
import 'package:tasian/events/events_controller.dart';
import 'package:tasian/settings/app_settings.dart';

abstract class DayNotificationService {
  static const _channel = MethodChannel('tasian/day_notification');
  static const _delay = Duration(milliseconds: 400);

  static Timer? _timer;

  static void follow(
    AppSettings settings,
    EventsController events,
    TodayController today,
  ) {
    if (!Platform.isAndroid) return;
    Listenable.merge([settings, events, today]).addListener(() {
      _timer?.cancel();
      _timer = Timer(_delay, () => unawaited(_push(settings, events, today)));
    });
    unawaited(_push(settings, events, today));
  }

  static Future<void> _push(
    AppSettings settings,
    EventsController events,
    TodayController today,
  ) async {
    final enabled = settings.dayNotification;
    final entries = enabled
        ? DayNotificationBuilder.build(
            fromJdn: today.jdn,
            main: settings.mainCalendar,
            extras: settings.extraCalendars,
            persian: settings.persianDigits,
            eventsOn: events.forDay,
          )
        : const <DayNotificationEntry>[];
    try {
      await _channel.invokeMethod<void>('sync', {
        'enabled': enabled,
        'entries': [
          for (final entry in entries)
            {
              'date': entry.date,
              'title': entry.title,
              'body': entry.body,
              'badge': entry.badge,
            },
        ],
      });
    } on PlatformException {
      return;
    }
  }
}
