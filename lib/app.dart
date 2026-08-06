import 'package:flutter/material.dart';

import 'screens/welcome/welcome_screen.dart';

class KenzaHubApp extends StatelessWidget {
  const KenzaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Kenza Hub',

      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC62828),
        ),
        useMaterial3: true,
      ),

      home: const WelcomeScreen(),
    );
  }
} 
