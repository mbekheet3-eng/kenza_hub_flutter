import 'package:material_ui/material_ui.dart';

import 'config/app_locale.dart';
import 'config/app_theme.dart';
import 'l10n/app_strings.dart';
import 'l10n/kenza_localizations.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

class KenzaHubApp extends StatelessWidget {
  const KenzaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocale.notifier,
      builder: (context, locale, _) => MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'Kenza',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        locale: locale,
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: KenzaLocalizations.delegates,
        home: const KenzaSplashScreen(),
      ),
    );
  }
}
