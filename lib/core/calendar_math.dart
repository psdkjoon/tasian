import 'package:pcal/pcal.dart';
import 'package:tasian/core/calendar_kind.dart';

class MonthRef {
  const MonthRef(this.kind, this.year, this.month);

  final CalendarKind kind;
  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      other is MonthRef &&
      other.kind == kind &&
      other.year == year &&
      other.month == month;

  @override
  int get hashCode => Object.hash(kind, year, month);
}

abstract class CalendarMath {
  static const _plainMonths = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  static const _deylamiMonths = <int>[1, 2, 3, 4, 5, 6, 7, 8, 0, 9, 10, 11, 12];

  static List<int> monthNumbers(CalendarKind kind) =>
      kind == CalendarKind.deylami ? _deylamiMonths : _plainMonths;

  static CalendarDate? tryDate(CalendarKind kind, int jdn) {
    try {
      return kind.dateOf(jdn);
    } on PcalException {
      return null;
    }
  }

  static CalendarDate dateOrGregorian(CalendarKind kind, int jdn) =>
      tryDate(kind, jdn) ?? GregorianDate.fromJulianDayNumber(jdn);

  static MonthRef monthOf(CalendarKind kind, int jdn) {
    final clamped = jdn < kind.minJdn
        ? kind.minJdn
        : (jdn > kind.maxJdn ? kind.maxJdn : jdn);
    final date = kind.dateOf(clamped);
    if (kind == CalendarKind.japanese) {
      final gregorian = date.toGregorian();
      return MonthRef(kind, gregorian.year, gregorian.month);
    }
    return MonthRef(kind, date.year, date.month);
  }

  static int firstJdn(MonthRef ref) => switch (ref.kind) {
        CalendarKind.gregorian ||
        CalendarKind.japanese =>
          GregorianDate(ref.year, ref.month, 1).julianDayNumber,
        CalendarKind.jalali =>
          JalaliDate(ref.year, ref.month, 1).julianDayNumber,
        CalendarKind.deylami => DeylamiDate(
            ref.year,
            ref.month,
            ref.month == 0 && DeylamiDate.isLeap(ref.year) ? 0 : 1,
          ).julianDayNumber,
      };

  static int length(MonthRef ref) => switch (ref.kind) {
        CalendarKind.gregorian ||
        CalendarKind.japanese =>
          GregorianDate.daysInMonthOf(ref.year, ref.month),
        CalendarKind.jalali => JalaliDate.daysInMonthOf(ref.year, ref.month),
        CalendarKind.deylami =>
          DeylamiDate.daysInMonthOf(ref.year, ref.month),
      };

  static bool isValid(MonthRef ref) {
    try {
      final first = firstJdn(ref);
      final last = first + length(ref) - 1;
      return first >= ref.kind.minJdn && last <= ref.kind.maxJdn;
    } on PcalException {
      return false;
    }
  }

  static MonthRef? shift(MonthRef ref, int delta) {
    final months = monthNumbers(ref.kind);
    var index = months.indexOf(ref.month) + delta;
    var year = ref.year;
    while (index < 0) {
      index += months.length;
      year--;
    }
    while (index >= months.length) {
      index -= months.length;
      year++;
    }
    final next = MonthRef(ref.kind, year, months[index]);
    return isValid(next) ? next : null;
  }

  static List<int?> cells(MonthRef ref, int weekStart) {
    final first = firstJdn(ref);
    final lead = (first % 7 + 1 - weekStart + 7) % 7;
    return [
      for (var i = 0; i < lead; i++) null,
      for (var i = 0; i < length(ref); i++) first + i,
    ];
  }
}
