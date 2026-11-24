import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'auth_gate.dart';

class KenzaSplashScreen extends StatefulWidget {
  const KenzaSplashScreen({super.key});

  @override
  State<KenzaSplashScreen> createState() => _KenzaSplashScreenState();
}

class _KenzaSplashScreenState extends State<KenzaSplashScreen> {
  static const _splashImages = [
    'assets/images/kenza_splash_screen.png',
    'assets/images/kenza_splash_2.jpg',
  ];

  Timer? _timer;
  Timer? _imageTimer;
  int _splashImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imageTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!mounted) return;
      setState(() {
        _splashImageIndex = (_splashImageIndex + 1) % _splashImages.length;
      });
    });
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
    _imageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) => SizedBox.expand(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Image.asset(
              _splashImages[_splashImageIndex],
              key: ValueKey(_splashImageIndex),
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
