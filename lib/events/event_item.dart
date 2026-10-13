import 'package:pcal/pcal.dart';

class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.jdn,
    this.minute,
    this.note = '',
    this.reminderLead,
  });

  final int id;
  final String title;
  final String note;
  final int jdn;
  final int? minute;
  final int? reminderLead;

  static const timedLeads = <int>[0, 5, 15, 30, 60, 1440];
  static const timelessLeads = <int>[0, 1440];

  bool get timed => minute != null;

  DateTime startsAt(int timelessMinute) {
    final date = GregorianDate.fromJulianDayNumber(jdn);
    final at = minute ?? timelessMinute;
    return DateTime(date.year, date.month, date.day, at ~/ 60, at % 60);
  }

  DateTime? remindAt(int timelessMinute) {
    final lead = reminderLead;
    if (lead == null) return null;
    return startsAt(timelessMinute).subtract(Duration(minutes: lead));
  }

  int compareTo(EventItem other) {
    final byDay = jdn.compareTo(other.jdn);
    if (byDay != 0) return byDay;
    final byTime = (minute ?? -1).compareTo(other.minute ?? -1);
    if (byTime != 0) return byTime;
    return id.compareTo(other.id);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'day': jdn,
        if (minute != null) 'minute': minute,
        if (reminderLead != null) 'lead': reminderLead,
      };

  static EventItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title'];
    final day = json['day'];
    if (id is! int || title is! String || day is! int) return null;
    final note = json['note'];
    final minute = json['minute'];
    final lead = json['lead'];
    return EventItem(
      id: id,
      title: title,
      jdn: day,
      note: note is String ? note : '',
      minute: minute is int ? minute : null,
      reminderLead: lead is int ? lead : null,
    );
  }
}
