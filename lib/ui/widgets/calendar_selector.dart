import 'package:flutter/material.dart' hide Text, Icon;
import 'package:tasian/core/calendar_kind.dart';
import 'package:tasian/localization/localization.dart';

class CalendarSelector extends StatelessWidget {
  const CalendarSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final CalendarKind selected;
  final ValueChanged<CalendarKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CalendarKind>(
      expandedInsets: EdgeInsets.zero,
      showSelectedIcon: false,
      segments: [
        for (final kind in CalendarKind.values)
          ButtonSegment(
            value: kind,
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(kind.title)),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}
