import 'package:flutter/material.dart';
import 'package:kenza_hub/screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كنزة هب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cairo', // لو عندك خط Cairo في المشروع
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
          body: Center(child: Text('إنشاء حساب - قيد التطوير')),
        ),
        '/login': (context) => const Scaffold(
          body: Center(child: Text('تسجيل الدخول - قيد التطوير')),
        ),
        '/guest_home': (context) => const Scaffold(
          body: Center(child: Text('التصفح كزائر - قيد التطوير')),
        ),
      },
    );
  }
}