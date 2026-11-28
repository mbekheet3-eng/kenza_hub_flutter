import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../config/app_locale.dart';
import '../l10n/app_strings.dart';
import '../widgets/kenza_logo.dart';

import 'main_navigation_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'about_kenza_screen.dart';
import 'policies_screen.dart';
import 'privacy_policy_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _row1Controller;
  late final AnimationController _row2Controller;

  static const List<String> _row1Images = [
    'assets/images/welcome/welcome_row1_05.png',
    'assets/images/welcome/welcome_row1_06.png',
    'assets/images/welcome/welcome_row1_07.png',
    'assets/images/welcome/welcome_row1_08.png',
    'assets/images/welcome/welcome_row1_09.png',
    'assets/images/welcome/welcome_row1_10.png',
    'assets/images/welcome/welcome_row1_01.png',
    'assets/images/welcome/welcome_row1_02.png',
    'assets/images/welcome/welcome_row1_03.png',
    'assets/images/welcome/welcome_row1_04.png',
    'https://apollosports.pk/cdn/shop/files/Gemini_Generated_Image_woo9yzwoo9yzwoo9.jpg?v=1771931312&width=800',
    'https://abbeyangels.co.uk/uploads/2026/04/essential-sports-equipment-examples-for-every-athlete.webp',
    'https://thecoachhouse.store/cdn/shop/collections/pet-accessories-bedding-tpys.png?v=1762802681',
    'https://yiwusrc.com/images/custom/pet-supplies.jpg',
    'https://www.globus.de/media/globus/themen/sommer/schulanfang/schreibwaren_169.jpg',
    'https://www.wiky.sk/sub/wiky.sk/shop/content/full_images/127.jpg',
  ];

  static const List<String> _row2Images = [
    'assets/images/welcome/welcome_row2_05.png',
    'assets/images/welcome/welcome_row2_06.png',
    'assets/images/welcome/welcome_row2_07.png',
    'assets/images/welcome/welcome_row2_08.png',
    'assets/images/welcome/welcome_row2_09.png',
    'assets/images/welcome/welcome_row2_10.png',
    'assets/images/welcome/welcome_row2_01.png',
    'assets/images/welcome/welcome_row2_02.png',
    'assets/images/welcome/welcome_row2_03.png',
    'assets/images/welcome/welcome_row2_04.png',
    'https://cdn.prod.website-files.com/58ff73d27e10d442b71ca39c/5e3b69c2c2c6352e36fdd33f_ulta-beauty.jpg',
    'https://muslimsheraz.com/cdn/shop/collections/IMG-2084.png?crop=center&height=500&v=1782414415&width=600',
    'https://www.aircold.sg/cdn/shop/collections/WhatsApp_Image_2026-01-20_at_08.35.17.jpg?v=1768875219&width=1536',
    'https://dogruhomestore.com/upload/mega-kucuk-ev.png',
    'https://image.rakuten.co.jp/ideabike/cabinet/tool/h14002a_002.jpg',
    'https://i.ebayimg.com/images/g/fJIAAeSw9jVo1llL/s-l1200.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _row1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 44000),
    )..repeat();
    _row2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _row1Controller.dispose();
    _row2Controller.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openLogin() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const FractionallySizedBox(
        heightFactor: 0.94,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: LoginScreen(),
        ),
      ),
    );
  }

  Widget _imageRow({
    required List<String> images,
    required double progress,
    required double imageWidth,
    required double imageHeight,
    required bool movesLeft,
  }) {
    const spacing = 9.0;
    final cycleWidth = images.length * (imageWidth + spacing);
    final offset = movesLeft
        ? -(progress * cycleWidth)
        : (-cycleWidth + progress * cycleWidth);

    Widget sequence() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final image in images)
          Padding(
            padding: const EdgeInsets.only(right: spacing),
            child: Container(
              width: imageWidth,
              height: imageHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: image.startsWith('https://')
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFF1F5F9),
                          child: Center(
                            child: Icon(Icons.image_not_supported_outlined,
                                color: Color(0xFF94A3B8)),
                          ),
                        ),
                      )
                    : Image.asset(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFF1F5F9),
                          child: Center(
                            child: Icon(Icons.image_not_supported_outlined,
                                color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
              ),
            ),
          ),
      ],
    );

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: cycleWidth * 2,
        maxWidth: cycleWidth * 2,
        minHeight: imageHeight,
        maxHeight: imageHeight,
        child: Transform.translate(
          offset: Offset(offset, 0),
          child: SizedBox(
            width: cycleWidth * 2,
            height: imageHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [sequence(), sequence()],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final strings = AppStrings.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenHeight < 700;
    final imageWidth = (screenWidth * 0.40).clamp(145.0, 175.0).toDouble();
    final imageHeight = imageWidth * 1.22;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const KenzaLogo(width: 52, height: 52),
                        PopupMenuButton<String>(
                          tooltip: strings.languageChange,
                          onSelected: AppLocale.setLanguage,
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'ar', child: Text('العربية')),
                            PopupMenuItem(value: 'en', child: Text('English')),
                            PopupMenuItem(value: 'fr', child: Text('Français')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(languageCode == 'ar' ? 'العربية' : languageCode == 'fr' ? 'Français' : 'English',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                const SizedBox(width: 3),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: imageHeight,
                        width: double.infinity,
                        child: AnimatedBuilder(
                          animation: _row1Controller,
                          builder: (_, __) => _imageRow(
                            images: _row1Images,
                            progress: _row1Controller.value,
                            imageWidth: imageWidth,
                            imageHeight: imageHeight,
                            movesLeft: true,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 11),
                      SizedBox(
                        height: imageHeight * 0.90,
                        width: double.infinity,
                        child: AnimatedBuilder(
                          animation: _row2Controller,
                          builder: (_, __) => _imageRow(
                            images: _row2Images,
                            progress: _row2Controller.value,
                            imageWidth: imageWidth * 0.98,
                            imageHeight: imageHeight * 0.90,
                            movesLeft: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    child: Column(
                      children: [
                        Text(
                          strings.welcomeTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 23 : 27,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            color: const Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 22),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => _open(const SignupScreen()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              strings.signUp,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _openLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              strings.login,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => const MainNavigationScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            strings.continueAsGuest,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Divider(color: Color(0xFFE2E8F0), height: 1),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 2,
                          children: [
                            TextButton(
                              onPressed: () => _open(const AboutKenzaScreen()),
                              child: Text(strings.aboutTitle),
                            ),
                            const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                            TextButton(
                              onPressed: () => _open(const PoliciesScreen()),
                              child: Text(strings.policiesTitle),
                            ),
                            const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                            TextButton(
                              onPressed: () => _open(const PrivacyPolicyScreen()),
                              child: Text(strings.privacyPolicy),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '© Kenza Hub',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}