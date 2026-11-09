import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

class AboutKenzaScreen extends StatelessWidget {
  const AboutKenzaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storefront_rounded, color: Colors.white, size: 42),
                const SizedBox(height: 18),
                const Text('كنزة هب', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(s.brandTagline, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(s.brandSubtitle, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.7)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _section(s.ideaTitle, s.ideaBody),
          _section(s.whatYouFindTitle, s.whatYouFindBody),
          _section(s.howItWorksTitle, s.howItWorksBody),
          _section(s.missionTitle, s.missionBody),
          const SizedBox(height: 8),
          Text(s.aboutThanks, style: const TextStyle(height: 1.8, color: Color(0xFF475569))),
          const SizedBox(height: 20),
          Center(child: Text(s.copyright, style: const TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }

  static Widget _section(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(height: 1.8, color: Color(0xFF475569))),
      ],
    ),
  );
}
