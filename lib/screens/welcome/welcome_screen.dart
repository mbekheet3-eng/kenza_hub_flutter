import 'package:flutter/material.dart';

import 'widgets/header_section.dart';
import 'widgets/image_slider.dart';
import 'widgets/welcome_text.dart';
import 'widgets/action_buttons.dart';
import 'widgets/footer_links.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeaderSection(
                  currentLanguage: 'العربية',
                  onLanguageChanged: (language) {},
                ),

                const SizedBox(height: 25),

                const ImageSlider(),

                const SizedBox(height: 25),

                const WelcomeText(),

                const SizedBox(height: 30),

                ActionButtons(
                  onSignUp: () {},
                  onLogin: () {},
                  onGuest: () {},
                ),

                const SizedBox(height: 25),

                FooterLinks(
                  onAbout: () {},
                  onTerms: () {},
                  onPrivacy: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}