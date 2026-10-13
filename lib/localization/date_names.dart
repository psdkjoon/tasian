abstract class DateNames {
  static const _months = <String, List<String>>{
    'en': [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ],
    'fa': [
      'ژانویه',
      'فوریه',
      'مارس',
      'آوریل',
      'مه',
      'ژوئن',
      'ژوئیه',
      'اوت',
      'سپتامبر',
      'اکتبر',
      'نوامبر',
      'دسامبر',
    ],
    'ru': [
      'январь',
      'февраль',
      'март',
      'апрель',
      'май',
      'июнь',
      'июль',
      'август',
      'сентябрь',
      'октябрь',
      'ноябрь',
      'декабрь',
    ],
    'ja': [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ],
  };

  static const _russianGenitive = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const _weekdays = <String, List<String>>{
    'en': [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ],
    'fa': [
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنج‌شنبه',
      'جمعه',
      'شنبه',
      'یکشنبه',
    ],
    'ru': [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье',
    ],
    'ja': [
      '月曜日',
      '火曜日',
      '水曜日',
      '木曜日',
      '金曜日',
      '土曜日',
      '日曜日',
    ],
  };

  static const _short = <String, List<String>>{
    'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'fa': ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'],
    'ru': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
    'ja': ['月', '火', '水', '木', '金', '土', '日'],
  };

  static List<String> weekdayLetters(String code) =>
      _short[code] ?? _short['en']!;

  static String month(String code, int month) =>
      (_months[code] ?? _months['en']!)[month - 1];

  static String monthInDate(String code, int month) =>
      code == 'ru' ? _russianGenitive[month - 1] : DateNames.month(code, month);

  static String weekday(String code, int weekday) =>
      (_weekdays[code] ?? _weekdays['en']!)[weekday - 1];
}
