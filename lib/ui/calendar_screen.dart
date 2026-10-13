import 'package:flutter/material.dart' hide Text, Icon;
import 'package:tasian/calendar/today_controller.dart';
import 'package:tasian/core/calendar_kind.dart';
import 'package:tasian/core/calendar_math.dart';
import 'package:tasian/core/date_format.dart';
import 'package:tasian/events/events_controller.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_spacing.dart';
import 'package:tasian/ui/widgets/calendar_selector.dart';
import 'package:tasian/ui/widgets/compact_dates.dart';
import 'package:tasian/ui/widgets/events_section.dart';
import 'package:tasian/ui/widgets/page_frame.dart';
import 'package:tasian/ui/widgets/section_header.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    required this.settings,
    required this.events,
    required this.today,
    super.key,
  });

  final AppSettings settings;
  final EventsController events;
  final TodayController today;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const double _swipeVelocity = 200;

  late CalendarKind _kind;
  late CalendarKind _lastMain;
  late MonthRef _month;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _kind = widget.settings.mainCalendar;
    _lastMain = _kind;
    _selected = widget.today.jdn;
    _month = CalendarMath.monthOf(_kind, _selected);
    widget.settings.addListener(_onSettings);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    final main = widget.settings.mainCalendar;
    if (main == _lastMain) return;
    _lastMain = main;
    setState(() {
      _kind = main;
      _month = CalendarMath.monthOf(main, _selected);
    });
  }

  void _setKind(CalendarKind kind) {
    setState(() {
      _kind = kind;
      _month = CalendarMath.monthOf(kind, _selected);
    });
  }

  void _step(int delta) {
    final next = CalendarMath.shift(_month, delta);
    if (next != null) setState(() => _month = next);
  }

  void _goToday() {
    setState(() {
      _selected = widget.today.jdn;
      _month = CalendarMath.monthOf(_kind, _selected);
    });
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -_swipeVelocity) {
      _step(1);
    } else if (velocity > _swipeVelocity) {
      _step(-1);
    }
  }

  CalendarKind? _secondaryKind() {
    for (final kind in widget.settings.shownCalendars) {
      if (!kind.sharesDaysWith(_kind)) return kind;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return ListenableBuilder(
      listenable: Listenable.merge([settings, widget.events, widget.today]),
      builder: (context, _) {
        final persian = settings.persianDigits;
        final weekStart = settings.weekStartFor(_kind);
        final secondary = _secondaryKind();
        final range = secondary == null
            ? ''
            : DateFormatter.monthRange(_month, secondary, persian: persian);
        return PageFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                CalendarSelector(selected: _kind, onSelected: _setKind),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragEnd: _onSwipe,
                      child: Column(
                        spacing: AppSpacing.xxs,
                        children: [
                          _MonthHeader(
                            title: DateFormatter.monthTitle(
                              _month,
                              persian: persian,
                            ),
                            subtitle: range,
                            onPrevious: CalendarMath.shift(_month, -1) == null
                                ? null
                                : () => _step(-1),
                            onNext: CalendarMath.shift(_month, 1) == null
                                ? null
                                : () => _step(1),
                            onToday: _goToday,
                          ),
                          _WeekdayRow(kind: _kind, weekStart: weekStart),
                          _MonthGrid(
                            cells: CalendarMath.cells(_month, weekStart),
                            kind: _kind,
                            secondary: secondary,
                            persian: persian,
                            today: widget.today.jdn,
                            selected: _selected,
                            events: widget.events,
                            onSelected: (jdn) =>
                                setState(() => _selected = jdn),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SectionHeader(title: 'Selected day'),
                CompactDates(jdn: _selected, settings: settings),
                EventsSection(
                  jdn: _selected,
                  settings: settings,
                  events: widget.events,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.subtitle,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month'.tr,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: onPrevious,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Next month'.tr,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: onNext,
        ),
        IconButton(
          tooltip: 'Go to today'.tr,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.today_rounded),
          onPressed: onToday,
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.kind, required this.weekStart});

  final CalendarKind kind;
  final int weekStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letters = kind.weekdayLetters;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Text(
                letters[(weekStart - 1 + i) % 7],
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.cells,
    required this.kind,
    required this.secondary,
    required this.persian,
    required this.today,
    required this.selected,
    required this.events,
    required this.onSelected,
  });

  final List<int?> cells;
  final CalendarKind kind;
  final CalendarKind? secondary;
  final bool persian;
  final int today;
  final int selected;
  final EventsController events;
  final ValueChanged<int> onSelected;

  static const double _cellAspect = 1;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: AppSpacing.xxs,
        crossAxisSpacing: AppSpacing.xxs,
        childAspectRatio: _cellAspect,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final jdn = cells[index];
        if (jdn == null) return const SizedBox.shrink();
        return _DayCell(
          jdn: jdn,
          kind: kind,
          secondary: secondary,
          persian: persian,
          isToday: jdn == today,
          isSelected: jdn == selected,
          hasEvents: events.hasEvents(jdn),
          onTap: () => onSelected(jdn),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.jdn,
    required this.kind,
    required this.secondary,
    required this.persian,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
    required this.onTap,
  });

  final int jdn;
  final CalendarKind kind;
  final CalendarKind? secondary;
  final bool persian;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;
  final VoidCallback onTap;

  static const double _dot = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = CalendarMath.tryDate(kind, jdn);
    final other = secondary;
    final otherDate = other == null ? null : CalendarMath.tryDate(other, jdn);
    final foreground = isSelected
        ? scheme.onPrimary
        : (isToday ? scheme.primary : scheme.onSurface);
    final muted = isSelected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final radius = BorderRadius.circular(AppRadius.tile);
    return Material(
      color: isSelected ? scheme.primary : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isToday && !isSelected
            ? BorderSide(color: scheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  date == null
                      ? ''
                      : DateFormatter.dayNumber(date, persian: persian),
                  style: theme.textTheme.labelLarge?.copyWith(color: foreground),
                ),
                if (otherDate != null && other != null)
                  Text(
                    DateFormatter.number(otherDate.day, other, persian: persian),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                if (hasEvents)
                  Container(
                    width: _dot,
                    height: _dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? scheme.onPrimary : scheme.tertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
