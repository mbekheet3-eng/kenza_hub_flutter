import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.policiesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.policiesIntro,
            style: const TextStyle(height: 1.8, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
          _documentTile(
            context,
            icon: Icons.gavel_outlined,
            title: s.termsAndConditions,
            subtitle: s.termsOfService,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const TermsScreen()),
            ),
          ),
          _documentTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: s.privacyPolicy,
            subtitle: s.privacySecurity,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacyPolicyScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
