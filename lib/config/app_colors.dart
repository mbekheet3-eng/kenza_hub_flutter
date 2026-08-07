import 'package:flutter/material.dart';

/// Design system colors for Kenza Hub.
/// Organized to align with Material 3 ColorScheme usage.
final class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFC62828);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary
  static const Color secondary = Color(0xFF0F172A);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Surface / Background
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1F2937);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color onSurface = Color(0xFF1F2937);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  // Outline / Borders (Material 3: ColorScheme.outline)
  static const Color outline = Color(0xFFE5E7EB);
  static const Color outlineVariant = Color(0xFFD1D5DB);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
}
