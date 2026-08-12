import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: () => _showLanguageSheet(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(
                color: Color(0xFFC62828),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              currentLanguage,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Image.asset(
            'assets/images/logo.png',
            height: 46,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 12),

              ListTile(
                title: const Text(
                  'العربية',
                  textAlign: TextAlign.right,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onLanguageChanged('ar');
                },
              ),

              ListTile(
                title: const Text(
                  'English',
                  textAlign: TextAlign.right,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onLanguageChanged('en');
                },
              ),

              ListTile(
                title: const Text(
                  'Français',
                  textAlign: TextAlign.right,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onLanguageChanged('fr');
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}