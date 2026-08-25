import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

class WelcomeFooter extends StatelessWidget {
  const WelcomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Column(
      children: [
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _footerLink(context, strings.aboutUs),
            _footerLink(context, strings.termsAndConditions),
            _footerLink(context, strings.privacyPolicy),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '© ${DateTime.now().year} Kenza Hub',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _footerLink(BuildContext context, String label) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to the corresponding page
      },
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
