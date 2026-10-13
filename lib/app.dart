import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tasian/app_info.dart';
import 'package:tasian/calendar/today_controller.dart';
import 'package:tasian/events/events_controller.dart';
import 'package:tasian/localization/localization.dart';
import 'package:tasian/settings/app_settings.dart';
import 'package:tasian/theme/app_theme.dart';
import 'package:tasian/ui/app_shell.dart';

class TasianApp extends StatelessWidget {
  const TasianApp({
    required this.settings,
    required this.events,
    required this.today,
    super.key,
  });

  final AppSettings settings;
  final EventsController events;
  final TodayController today;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppInfo.name.tr,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          scrollBehavior: const _NoScrollbarBehavior(),
          locale: L10n.locale,
          supportedLocales: [
            for (final language in L10n.languages) Locale(language.code),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: KeyedSubtree(
            key: ValueKey(L10n.code),
            child: AppShell(settings: settings, events: events, today: today),
          ),
        );
      },
    );
  }
}

class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
