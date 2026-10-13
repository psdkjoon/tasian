import 'package:flutter/material.dart' hide Text, Icon;
import 'package:tasian/localization/localization.dart';
import 'package:tasian/theme/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
            child: Text(
              title,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
