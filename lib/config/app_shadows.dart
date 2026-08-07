import 'package:flutter/material.dart';

/// Reusable subtle shadow presets aligned with Material design principles.
final class AppShadows {
  AppShadows._();

  /// Small elevation shadow (used for cards, small surfaces).
  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 3.0,
      spreadRadius: 0.0,
    ),
  ];

  /// Medium elevation shadow (used for raised buttons, dialogs).
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 8.0,
      spreadRadius: 0.0,
    ),
    BoxShadow(
      color: Color(0x07000000),
      offset: Offset(0, 2),
      blurRadius: 2.0,
      spreadRadius: 0.0,
    ),
  ];

  /// Large elevation shadow (used for prominent overlays).
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 10),
      blurRadius: 20.0,
      spreadRadius: 0.0,
    ),
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 4),
      blurRadius: 6.0,
      spreadRadius: 0.0,
    ),
  ];
}
