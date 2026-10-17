import 'package:flutter/material.dart';
import 'welcome_image_row.dart';

class WelcomeImageRows extends StatefulWidget {
  const WelcomeImageRows({super.key});

  @override
  State<WelcomeImageRows> createState() => _WelcomeImageRowsState();
}

class _WelcomeImageRowsState extends State<WelcomeImageRows>
    with TickerProviderStateMixin {
  late AnimationController _controllerRow1;
  late AnimationController _controllerRow2;

  final List<String> _row1Images = [
    'assets/images/welcome/welcome_row1_01.png',
    'assets/images/welcome/welcome_row1_02.png',
    'assets/images/welcome/welcome_row1_03.png',
    'assets/images/welcome/welcome_row1_04.png',
    'assets/images/welcome/welcome_row1_05.png',
    'assets/images/welcome/welcome_row1_06.png',
    'assets/images/welcome/welcome_row1_07.png',
    'assets/images/welcome/welcome_row1_08.png',
    'assets/images/welcome/welcome_row1_09.png',
    'assets/images/welcome/welcome_row1_10.png',
  ];

  final List<String> _row2Images = [
    'assets/images/welcome/welcome_row2_01.png',
    'assets/images/welcome/welcome_row2_02.png',
    'assets/images/welcome/welcome_row2_03.png',
    'assets/images/welcome/welcome_row2_04.png',
    'assets/images/welcome/welcome_row2_05.png',
    'assets/images/welcome/welcome_row2_06.png',
    'assets/images/welcome/welcome_row2_07.png',
    'assets/images/welcome/welcome_row2_08.png',
    'assets/images/welcome/welcome_row2_09.png',
    'assets/images/welcome/welcome_row2_10.png',
  ];

  @override
  void initState() {
    super.initState();
    
    // Row 1: Smooth infinite scroll to the left
    _controllerRow1 = AnimationController(
      duration: const Duration(seconds: 50),
      vsync: this,
    )..repeat();

    // Row 2: Smooth infinite scroll to the right
    _controllerRow2 = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controllerRow1.dispose();
    _controllerRow2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenHeight(context) < 700;
    final imageWidth = screenWidth * (isSmallScreen ? 0.26 : 0.28);
    final imageHeight = imageWidth * 1.3;

    return Column(
      children: [
        // Row 1: Scrolls to the left
        AnimatedBuilder(
          animation: _controllerRow1,
          builder: (context, child) {
            // Infinite scroll effect: -1x means continuous movement
            final offset = -_controllerRow1.value * screenWidth * 2.5;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: WelcomeImageRow(
                images: _row1Images,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        
        // Row 2: Scrolls to the right
        AnimatedBuilder(
          animation: _controllerRow2,
          builder: (context, child) {
            // Infinite scroll effect: opposite direction
            final offset = _controllerRow2.value * screenWidth * 2.0;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: WelcomeImageRow(
                images: _row2Images,
                imageWidth: imageWidth * 0.9,
                imageHeight: imageHeight * 0.9,
              ),
            );
          },
        ),
      ],
    );
  }

  double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;
}
