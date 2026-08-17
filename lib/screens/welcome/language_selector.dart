import 'package:flutter/material.dart';
<<<<<<< ours
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
||||||| base
=======
import '../../core/localization/app_localizations.dart';
>>>>>>> theirs

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
<<<<<<< ours
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _selectedLanguage = 'AR';

  final Map<String, String> _languages = {
    'AR': 'العربية',
    'EN': 'English',
    'FR': 'Français',
  };

  @override
  void initState() {
    super.initState();

    final languageCode = AppLocalizations.currentLocale.languageCode;

    _selectedLanguage = switch (languageCode) {
      'en' => 'EN',
      'fr' => 'FR',
      _ => 'AR',
    };
  }

  @override
||||||| base
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _selectedLanguage = 'AR';

  final Map<String, String> _languages = {
    'AR': 'العربية',
    'EN': 'English',
    'FR': 'Français',
  };

  @override
=======
>>>>>>> theirs
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC62828),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
<<<<<<< ours
      child: DropdownButton<String>(
        value: _selectedLanguage,
        icon: const Icon(
          Icons.arrow_drop_down,
          color: Color(0xFF0F172A),
        ),
        underline: const SizedBox(),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
||||||| base
      child: DropdownButton<String>(
        value: _selectedLanguage,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F172A)),
        underline: const SizedBox(),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
=======
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: localization.locale.languageCode,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFFC62828),
          ),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          borderRadius: BorderRadius.circular(10),
          onChanged: (String? languageCode) {
            if (languageCode == null) return;
            AppLocalizations.setLocale(languageCode);
          },
          items: const [
            DropdownMenuItem(
              value: 'ar',
              child: Text('العربية'),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Text('English'),
            ),
            DropdownMenuItem(
              value: 'fr',
              child: Text('Français'),
            ),
          ],
>>>>>>> theirs
        ),
<<<<<<< ours
        onChanged: (String? newValue) {
          if (newValue == null) return;

          setState(() {
            _selectedLanguage = newValue;
          });

          AppLocalizations.setLocale(
            switch (newValue) {
              'EN' => 'en',
              'FR' => 'fr',
              _ => 'ar',
            },
          );
        },
        items: _languages.keys.map((String key) {
          return DropdownMenuItem<String>(
            value: key,
            child: Text(_languages[key]!),
          );
        }).toList(),
||||||| base
        onChanged: (String? newValue) {
          setState(() {
            _selectedLanguage = newValue!;
          });
        },
        items: _languages.keys.map((String key) {
          return DropdownMenuItem<String>(
            value: key,
            child: Text(_languages[key]!),
          );
        }).toList(),
=======
>>>>>>> theirs
      ),
    );
  }
}