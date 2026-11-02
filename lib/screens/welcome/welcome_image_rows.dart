import 'package:flutter/material.dart';
import 'welcome_image_row.dart';

class WelcomeImageRows extends StatefulWidget {
  const WelcomeImageRows({super.key});

  @override
  State<WelcomeImageRows> createState() => _WelcomeImageRowsState();
}

class _WelcomeImageRowsState extends State<WelcomeImageRows>
    with TickerProviderStateMixin {
  late final AnimationController _row1Controller;
  late final AnimationController _row2Controller;

  // Both rows intentionally begin with image 05.
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
  ];

  @override
  void initState() {
    super.initState();
    _row1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
    _row2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _row1Controller.dispose();
    _row2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallScreen = screenHeight < 700;
    final imageWidth = (screenWidth * 0.34).clamp(112.0, 145.0);
    final imageHeight = imageWidth * 1.22;
    const spacing = 9.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _row1Controller,
            builder: (context, child) => WelcomeImageRow(
              images: _row1Images,
              imageWidth: imageWidth,
              imageHeight: imageHeight,
              spacing: spacing,
              progress: _row1Controller.value,
              direction: WelcomeImageDirection.rightToLeft,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 11),
        SizedBox(
          height: imageHeight * 0.88,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _row2Controller,
            builder: (context, child) => WelcomeImageRow(
              images: _row2Images,
              imageWidth: imageWidth * 0.9,
              imageHeight: imageHeight * 0.88,
              spacing: spacing,
              progress: _row2Controller.value,
              direction: WelcomeImageDirection.leftToRight,
            ),
          ),
        ),
      ],
    );
  }
}
