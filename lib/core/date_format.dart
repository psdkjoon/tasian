import 'package:pcal/pcal.dart';
import 'package:tasian/core/calendar_kind.dart';
import 'package:tasian/core/calendar_math.dart';
import 'package:tasian/localization/date_names.dart';
import 'package:tasian/localization/localization.dart';

abstract class DateFormatter {
  static const _persianDigits = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  static CalendarKind kindOf(CalendarDate date) => switch (date) {
        JalaliDate() => CalendarKind.jalali,
        DeylamiDate() => CalendarKind.deylami,
        JapaneseDate() => CalendarKind.japanese,
        _ => CalendarKind.gregorian,
      };

  static String digits(
    String text,
    CalendarKind kind, {
    required bool persian,
  }) {
    if (!persian || !(kind.persianScript || L10n.code == 'fa')) return text;
    final buffer = StringBuffer();
    for (final unit in text.codeUnits) {
      if (unit >= 0x30 && unit <= 0x39) {
        buffer.write(_persianDigits[unit - 0x30]);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  static String number(int value, CalendarKind kind, {required bool persian}) =>
      digits('$value', kind, persian: persian);

  static String dayNumber(CalendarDate date, {required bool persian}) =>
      number(date.day, kindOf(date), persian: persian);

  static String weekday(CalendarDate date) => date is GregorianDate
      ? DateNames.weekday(L10n.code, date.weekday)
      : date.weekdayName;

  static String monthName(CalendarDate date) => date is GregorianDate
      ? DateNames.month(L10n.code, date.month)
      : date.monthName;

  static String full(CalendarDate date, {required bool persian}) {
    if (date is JapaneseDate) {
      return '${date.toKanjiString()} ${date.weekdayName}';
    }
    final kind = kindOf(date);
    final code = L10n.code;
    if (code == 'ja' && date is GregorianDate) {
      return '${date.year}年${date.month}月${date.day}日 ${weekday(date)}';
    }
    final day = number(date.day, kind, persian: persian);
    final year = number(date.year, kind, persian: persian);
    final comma = kind.persianScript || code == 'fa' ? '،' : ',';
    final month = date is GregorianDate
        ? DateNames.monthInDate(code, date.month)
        : date.monthName;
    return '${weekday(date)}$comma $day $month $year';
  }

  static String fullOn(CalendarKind kind, int jdn, {required bool persian}) =>
      full(CalendarMath.dateOrGregorian(kind, jdn), persian: persian);

  static String monthYear(CalendarDate date, {required bool persian}) {
    if (date is JapaneseDate) {
      final year = date.year == 1 ? '元' : '${date.year}';
      return '${date.era.kanjiName}$year年${date.month}月';
    }
    if (date is GregorianDate && L10n.code == 'ja') {
      return '${date.year}年${date.month}月';
    }
    final year = number(date.year, kindOf(date), persian: persian);
    final month = monthName(date);
    final shown = date is GregorianDate && L10n.code == 'ru'
        ? '${month[0].toUpperCase()}${month.substring(1)}'
        : month;
    return '$shown $year';
  }

  static String monthTitle(MonthRef ref, {required bool persian}) =>
      monthYear(ref.kind.dateOf(CalendarMath.firstJdn(ref)), persian: persian);

  static String monthRange(
    MonthRef ref,
    CalendarKind other, {
    required bool persian,
  }) {
    final first = CalendarMath.firstJdn(ref);
    final start = CalendarMath.tryDate(other, first);
    final end = CalendarMath.tryDate(other, first + CalendarMath.length(ref) - 1);
    if (start == null || end == null) return '';
    final from = monthYear(start, persian: persian);
    final to = monthYear(end, persian: persian);
    return from == to ? from : '$from – $to';
  }

  static String numeric(CalendarDate date, {required bool persian}) {
    if (date is JapaneseDate) {
      return '${date.era.abbreviation}${date.year}.${date.month}.${date.day}';
    }
    return digits(date.toString(), kindOf(date), persian: persian);
  }

  static String time(int minuteOfDay) {
    final hours = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final minutes = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  static String relativeDay(int days) => switch (days) {
        0 => 'Today',
        1 => 'Tomorrow',
        -1 => 'Yesterday',
        > 1 => 'In $days days',
        _ => '${-days} days ago',
      };
}
