import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasian/app.dart';
import 'package:tasian/calendar/today_controller.dart';
import 'package:tasian/core/kv_store.dart';
import 'package:tasian/events/events_controller.dart';
import 'package:tasian/platform/day_notification_service.dart';
import 'package:tasian/platform/launcher_icon_service.dart';
import 'package:tasian/platform/reminder_service.dart';
import 'package:tasian/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = await KvStore.open();
  final settings = AppSettings.load(store);
  final events = EventsController.load(store);
  final today = TodayController();

  runApp(TasianApp(settings: settings, events: events, today: today));

  unawaited(_initPlatform(settings, events, today));
}

Future<void> _initPlatform(
  AppSettings settings,
  EventsController events,
  TodayController today,
) async {
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } on Object {
    debugPrint('edge-to-edge unavailable');
  }

  LauncherIconService.init(settings);
  DayNotificationService.follow(settings, events, today);
  ReminderService.follow(settings, events);
}
