import 'package:flutter/material.dart' hide Text, Icon;
import 'package:tasian/core/calendar_kind.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_spacing.dart';

class CalendarOrderList extends StatelessWidget {
  const CalendarOrderList({required this.settings, super.key});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final extras = settings.extraCalendars;
    return Column(
      spacing: AppSpacing.xxs,
      children: [
        for (var i = 0; i < extras.length; i++)
          _OrderRow(
            kind: extras[i],
            rank: i + 1,
            canMoveUp: i > 0,
            canMoveDown: i < extras.length - 1,
            settings: settings,
          ),
        for (final kind in settings.otherCalendars)
          _OrderRow(
            kind: kind,
            rank: null,
            canMoveUp: false,
            canMoveDown: false,
            settings: settings,
          ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.kind,
    required this.rank,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.settings,
  });

  final CalendarKind kind;
  final int? rank;
  final bool canMoveUp;
  final bool canMoveDown;
  final AppSettings settings;

  static const double _rankSize = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final position = rank;
    return Row(
      spacing: AppSpacing.sm,
      children: [
        Container(
          width: _rankSize,
          height: _rankSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: position == null
                ? scheme.surfaceContainerHighest
                : scheme.primary,
          ),
          child: Text(
            position == null ? '–' : '$position',
            style: theme.textTheme.labelMedium?.copyWith(
              color:
                  position == null ? scheme.onSurfaceVariant : scheme.onPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            kind.title,
            style: theme.textTheme.labelLarge?.copyWith(
              color:
                  position == null ? scheme.onSurfaceVariant : scheme.onSurface,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Move up'.tr,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          onPressed: canMoveUp ? () => settings.moveExtra(kind, -1) : null,
        ),
        IconButton(
          tooltip: 'Move down'.tr,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: canMoveDown ? () => settings.moveExtra(kind, 1) : null,
        ),
        Switch(
          value: position != null,
          onChanged: (shown) => settings.setExtra(kind, shown: shown),
        ),
      ],
    );
  }
}
