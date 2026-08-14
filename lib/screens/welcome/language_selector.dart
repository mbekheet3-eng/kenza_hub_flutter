import 'package:flutter/material.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _currentLanguage = 'ar';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildLanguageButton('AR'),
        const SizedBox(width: 4),
        _buildLanguageButton('EN'),
        const SizedBox(width: 4),
        _buildLanguageButton('FR'),
      ],
    );
  }

  Widget _buildLanguageButton(String code) {
    final isSelected = _currentLanguage == code.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentLanguage = code.toLowerCase();
        });
        // هنا سيتم إضافة Localization الفعلي لاحقاً
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC62828) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFC62828) : const Color(0xFFCBD5E1),
            width: 1.2,
          ),
        ),
        child: Text(
          code,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
