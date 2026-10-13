import 'dart:async';

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:pcal/pcal.dart';
import 'package:tasian/core/date_format.dart';
import 'package:tasian/events/event_item.dart';
import 'package:tasian/events/events_controller.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/platform/notification_service.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_spacing.dart';

Future<void> showEventSheet(
  BuildContext context, {
  required AppSettings settings,
  required EventsController events,
  required int jdn,
  EventItem? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _EventSheet(
      settings: settings,
      events: events,
      jdn: jdn,
      existing: existing,
    ),
  );
}

class _EventSheet extends StatefulWidget {
  const _EventSheet({
    required this.settings,
    required this.events,
    required this.jdn,
    required this.existing,
  });

  final AppSettings settings;
  final EventsController events;
  final int jdn;
  final EventItem? existing;

  @override
  State<_EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<_EventSheet> {
  static const double _maxWidth = 520;
  static const int _defaultMinute = 9 * 60;

  final _title = TextEditingController();
  final _note = TextEditingController();
  var _jdn = 0;
  int? _minute;
  int? _lead = 0;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _jdn = widget.jdn;
    if (existing != null) {
      _title.text = existing.title;
      _note.text = existing.note;
      _jdn = existing.jdn;
      _minute = existing.minute;
      _lead = existing.reminderLead;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  List<int> get _allowedLeads =>
      _minute == null ? EventItem.timelessLeads : EventItem.timedLeads;

  List<(int?, String)> get _reminderOptions {
    if (_minute != null) {
      return [
        (null, 'No reminder'),
        (0, 'At the time'),
        (5, '5 minutes before'),
        (15, '15 minutes before'),
        (30, '30 minutes before'),
        (60, '1 hour before'),
        (1440, '1 day before'),
      ];
    }
    final time = DateFormatter.time(widget.settings.timelessMinute);
    return [
      (null, 'No reminder'),
      (0, 'On the day, $time'),
      (1440, 'The day before, $time'),
    ];
  }

  void _setTimed(bool timed) {
    setState(() {
      if (timed) {
        final next = (DateTime.now().hour + 1) % 24 * 60;
        _minute = _minute ?? next;
      } else {
        _minute = null;
      }
      final lead = _lead;
      if (lead != null && !_allowedLeads.contains(lead)) _lead = 0;
    });
  }

  Future<void> _pickDate() async {
    final current = GregorianDate.fromJulianDayNumber(_jdn);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked == null || !mounted) return;
    setState(() => _jdn = GregorianDate.fromDateTime(picked).julianDayNumber);
  }

  Future<void> _pickTime() async {
    final current = _minute ?? _defaultMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null || !mounted) return;
    setState(() => _minute = picked.hour * 60 + picked.minute);
  }

  void _save() {
    final existing = widget.existing;
    widget.events.save(
      EventItem(
        id: existing?.id ?? widget.events.nextId(),
        title: _title.text.trim(),
        note: _note.text.trim(),
        jdn: _jdn,
        minute: _minute,
        reminderLead: _lead,
      ),
    );
    if (_lead != null) unawaited(NotificationService.requestPermission());
    Navigator.of(context).pop();
  }

  void _delete() {
    final existing = widget.existing;
    if (existing == null) return;
    widget.events.remove(existing.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settings;
    final minute = _minute;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(
                  widget.existing == null ? 'New event' : 'Edit event',
                  style: theme.textTheme.titleLarge,
                ),
                TextField(
                  controller: _title,
                  autofocus: widget.existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: 'Title'.tr),
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.event_rounded),
                        title: Text(
                          DateFormatter.fullOn(
                            settings.mainCalendar,
                            _jdn,
                            persian: settings.persianDigits,
                          ),
                        ),
                        subtitle: const Text('Tap to change the date'),
                        onTap: _pickDate,
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.schedule_rounded),
                        title: const Text('Set a time'),
                        subtitle: const Text('Without a time it is an all-day event'),
                        value: minute != null,
                        onChanged: _setTimed,
                      ),
                      if (minute != null)
                        ListTile(
                          leading: const Icon(Icons.access_time_rounded),
                          title: Text(DateFormatter.time(minute)),
                          subtitle: const Text('Tap to change the time'),
                          onTap: _pickTime,
                        ),
                    ],
                  ),
                ),
                Text('Remind me', style: theme.textTheme.labelLarge),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in _reminderOptions)
                      ChoiceChip(
                        label: Text(option.$2),
                        showCheckmark: false,
                        selected: _lead == option.$1,
                        onSelected: (_) => setState(() => _lead = option.$1),
                      ),
                  ],
                ),
                TextField(
                  controller: _note,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: 'Note (optional)'.tr),
                ),
                Row(
                  spacing: AppSpacing.md,
                  children: [
                    if (widget.existing != null)
                      TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: _title,
                      builder: (context, _) => FilledButton(
                        onPressed: _title.text.trim().isEmpty ? null : _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
