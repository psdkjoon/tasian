import 'package:flutter/material.dart' hide Text, Icon;
import 'package:tasian/events/events_controller.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_spacing.dart';
import 'package:tasian/ui/event_sheet.dart';
import 'package:tasian/ui/widgets/event_tile.dart';
import 'package:tasian/ui/widgets/section_header.dart';
import 'package:tasian/ui/widgets/surface_card.dart';

class EventsSection extends StatelessWidget {
  const EventsSection({
    required this.jdn,
    required this.settings,
    required this.events,
    this.title = 'Events',
    super.key,
  });

  final int jdn;
  final AppSettings settings;
  final EventsController events;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: events,
      builder: (context, _) {
        final items = events.forDay(jdn);
        void add() => showEventSheet(
              context,
              settings: settings,
              events: events,
              jdn: jdn,
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            SectionHeader(
              title: title,
              trailing: IconButton.filledTonal(
                tooltip: 'Add event'.tr,
                icon: const Icon(Icons.add_rounded),
                onPressed: add,
              ),
            ),
            if (items.isEmpty)
              SurfaceCard(
                onTap: add,
                child: Row(
                  spacing: AppSpacing.md,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Text(
                        'Nothing planned. Tap to add an event.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final item in items)
                EventTile(
                  item: item,
                  onTap: () => showEventSheet(
                    context,
                    settings: settings,
                    events: events,
                    jdn: jdn,
                    existing: item,
                  ),
                ),
          ],
        );
      },
    );
  }
}
