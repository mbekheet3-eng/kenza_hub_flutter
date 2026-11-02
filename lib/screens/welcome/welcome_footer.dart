import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

class WelcomeFooter extends StatelessWidget {
  const WelcomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.safeOf(context);

    return Column(
      children: [
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 10,
          children: [
            _footerLink(context, strings.aboutUs, '/about-kenza'),
            _footerLink(context, strings.termsAndConditions, '/policies'),
            _footerLink(context, strings.privacyPolicy, '/policies'),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '© Kenza Hub',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _footerLink(BuildContext context, String label, String route) {
    return TextButton(
      onPressed: () => context.push(route),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
