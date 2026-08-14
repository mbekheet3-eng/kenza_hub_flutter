import 'package:flutter/material.dart';

class WelcomeFooter extends StatelessWidget {
  const WelcomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _footerLink('من نحن'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
        ),
        _footerLink('الشروط والأحكام'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
        ),
        _footerLink('سياسة الخصوصية'),
      ],
    );
  }

  Widget _footerLink(String text) {
    return TextButton(
      onPressed: () {
        // سيتم إضافة الشاشات لاحقاً
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
