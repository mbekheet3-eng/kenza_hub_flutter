import 'package:flutter/material.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F172A)),
        underline: const SizedBox(),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
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
      ),
    );
  }
}
