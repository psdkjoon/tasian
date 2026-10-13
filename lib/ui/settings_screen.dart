import 'dart:async';

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:tasian/core/date_format.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/platform/notification_service.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_spacing.dart';
import 'package:tasian/ui/language_sheet.dart';
import 'package:tasian/ui/widgets/calendar_order_list.dart';
import 'package:tasian/ui/widgets/calendar_selector.dart';
import 'package:tasian/ui/widgets/page_frame.dart';
import 'package:tasian/ui/widgets/settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.settings, super.key});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                SettingsSection(
                  title: 'Appearance',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SegmentedButton<ThemeMode>(
                        expandedInsets: EdgeInsets.zero,
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Auto'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Latte'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Mocha'),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selection) =>
                            settings.themeMode = selection.first,
                      ),
                    ),
                  ],
                ),
                if (L10n.languages.length > 1)
                  SettingsSection(
                    title: 'Language',
                    children: [
                      ListTile(
                        title: const Text('Language'),
                        subtitle: Text(_languageName(settings.language)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _pickLanguage(context),
                      ),
                    ],
                  ),
                SettingsSection(
                  title: 'Calendars',
                  help:
                      'The main calendar is shown first everywhere and gives the notification its title. The other calendars you pick follow it in the order you set, in the notification, in the date lists and next to the day numbers in the month view.',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.sm,
                        children: [
                          Text(
                            'Main calendar',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          CalendarSelector(
                            selected: settings.mainCalendar,
                            onSelected: (kind) => settings.mainCalendar = kind,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.sm,
                        children: [
                          Text(
                            'Also show, in this order',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          CalendarOrderList(settings: settings),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.sm,
                        children: [
                          Text(
                            'Week starts on',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          SegmentedButton<int>(
                            expandedInsets: EdgeInsets.zero,
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 0, label: Text('Auto')),
                              ButtonSegment(
                                value: DateTime.saturday,
                                label: Text('Sat'),
                              ),
                              ButtonSegment(
                                value: DateTime.sunday,
                                label: Text('Sun'),
                              ),
                              ButtonSegment(
                                value: DateTime.monday,
                                label: Text('Mon'),
                              ),
                            ],
                            selected: {settings.weekStart},
                            onSelectionChanged: (selection) =>
                                settings.weekStart = selection.first,
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Persian digits'),
                      subtitle: const Text(
                        'Write ۱۴۰۵ instead of 1405 for Jalali and Deylami dates',
                      ),
                      value: settings.persianDigits,
                      onChanged: (value) => settings.persianDigits = value,
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'Notifications',
                  help:
                      'The notification stays in the notification bar and shows the day number as its small icon. It changes at midnight, and it lists today\'s events. Event reminders arrive at the time you set on each event. Events without a time use the reminder time below.',
                  children: [
                    SwitchListTile(
                      title: const Text('Show today in the notification bar'),
                      subtitle: const Text(
                        'A constant notification with the date',
                      ),
                      value: settings.dayNotification,
                      onChanged: (value) {
                        settings.dayNotification = value;
                        if (value) unawaited(NotificationService.requestPermission());
                      },
                    ),
                    ListTile(
                      title: const Text('Reminder time for all-day events'),
                      subtitle: Text(
                        DateFormatter.time(settings.timelessMinute),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _pickReminderTime(context),
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'Updates',
                  children: [
                    SwitchListTile(
                      title: const Text('Check for updates'),
                      subtitle: const Text(
                        'Look for a newer version when the app starts',
                      ),
                      value: settings.checkUpdates,
                      onChanged: (value) => settings.checkUpdates = value,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _languageName(String code) {
    if (code == L10n.system) return 'System default'.tr;
    for (final language in L10n.languages) {
      if (language.code == code) return language.name;
    }
    return code;
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final current = settings.timelessMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    settings.timelessMinute = picked.hour * 60 + picked.minute;
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final picked = await showLanguageSheet(context, settings.language);
    if (picked != null) settings.language = picked;
  }
}
