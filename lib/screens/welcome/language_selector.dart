import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  static const Map<String, String> _languages = {
    'AR': 'العربية',
    'EN': 'English',
    'FR': 'Français',
  };

  @override
  Widget build(BuildContext context) {
    final selectedLanguage =
        AppLocalizations.currentLocale.languageCode.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _languages.containsKey(selectedLanguage)
              ? selectedLanguage
              : 'AR',
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF0F172A),
          ),
          borderRadius: BorderRadius.circular(12),
          isDense: true,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          onChanged: (value) {
            if (value == null) return;
            AppLocalizations.setLocale(value.toLowerCase());
          },
          items: _languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
        ),
      ),
    );
  }
}
