import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
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
        ),
      ),
    );
  }
}