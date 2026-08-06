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
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language Button
          OutlinedButton(
            onPressed: () {
              _showLanguageSheet(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(
                color: Color(0xFFC62828),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(currentLanguage.toUpperCase()),
          ),

          // Logo
          Image.asset(
            'assets/images/logo.png',
            height: 42,
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('العربية'),
                onTap: () {
                  Navigator.pop(context);
                  onLanguageChanged('ar');
                },
              ),
              ListTile(
                title: const Text('English'),
                onTap: () {
                  Navigator.pop(context);
                  onLanguageChanged('en');
                },
              ),
              ListTile(
                title: const Text('Français'),
                onTap: () {
                  Navigator.pop(context);
                  onLanguageChanged('fr');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
