import 'package:flutter/material.dart' hide Text, Icon;
import 'package:flutter/services.dart';
import 'package:pcal/pcal.dart';
import 'package:tasian/calendar/today_controller.dart';
import 'package:tasian/core/calendar_kind.dart';
import 'package:tasian/core/calendar_math.dart';
import 'package:tasian/localization/date_names.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_spacing.dart';
import 'package:tasian/ui/widgets/calendar_selector.dart';
import 'package:tasian/ui/widgets/compact_dates.dart';
import 'package:tasian/ui/widgets/page_frame.dart';
import 'package:tasian/ui/widgets/section_header.dart';
import 'package:tasian/ui/widgets/settings_section.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({
    required this.settings,
    required this.today,
    super.key,
  });

  final AppSettings settings;
  final TodayController today;

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final _year = TextEditingController();
  final _day = TextEditingController();
  late CalendarKind _kind;
  var _month = 1;
  var _era = JapaneseEra.reiwa;
  var _epoch = 0;

  @override
  void initState() {
    super.initState();
    _kind = widget.settings.mainCalendar;
    _fill(widget.today.jdn);
  }

  @override
  void dispose() {
    _year.dispose();
    _day.dispose();
    super.dispose();
  }

  void _fill(int jdn) {
    final date = CalendarMath.tryDate(_kind, jdn);
    if (date == null) {
      _month = CalendarMath.monthNumbers(_kind).first;
      return;
    }
    _year.text = '${date.year}';
    _day.text = '${date.day}';
    _month = date.month;
    if (date is JapaneseDate) _era = date.era;
    _epoch++;
  }

  void _select(CalendarKind kind) {
    final jdn = _resolve().date?.julianDayNumber ?? widget.today.jdn;
    setState(() {
      _kind = kind;
      _fill(jdn);
    });
  }

  ({CalendarDate? date, String? error}) _resolve() {
    final year = int.tryParse(_year.text.trim());
    final day = int.tryParse(_day.text.trim());
    if (year == null || day == null) return (date: null, error: null);
    try {
      final CalendarDate date = switch (_kind) {
        CalendarKind.gregorian => GregorianDate(year, _month, day),
        CalendarKind.jalali => JalaliDate(year, _month, day),
        CalendarKind.deylami => DeylamiDate(year, _month, day),
        CalendarKind.japanese => JapaneseDate(_era, year, _month, day),
      };
      return (date: date, error: null);
    } on PcalException catch (error) {
      return (date: null, error: error.message);
    }
  }

  String _monthLabel(int month) => switch (_kind) {
        CalendarKind.gregorian => DateNames.month(L10n.code, month),
        CalendarKind.jalali => JalaliDate.monthNames[month - 1],
        CalendarKind.deylami => DeylamiDate.monthNames[month],
        CalendarKind.japanese => L10n.code == 'ja'
            ? JapaneseDate.monthNames[month - 1]
            : '${DateNames.month(L10n.code, month)} · ${JapaneseDate.monthNames[month - 1]}',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _resolve();
    final date = result.date;
    final error = result.error;
    return PageFrame(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: [
            SettingsSection(
              title: 'Convert from',
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.md,
                    children: [
                      CalendarSelector(selected: _kind, onSelected: _select),
                      if (_kind == CalendarKind.japanese)
                        DropdownMenu<JapaneseEra>(
                          key: ValueKey('era-$_epoch'),
                          initialSelection: _era,
                          expandedInsets: EdgeInsets.zero,
                          requestFocusOnTap: false,
                          label: const Text('Era'),
                          dropdownMenuEntries: [
                            for (final era in JapaneseEra.values)
                              DropdownMenuEntry(
                                value: era,
                                label: '${era.kanjiName} ${era.romajiName}',
                              ),
                          ],
                          onSelected: (era) {
                            if (era != null) setState(() => _era = era);
                          },
                        ),
                      Row(
                        spacing: AppSpacing.md,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _year,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: (_kind == CalendarKind.japanese
                                        ? 'Era year'
                                        : 'Year')
                                    .tr,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _day,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Day'.tr,
                              ),
                            ),
                          ),
                        ],
                      ),
                      DropdownMenu<int>(
                        key: ValueKey('month-$_kind-$_epoch'),
                        initialSelection: _month,
                        expandedInsets: EdgeInsets.zero,
                        requestFocusOnTap: false,
                        label: const Text('Month'),
                        dropdownMenuEntries: [
                          for (final month in CalendarMath.monthNumbers(_kind))
                            DropdownMenuEntry(
                              value: month,
                              label: _monthLabel(month),
                            ),
                        ],
                        onSelected: (month) {
                          if (month != null) setState(() => _month = month);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (date != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.sm,
                children: [
                  const SectionHeader(title: 'Result'),
                  CompactDates(
                    jdn: date.julianDayNumber,
                    settings: widget.settings,
                    skip: _kind,
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  error ?? 'Enter a year and a day.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
