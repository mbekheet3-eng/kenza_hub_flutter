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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HeaderSection(
                          currentLanguage: 'العربية',
                          onLanguageChanged: (language) {},
                        ),

                        const SizedBox(height: 12),

                        const ImageSlider(),

                        const SizedBox(height: 22),

                        const WelcomeText(),

                        const SizedBox(height: 24),

                        ActionButtons(
                          onSignUp: () {},
                          onLogin: () {},
                          onGuest: () {},
                        ),

                        const SizedBox(height: 18),

                        FooterLinks(
                          onAbout: () {},
                          onTerms: () {},
                          onPrivacy: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}