import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  static const Map<String, String> _labels = {
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocalizations.localeNotifier,
      builder: (context, locale, _) {
        final code = locale.languageCode;
        final label = _labels[code] ?? _labels['ar']!;
        return PopupMenuButton<String>(
          tooltip: 'Language',
          onSelected: AppLocalizations.setLocale,
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'ar', child: _LanguageOption(label: 'العربية', code: 'AR')),
            PopupMenuItem(value: 'en', child: _LanguageOption(label: 'English', code: 'EN')),
            PopupMenuItem(value: 'fr', child: _LanguageOption(label: 'Français', code: 'FR')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, size: 18, color: Color(0xFF0F172A)),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;

  const _LanguageOption({required this.label, required this.code});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            code,
            style: const TextStyle(
              color: Color(0xFFC62828),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        Text(label),
      ],
    );
  }
}
