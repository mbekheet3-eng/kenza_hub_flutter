import 'package:flutter/material.dart';

/// App-wide locale state shared by the welcome language selector and MaterialApp.
final class AppLocale {
  AppLocale._();

  static final ValueNotifier<Locale> notifier =
      ValueNotifier<Locale>(const Locale('ar'));

  static void setLanguage(String languageCode) {
    if (languageCode != 'ar' && languageCode != 'en' && languageCode != 'fr') return;
    notifier.value = Locale(languageCode);
  }
}
