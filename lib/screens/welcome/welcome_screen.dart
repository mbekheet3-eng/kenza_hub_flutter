import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
=======
import '../../core/localization/app_localizations.dart';
import 'welcome_actions.dart';
import 'welcome_footer.dart';
>>>>>>> origin/test_build
import 'welcome_image_rows.dart';
import 'welcome_logo.dart';
import 'language_selector.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final screenHeight = MediaQuery.sizeOf(context).height;
=======
    final strings = AppLocalizations.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

>>>>>>> origin/test_build
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      child: Row(
<<<<<<< HEAD
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
=======
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
>>>>>>> origin/test_build
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          WelcomeLogo(),
                          LanguageSelector(),
                        ],
                      ),
                    ),

                    SizedBox(
<<<<<<< HEAD
                      height: isSmallScreen ? 235 : 275,
                      child: const Center(
=======
                      height: isSmallScreen ? 225 : 275,
                      child: const Align(
                        alignment: Alignment.center,
>>>>>>> origin/test_build
                        child: WelcomeImageRows(),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        isSmallScreen ? 4 : 12,
                        24,
                        12,
                      ),
                      child: Column(
                        children: [
                          Text(
<<<<<<< HEAD
                            AppLocalizations.of(context).welcomeTitle,
=======
                            strings.welcomeTitle,
>>>>>>> origin/test_build
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              height: 1.35,
                            ),
                          ),
<<<<<<< HEAD
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context).welcomeSubtitle,
=======

                          const SizedBox(height: 8),

                          Text(
                            strings.welcomeSubtitle,
>>>>>>> origin/test_build
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              color: const Color(0xFF64748B),
                            ),
                          ),
<<<<<<< HEAD
                          SizedBox(
                            height: isSmallScreen ? 16 : 22,
                          ),
                          const WelcomeActions(),
                          SizedBox(
                            height: isSmallScreen ? 10 : 16,
                          ),
=======

                          SizedBox(
                            height: isSmallScreen ? 16 : 22,
                          ),

                          const WelcomeActions(),

                          SizedBox(
                            height: isSmallScreen ? 10 : 16,
                          ),

>>>>>>> origin/test_build
                          const WelcomeFooter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}