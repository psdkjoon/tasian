import 'package:flutter/material.dart' hide Text, Icon;
import 'package:tasian/core/date_format.dart';
import 'package:tasian/events/event_item.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/theme/app_spacing.dart';
import 'package:tasian/ui/widgets/surface_card.dart';

class EventTile extends StatelessWidget {
  const EventTile({
    required this.item,
    required this.onTap,
    this.caption,
    super.key,
  });

  final EventItem item;
  final VoidCallback onTap;
  final String? caption;

  static const double _timeWidth = 52;
  static const double _barWidth = 3;
  static const double _barHeight = 36;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final minute = item.minute;
    final label = caption;
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        spacing: AppSpacing.md,
        children: [
          SizedBox(
            width: _timeWidth,
            child: Text(
              minute == null ? 'All day' : DateFormatter.time(minute),
              textAlign: TextAlign.center,
              style: (minute == null
                      ? theme.textTheme.labelMedium
                      : theme.textTheme.labelLarge)
                  ?.copyWith(
                color: minute == null ? scheme.onSurfaceVariant : scheme.primary,
              ),
            ),
          ),
          Container(
            width: _barWidth,
            height: _barHeight,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                if (label != null)
                  Text(
                    label,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.primary),
                  ),
                Text(item.title, style: theme.textTheme.titleMedium),
                if (item.note.isNotEmpty)
                  Text(
                    item.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (item.reminderLead != null)
            Icon(
              Icons.notifications_active_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}
