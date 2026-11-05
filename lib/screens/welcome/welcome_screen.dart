import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'welcome_actions.dart';
import 'welcome_footer.dart';
import 'welcome_image_rows.dart';
import 'welcome_logo.dart';
import 'language_selector.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallScreen = screenHeight < 700;
    
    // Get strings safely - fallback to Arabic if context not available
    late final AppLocalizations strings;
    try {
      strings = AppLocalizations.of(context);
    } catch (_) {
      strings = AppLocalizations(AppLocalizations.currentLocale);
    }

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
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          WelcomeLogo(),
                          LanguageSelector(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: const Align(
                        alignment: Alignment.topCenter,
                        child: WelcomeImageRows(),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        isSmallScreen ? 2 : 8,
                        24,
                        16,
                      ),
                      child: Column(
                        children: [
                          Text(
                            strings.welcomeTitle,
                            textAlign: TextAlign.center,
                            textDirection: strings.isArabic
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 23 : 27,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              height: 1.3,
                              letterSpacing: 0,

                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.welcomeSubtitle,
                            textAlign: TextAlign.center,
                            textDirection: strings.isArabic
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 15,
                              color: const Color(0xFF64748B),
                              height: 1.5,
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
