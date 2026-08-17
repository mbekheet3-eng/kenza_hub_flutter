import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:kenza_hub_flutter/screens/welcome/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocalizations.localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          locale: locale,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return supportedLocales.firstWhere(
              (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
              orElse: () => const Locale('ar'),
            );
          },
          title: 'كنزة هب',
          debugShowCheckedModeBanner: false,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          theme: ThemeData(
            fontFamily: 'Cairo',
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC62828),
              secondary: Color(0xFF0F172A),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const WelcomeScreen(),
            '/signup': (context) => const Scaffold(
              body: Center(
                child: Text('إنشاء حساب - قيد التطوير'),
              ),
            ),
            '/login': (context) => const Scaffold(
              body: Center(
                child: Text('تسجيل الدخول - قيد التطوير'),
              ),
            ),
            '/guest_home': (context) => const Scaffold(
              body: Center(
                child: Text('التصفح كزائر - قيد التطوير'),
              ),
            ),
          },
        );
      },
    );
  }
}
