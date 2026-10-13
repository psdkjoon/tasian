import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pcal/pcal.dart';

class TodayController extends ChangeNotifier with WidgetsBindingObserver {
  TodayController() : _today = GregorianDate.now() {
    WidgetsBinding.instance.addObserver(this);
    _arm();
  }

  GregorianDate _today;
  Timer? _timer;

  GregorianDate get today => _today;

  int get jdn => _today.julianDayNumber;

  void _arm() {
    _timer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(
      midnight.difference(now) + const Duration(seconds: 1),
      _refresh,
    );
  }

  void _refresh() {
    final now = GregorianDate.now();
    if (now != _today) {
      _today = now;
      notifyListeners();
    }
    _arm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
