import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'welcome_image_rows.dart';
import 'welcome_logo.dart';
import 'welcome_actions.dart';
import 'language_selector.dart';
import 'welcome_footer.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          WelcomeLogo(),
                          LanguageSelector(),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: isSmallScreen ? 235 : 275,
                      child: const Center(
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
                            AppLocalizations.of(context).welcomeTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context).welcomeSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(
                            height: isSmallScreen ? 16 : 22,
                          ),
                          const WelcomeActions(),
                          SizedBox(
                            height: isSmallScreen ? 10 : 16,
                          ),
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
