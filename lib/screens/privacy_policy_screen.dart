import 'package:material_ui/material_ui.dart';
import '../l10n/app_strings.dart';
import '../widgets/kenza_page_brand_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context)!;
    final sections = <(String, String)>[
      (s.privacyDataTitle, s.privacyDataBody),
      (s.privacyUseTitle, s.privacyUseBody),
      (s.privacyAiReviewTitle, s.privacyAiReviewBody),
      (s.privacyPhoneTitle, s.privacyPhoneBody),
      (s.privacyVisibilityTitle, s.privacyVisibilityBody),
      (s.privacyMessagesTitle, s.privacyMessagesBody),
      (s.privacyOrderDataTitle, s.privacyOrderDataBody),
      (s.privacyRetentionTitle, s.privacyRetentionBody),
      (s.privacySecurityTitle, s.privacySecurityBody),
      (s.privacyChangesTitle, s.privacyChangesBody),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.privacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const KenzaPageBrandHeader(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
            child: Text(s.privacyIntro, style: const TextStyle(color: Colors.white, height: 1.7)),
          ),
          const SizedBox(height: 12),
          ...sections.map((section) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(section.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(section.$2, style: const TextStyle(height: 1.8, color: Color(0xFF475569))),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16)),
            child: Text(s.privacyDraftNotice, style: const TextStyle(color: Color(0xFF9A3412), height: 1.7)),
          ),
        ],
      ),
    );
  }
}
