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
              children: const [

                // Logo + Brand
                HeaderSection(),

                SizedBox(height: 25),

                // صور العرض
                ImageSlider(),

                SizedBox(height: 25),

                // النص الترحيبي
                WelcomeText(),

                SizedBox(height: 30),

                // أزرار الدخول والتسجيل
                ActionButtons(),

                SizedBox(height: 25),

                // الروابط السفلية
                FooterLinks(),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
