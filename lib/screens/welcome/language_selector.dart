import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late String _selectedLanguage;
  bool _isChanging = false;

  final Map<String, String> _languages = {
    'AR': 'العربية',
    'EN': 'English',
    'FR': 'Français',
  };

  @override
  void initState() {
    super.initState();
    _selectedLanguage =
        AppLocalizations.currentLocale.languageCode.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage,
        icon: _isChanging
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF0F172A),
                  ),
                ),
              )
            : const Icon(Icons.arrow_drop_down, color: Color(0xFF0F172A)),
        underline: const SizedBox(),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        onChanged: _isChanging
            ? null
            : (String? newValue) async {
                if (newValue == null || newValue == _selectedLanguage) return;

                setState(() => _isChanging = true);

                // Change locale - this triggers app rebuild via ValueListenableBuilder
                AppLocalizations.setLocale(newValue.toLowerCase());

                // Update UI state
                setState(() {
                  _selectedLanguage = newValue;
                  _isChanging = false;
                });
              },
        items: _languages.keys.map((String key) {
          return DropdownMenuItem<String>(
            value: key,
            child: Text(_languages[key]!),
          );
        }).toList(),
      ),
    );
  }
}
