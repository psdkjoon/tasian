import 'dart:async';

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:flutter/services.dart';
import 'package:tasian/core/calendar_kind.dart';
import 'package:tasian/core/calendar_math.dart';
import 'package:tasian/core/date_format.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_spacing.dart';
import 'package:tasian/ui/widgets/surface_card.dart';

class CompactDates extends StatelessWidget {
  const CompactDates({
    required this.jdn,
    required this.settings,
    this.skip,
    super.key,
  });

  final int jdn;
  final AppSettings settings;
  final CalendarKind? skip;

  @override
  Widget build(BuildContext context) {
    final kinds = [
      for (final kind in settings.orderedCalendars)
        if (kind != skip) kind,
    ];
    final scheme = Theme.of(context).colorScheme;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < kinds.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: AppSpacing.md, color: scheme.outlineVariant),
            _Row(
              kind: kinds[i],
              jdn: jdn,
              persian: settings.persianDigits,
              main: kinds[i] == settings.mainCalendar,
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.kind,
    required this.jdn,
    required this.persian,
    required this.main,
  });

  final CalendarKind kind;
  final int jdn;
  final bool persian;
  final bool main;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = CalendarMath.tryDate(kind, jdn);
    final text = date == null
        ? 'Outside the supported range'
        : DateFormatter.full(date, persian: persian);
    return InkWell(
      onTap: date == null ? null : () => _copy(context, text),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            SizedBox(
              width: 20,
              child: Text(
                kind.glyph,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: main ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: (main ? theme.textTheme.labelLarge : theme.textTheme.bodyMedium)
                    ?.copyWith(
                  color: date == null ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
