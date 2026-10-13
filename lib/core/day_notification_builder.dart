import 'package:tasian/core/calendar_kind.dart';
import 'package:tasian/core/calendar_math.dart';
import 'package:tasian/core/date_format.dart';
import 'package:tasian/events/event_item.dart';
import 'package:tasian/localization/localization.dart';

typedef DayNotificationEntry = ({
  String date,
  String title,
  String body,
  String badge,
});

abstract class DayNotificationBuilder {
  static const int days = 120;
  static const int _maxEventLines = 4;

  static List<DayNotificationEntry> build({
    required int fromJdn,
    required CalendarKind main,
    required List<CalendarKind> extras,
    required bool persian,
    required List<EventItem> Function(int jdn) eventsOn,
  }) {
    final entries = <DayNotificationEntry>[];
    for (var i = 0; i < days; i++) {
      final jdn = fromJdn + i;
      final mainDate = CalendarMath.tryDate(main, jdn);
      final gregorian = CalendarMath.tryDate(CalendarKind.gregorian, jdn);
      if (mainDate == null || gregorian == null) break;

      final lines = <String>[];
      for (final kind in extras) {
        final date = CalendarMath.tryDate(kind, jdn);
        if (date == null) continue;
        lines.add(DateFormatter.full(date, persian: persian));
      }
      lines.addAll(_eventLines(eventsOn(jdn)));

      entries.add((
        date: gregorian.toString(),
        title: DateFormatter.full(mainDate, persian: persian),
        body: lines.join('\n'),
        badge: DateFormatter.dayNumber(mainDate, persian: persian),
      ));
    }
    return entries;
  }

  static List<String> _eventLines(List<EventItem> items) {
    final lines = <String>[];
    for (final item in items.take(_maxEventLines)) {
      final minute = item.minute;
      lines.add(
        minute == null
            ? '• ${item.title}'
            : '• ${DateFormatter.time(minute)}  ${item.title}',
      );
    }
    if (items.length > _maxEventLines) {
      lines.add('+${items.length - _maxEventLines} more'.tr);
    }
    return lines;
  }
}
