import 'package:material_ui/material_ui.dart';

/// Kenza Hub brand palette: red, white, navy, and neutral greys.
final class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFC62828);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF0F172A);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Backgrounds and surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1F2937);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color onSurface = Color(0xFF1F2937);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  // Borders
  static const Color outline = Color(0xFFE5E7EB);
  static const Color outlineVariant = Color(0xFFD1D5DB);

  // Status colors stay within the approved brand palette.
  static const Color success = Color(0xFF0F172A);
  static const Color warning = Color(0xFF6B7280);
  static const Color error = Color(0xFFC62828);
}
