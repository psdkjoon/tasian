import 'package:flutter/material.dart';
import 'package:tasian/core/calendar_kind.dart';
import 'package:tasian/core/kv_store.dart';
import 'package:tasian/localization/localization.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs) {
    _themeMode = _byName(
      ThemeMode.values,
      _prefs.getString('themeMode'),
      _themeMode,
    );
    _language = _prefs.getString('language') ?? L10n.system;
    L10n.code = L10n.resolve(_language);
    _checkUpdates = _prefs.getBool('checkUpdates') ?? _checkUpdates;
    _mainCalendar = _byName(
      CalendarKind.values,
      _prefs.getString('mainCalendar'),
      _mainCalendar,
    );
    final order = _prefs.getStringList('calendarOrder');
    if (order != null) {
      final saved = [
        for (final name in order)
          for (final kind in CalendarKind.values)
            if (kind.name == name) kind,
      ];
      _order = [
        ...saved,
        for (final kind in CalendarKind.values)
          if (!saved.contains(kind)) kind,
      ];
    }
    final extras = _prefs.getStringList('extraCalendars');
    if (extras != null) {
      _extras = {
        for (final kind in CalendarKind.values)
          if (extras.contains(kind.name)) kind,
      };
    }
    _dayNotification = _prefs.getBool('dayNotification') ?? _dayNotification;
    _weekStart = _prefs.getInt('weekStart') ?? _weekStart;
    _persianDigits = _prefs.getBool('persianDigits') ?? _persianDigits;
    _timelessMinute = _prefs.getInt('timelessMinute') ?? _timelessMinute;
  }

  static AppSettings load(KvStore store) => AppSettings._(store);

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  final KvStore _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  String _language = L10n.system;
  bool _checkUpdates = true;
  CalendarKind _mainCalendar = CalendarKind.gregorian;
  Set<CalendarKind> _extras = {...CalendarKind.values};
  List<CalendarKind> _order = [...CalendarKind.values];
  bool _dayNotification = false;
  int _weekStart = 0;
  bool _persianDigits = true;
  int _timelessMinute = 9 * 60;

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get checkUpdates => _checkUpdates;
  CalendarKind get mainCalendar => _mainCalendar;
  bool get dayNotification => _dayNotification;
  int get weekStart => _weekStart;
  bool get persianDigits => _persianDigits;
  int get timelessMinute => _timelessMinute;

  List<CalendarKind> get extraCalendars => [
        for (final kind in _order)
          if (kind != _mainCalendar && _extras.contains(kind)) kind,
      ];

  List<CalendarKind> get otherCalendars => [
        for (final kind in _order)
          if (kind != _mainCalendar && !_extras.contains(kind)) kind,
      ];

  List<CalendarKind> get shownCalendars => [_mainCalendar, ...extraCalendars];

  List<CalendarKind> get orderedCalendars =>
      [_mainCalendar, ...extraCalendars, ...otherCalendars];

  bool showsExtra(CalendarKind kind) => _extras.contains(kind);

  int weekStartFor(CalendarKind kind) {
    if (_weekStart != 0) return _weekStart;
    return switch (kind) {
      CalendarKind.gregorian => DateTime.monday,
      CalendarKind.jalali || CalendarKind.deylami => DateTime.saturday,
      CalendarKind.japanese => DateTime.sunday,
    };
  }

  set themeMode(ThemeMode value) =>
      _set(() => _themeMode = value, 'themeMode', value.name);

  set language(String value) {
    _language = value;
    L10n.code = L10n.resolve(value);
    _prefs.setString('language', value);
    notifyListeners();
  }

  set checkUpdates(bool value) =>
      _set(() => _checkUpdates = value, 'checkUpdates', value);

  set mainCalendar(CalendarKind value) =>
      _set(() => _mainCalendar = value, 'mainCalendar', value.name);

  set dayNotification(bool value) =>
      _set(() => _dayNotification = value, 'dayNotification', value);

  set weekStart(int value) =>
      _set(() => _weekStart = value, 'weekStart', value);

  set persianDigits(bool value) =>
      _set(() => _persianDigits = value, 'persianDigits', value);

  set timelessMinute(int value) =>
      _set(() => _timelessMinute = value, 'timelessMinute', value);

  void setExtra(CalendarKind kind, {required bool shown}) {
    if (shown) {
      _extras.add(kind);
      _order
        ..remove(kind)
        ..add(kind);
    } else {
      _extras.remove(kind);
    }
    _saveCalendars();
  }

  void moveExtra(CalendarKind kind, int delta) {
    final extras = extraCalendars;
    final from = extras.indexOf(kind);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= extras.length) return;
    final a = _order.indexOf(extras[from]);
    final b = _order.indexOf(extras[to]);
    final moved = _order[a];
    _order[a] = _order[b];
    _order[b] = moved;
    _saveCalendars();
  }

  void _saveCalendars() {
    _prefs.setStringList('calendarOrder', [for (final k in _order) k.name]);
    _prefs.setStringList('extraCalendars', [
      for (final k in _order)
        if (_extras.contains(k)) k.name,
    ]);
    notifyListeners();
  }

  void _set(VoidCallback change, String key, Object value) {
    change();
    switch (value) {
      case final bool v:
        _prefs.setBool(key, v);
      case final int v:
        _prefs.setInt(key, v);
      case final String v:
        _prefs.setString(key, v);
    }
    notifyListeners();
  }
}
