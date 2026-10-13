import 'package:flutter/material.dart' hide Text, Icon;
import 'package:tasian/localization/localization.dart';
import 'package:flutter/services.dart';
import 'package:tasian/app_info.dart';
import 'package:tasian/calendar/today_controller.dart';
import 'package:tasian/events/events_controller.dart';
import 'package:tasian/platform/notification_service.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_spacing.dart';
import 'package:tasian/ui/about_screen.dart';
import 'package:tasian/ui/calendar_screen.dart';
import 'package:tasian/ui/convert_screen.dart';
import 'package:tasian/ui/home_screen.dart';
import 'package:tasian/ui/settings_screen.dart';
import 'package:tasian/ui/update_prompt.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.settings,
    required this.events,
    required this.today,
    super.key,
  });

  final AppSettings settings;
  final EventsController events;
  final TodayController today;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _sidebarBreakpoint = 800;
  static const _destinations = [
    _Destination('Today', Icons.today_outlined, Icons.today_rounded),
    _Destination(
      'Calendar',
      Icons.calendar_month_outlined,
      Icons.calendar_month_rounded,
    ),
    _Destination('Convert', Icons.swap_horiz_rounded, Icons.swap_horiz_rounded),
    _Destination('Settings', Icons.tune_rounded, Icons.tune_rounded),
    _Destination('About', Icons.info_outline_rounded, Icons.info_rounded),
  ];

  static var _lastIndex = 0;

  var _index = _lastIndex;

  @override
  void initState() {
    super.initState();
    if (AppInfo.usesNotifications) NotificationService.requestPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdatePrompt.run(context, widget.settings);
    });
  }

  void _select(int index) => setState(() => _index = _lastIndex = index);

  @override
  Widget build(BuildContext context) {
    final page = SafeArea(
      child: switch (_index) {
        0 => HomeScreen(
            settings: widget.settings,
            events: widget.events,
            today: widget.today,
          ),
        1 => CalendarScreen(
            settings: widget.settings,
            events: widget.events,
            today: widget.today,
          ),
        2 => ConvertScreen(settings: widget.settings, today: widget.today),
        3 => SettingsScreen(settings: widget.settings),
        _ => const AboutScreen(),
      },
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: theme.colorScheme.surfaceContainerLow,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    final Widget scaffold;
    if (MediaQuery.sizeOf(context).width >= _sidebarBreakpoint) {
      scaffold = Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              destinations: _destinations,
              selectedIndex: _index,
              onSelected: _select,
            ),
            Expanded(child: page),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
        body: page,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label.tr,
              ),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: scaffold,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _width = 11 * AppSpacing.spaceUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: _width,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      AppInfo.name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                for (var i = 0; i < destinations.length; i++)
                  ListTile(
                    selected: i == selectedIndex,
                    leading: Icon(
                      i == selectedIndex
                          ? destinations[i].selectedIcon
                          : destinations[i].icon,
                    ),
                    title: Text(destinations[i].label),
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
