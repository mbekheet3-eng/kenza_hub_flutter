import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context)!;
    final sections = <(String, String)>[
      (s.termsAccountTitle, s.termsAccountBody),
      (s.termsListingsTitle, s.termsListingsBody),
      (s.termsSellerTitle, s.termsSellerBody),
      (s.termsBuyerTitle, s.termsBuyerBody),
      (s.termsDeliveryTitle, s.termsDeliveryBody),
      (s.termsPaymentTitle, s.termsPaymentBody),
      (s.termsPrivacyTitle, s.termsPrivacyBody),
      (s.termsConductTitle, s.termsConductBody),
      (s.termsPlatformTitle, s.termsPlatformBody),
      (s.termsChangesTitle, s.termsChangesBody),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.termsAndConditions)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.policiesIntro,
            style: const TextStyle(height: 1.8, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          ...sections.map(
            (section) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  section.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SelectableText(
                      section.$2,
                      style: const TextStyle(
                        height: 1.8,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _notice(s.policiesDraftNotice),
        ],
      ),
    );
  }

  static Widget _notice(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9A3412),
            height: 1.7,
          ),
        ),
      );
}
