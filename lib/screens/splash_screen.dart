import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import '../widgets/kenza_logo.dart';

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = math.min(
              constraints.maxWidth * 0.88,
              constraints.maxHeight * 0.78,
            );
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KenzaLogo(width: logoSize, height: logoSize),
                  const SizedBox(height: 8),
                  const Text(
                    'Kenza',
                    style: TextStyle(
                      color: Color(0xFF17366F),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
