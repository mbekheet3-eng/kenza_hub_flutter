import 'package:flutter/material.dart';

import 'home_screen_new.dart' as current;

/// Backward-compatible name for the current marketplace home screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const current.HomeScreen();
}
