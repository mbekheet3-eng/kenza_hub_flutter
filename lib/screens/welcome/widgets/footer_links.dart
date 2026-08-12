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
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 2,
      children: [
        TextButton(
          onPressed: onAbout,
          child: const Text(
            'من نحن',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
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
              fontSize: 13,
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}