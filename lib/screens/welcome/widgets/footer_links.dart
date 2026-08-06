import 'package:flutter/material.dart';

class FooterLinks extends StatelessWidget {
  const FooterLinks({
    super.key,
    required this.onAbout,
    required this.onTerms,
    required this.onPrivacy,
  });

  final VoidCallback onAbout;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 20,
        left: 24,
        right: 24,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: onAbout,
            child: const Text(
              'من نحن',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onTerms,
            child: const Text(
              'الشروط والأحكام',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onPrivacy,
            child: const Text(
              'سياسة الخصوصية',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
