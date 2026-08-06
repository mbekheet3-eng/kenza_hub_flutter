import 'package:flutter/material.dart';

import 'welcome_screen.dart';

class KenzaHubApp extends StatelessWidget {
  const KenzaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kenza Hub',
      debugShowCheckedModeBanner: false,

      // اللغة الافتراضية ستصبح لغة الجهاز،
      // وسنضيف تغيير اللغة لاحقًا.
      locale: WidgetsBinding.instance.platformDispatcher.locale,

      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
        Locale('fr'),
      ],

      theme: ThemeData(
        useMaterial3: true,

        fontFamily: 'Cairo',

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC62828),
        ),

        scaffoldBackgroundColor: Colors.white,

        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          centerTitle: true,
        ),
      ),

      home: const WelcomeScreen(),
    );
  }
}
