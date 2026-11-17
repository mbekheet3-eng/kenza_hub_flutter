import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide locale state shared by all screens and persisted on this device.
final class AppLocale {
  AppLocale._();

  static const _storageKey = 'kenza_app_language';
  static final ValueNotifier<Locale> notifier =
      ValueNotifier<Locale>(const Locale('ar'));

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_storageKey);
    if (savedLanguage != null &&
        (savedLanguage == 'ar' || savedLanguage == 'en' || savedLanguage == 'fr')) {
      notifier.value = Locale(savedLanguage);
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'ar' && languageCode != 'en' && languageCode != 'fr') {
      return;
    }
    notifier.value = Locale(languageCode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, languageCode);
  }
}
