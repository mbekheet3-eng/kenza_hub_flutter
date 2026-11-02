import 'package:flutter/material.dart';

class WelcomeLogo extends StatelessWidget {
  const WelcomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Text(
            'كنزة هب',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          );
        },
      ),
    );
  }
}
