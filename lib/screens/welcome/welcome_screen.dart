import 'package:flutter/material.dart';
import 'welcome_image_rows.dart';
import 'welcome_logo.dart';
import 'welcome_actions.dart';
import 'language_selector.dart';
import 'welcome_footer.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const WelcomeLogo(),
                  const LanguageSelector(),
                ],
              ),
            ),
            const Expanded(child: WelcomeImageRows()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              child: Column(
                children: [
                  const Text(
                    'لو مش محتاجها...\nغيرك محتاجها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'بيع واشتري بسهولة من غير عمولة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const WelcomeActions(),
                  const SizedBox(height: 16),
                  const WelcomeFooter(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
