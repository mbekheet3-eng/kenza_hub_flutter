import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/config/app_theme.dart';

class KenzaHubApp extends StatelessWidget {
  const KenzaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Placeholder(),
    );
  }
}
