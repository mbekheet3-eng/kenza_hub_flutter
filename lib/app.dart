import 'package:flutter/material.dart';

import 'config/app_locale.dart';
import 'config/app_theme.dart';
import 'l10n/app_strings.dart';
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
        title: 'كنزة هب',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        locale: locale,
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: AppStrings.localizationsDelegates,
        home: const KenzaSplashScreen(),
      ),
    );
  }
}
