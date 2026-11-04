import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      final hasSession =
          Supabase.instance.client.auth.currentSession != null;
      context.go(hasSession ? '/home' : '/welcome');
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.88, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 156,
                height: 156,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.storefront_rounded,
                  size: 112,
                  color: Color(0xFFC62828),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'كنزة هب',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Kenza Hub',
              style: TextStyle(
                color: Color(0xFFC62828),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
