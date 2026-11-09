import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_gate.dart';

class KenzaSplashScreen extends StatefulWidget {
  const KenzaSplashScreen({super.key});

  @override
  State<KenzaSplashScreen> createState() => _KenzaSplashScreenState();
}

class _KenzaSplashScreenState extends State<KenzaSplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const AuthGate(),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 156,
              height: 156,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.storefront_rounded,
                size: 112,
                color: Color(0xFFC62828),
              ),
            ),
            const SizedBox(height: 22),
            const Text('كنزة هب', textDirection: TextDirection.rtl,
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 30,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            const Text('Kenza Hub', style: TextStyle(
              color: Color(0xFFC62828), fontSize: 17,
              fontWeight: FontWeight.w600, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }
}
