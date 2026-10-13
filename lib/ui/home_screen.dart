import 'package:flutter/material.dart' hide Text, Icon;
import 'package:pcal/pcal.dart';
import 'package:tasian/calendar/today_controller.dart';
import 'package:tasian/core/calendar_math.dart';
import 'package:tasian/core/date_format.dart';
import 'package:tasian/events/event_item.dart';
import 'package:tasian/events/events_controller.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_spacing.dart';
import 'package:tasian/ui/event_sheet.dart';
import 'package:tasian/ui/widgets/compact_dates.dart';
import 'package:tasian/ui/widgets/event_tile.dart';
import 'package:tasian/ui/widgets/events_section.dart';
import 'package:tasian/ui/widgets/page_frame.dart';
import 'package:tasian/ui/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.settings,
    required this.events,
    required this.today,
    super.key,
  });

  final AppSettings settings;
  final EventsController events;
  final TodayController today;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([settings, events, today]),
      builder: (context, _) {
        final jdn = today.jdn;
        final date = CalendarMath.dateOrGregorian(settings.mainCalendar, jdn);
        final upcoming = events.upcoming(jdn + 1);
        return PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                _TodayCard(date: date, persian: settings.persianDigits),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.sm,
                  children: [
                    const SectionHeader(title: 'Also today in'),
                    CompactDates(
                      jdn: jdn,
                      settings: settings,
                      skip: settings.mainCalendar,
                    ),
                  ],
                ),
                EventsSection(
                  jdn: jdn,
                  settings: settings,
                  events: events,
                  title: 'Today',
                ),
                if (upcoming.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.sm,
                    children: [
                      const SectionHeader(title: 'Coming up'),
                      for (final item in upcoming)
                        _UpcomingEvent(
                          item: item,
                          today: jdn,
                          settings: settings,
                          events: events,
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
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.date, required this.persian});

  final CalendarDate date;
  final bool persian;

  static const double _leaf = 104;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kind = DateFormatter.kindOf(date);
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          spacing: AppSpacing.lg,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: SizedBox(
                width: _leaf,
                height: _leaf,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      DateFormatter.dayNumber(date, persian: persian),
                      style: theme.textTheme.displayMedium
                          ?.copyWith(color: scheme.onPrimary),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xxs,
                children: [
                  Text(
                    '${kind.title} calendar',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.primary),
                  ),
                  Text(DateFormatter.weekday(date), style: theme.textTheme.titleLarge),
                  Text(
                    DateFormatter.monthYear(date, persian: persian),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEvent extends StatelessWidget {
  const _UpcomingEvent({
    required this.item,
    required this.today,
    required this.settings,
    required this.events,
  });

  final EventItem item;
  final int today;
  final AppSettings settings;
  final EventsController events;

  @override
  Widget build(BuildContext context) {
    return EventTile(
      item: item,
      caption: DateFormatter.relativeDay(item.jdn - today).tr,
      onTap: () => showEventSheet(
        context,
        settings: settings,
        events: events,
        jdn: item.jdn,
        existing: item,
      ),
    );
  }
}
