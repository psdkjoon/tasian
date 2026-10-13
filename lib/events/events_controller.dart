import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tasian/core/kv_store.dart';
import 'package:tasian/events/event_item.dart';

class EventsController extends ChangeNotifier {
  EventsController._(this._store, List<EventItem> items) {
    _items = items;
    _rebuild();
  }

  static EventsController load(KvStore store) {
    final items = <EventItem>[];
    final raw = store.getString('events');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final entry in decoded) {
            final item = EventItem.fromJson(entry);
            if (item != null) items.add(item);
          }
        }
      } on Object {
        items.clear();
      }
    }
    return EventsController._(store, items);
  }

  final KvStore _store;

  var _items = <EventItem>[];
  var _byDay = <int, List<EventItem>>{};

  List<EventItem> get all => List.unmodifiable(_items);

  List<EventItem> forDay(int jdn) => _byDay[jdn] ?? const <EventItem>[];

  bool hasEvents(int jdn) => _byDay.containsKey(jdn);

  List<EventItem> upcoming(int fromJdn, {int limit = 5}) {
    final found = <EventItem>[];
    for (final item in _items) {
      if (item.jdn < fromJdn) continue;
      found.add(item);
      if (found.length == limit) break;
    }
    return found;
  }

  int nextId() {
    var id = DateTime.now().microsecondsSinceEpoch;
    while (_items.any((item) => item.id == id)) {
      id++;
    }
    return id;
  }

  void save(EventItem item) {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index < 0) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
    _commit();
  }

  void remove(int id) {
    _items.removeWhere((item) => item.id == id);
    _commit();
  }

  void _commit() {
    _rebuild();
    _store.setString(
      'events',
      jsonEncode([for (final item in _items) item.toJson()]),
    );
    notifyListeners();
  }

  void _rebuild() {
    _items.sort((a, b) => a.compareTo(b));
    final byDay = <int, List<EventItem>>{};
    for (final item in _items) {
      byDay.putIfAbsent(item.jdn, () => <EventItem>[]).add(item);
    }
    _byDay = byDay;
  }
}
