import 'package:pcal/pcal.dart';
import 'package:tasian/localization/date_names.dart';
import 'package:tasian/localization/localization.dart';

enum CalendarKind {
  gregorian('Gregorian', 'Gregorian', 'G'),
  jalali('Jalali', 'جلالی', 'ج'),
  deylami('Deylami', 'دیلمی', 'د'),
  japanese('Japanese', '和暦', '和');

  const CalendarKind(this.title, this.nativeTitle, this.glyph);

  final String title;
  final String nativeTitle;
  final String glyph;

  bool get persianScript =>
      this == CalendarKind.jalali || this == CalendarKind.deylami;

  bool sharesDaysWith(CalendarKind other) =>
      this == other ||
      (this == CalendarKind.gregorian && other == CalendarKind.japanese) ||
      (this == CalendarKind.japanese && other == CalendarKind.gregorian);

  int get minJdn => switch (this) {
        CalendarKind.gregorian => GregorianDate.minJulianDayNumber,
        CalendarKind.jalali => JalaliDate.minJulianDayNumber,
        CalendarKind.deylami => DeylamiDate.minJulianDayNumber,
        CalendarKind.japanese => JapaneseDate.minJulianDayNumber,
      };

  int get maxJdn => switch (this) {
        CalendarKind.gregorian => GregorianDate.maxJulianDayNumber,
        CalendarKind.jalali => JalaliDate.maxJulianDayNumber,
        CalendarKind.deylami => DeylamiDate.maxJulianDayNumber,
        CalendarKind.japanese => JapaneseDate.maxJulianDayNumber,
      };

  CalendarDate dateOf(int jdn) => switch (this) {
        CalendarKind.gregorian => GregorianDate.fromJulianDayNumber(jdn),
        CalendarKind.jalali => JalaliDate.fromJulianDayNumber(jdn),
        CalendarKind.deylami => DeylamiDate.fromJulianDayNumber(jdn),
        CalendarKind.japanese => JapaneseDate.fromJulianDayNumber(jdn),
      };

  List<String> get weekdayLetters => switch (this) {
        CalendarKind.gregorian => DateNames.weekdayLetters(L10n.code),
        CalendarKind.jalali ||
        CalendarKind.deylami =>
          const ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'],
        CalendarKind.japanese => const ['月', '火', '水', '木', '金', '土', '日'],
      };
}
