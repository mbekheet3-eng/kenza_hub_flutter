import 'package:flutter/material.dart';
import 'welcome_image_row.dart';

class WelcomeImageRows extends StatefulWidget {
  const WelcomeImageRows({super.key});

  @override
  State<WelcomeImageRows> createState() => _WelcomeImageRowsState();
}

class _WelcomeImageRowsState extends State<WelcomeImageRows>
    with TickerProviderStateMixin {
  late final AnimationController _controllerRow1;
  late final AnimationController _controllerRow2;

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

    _controllerRow1 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _controllerRow2 = AnimationController(
      duration: const Duration(seconds: 30),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // الهدف: صورتان كاملتان + جزء من الثالثة.
        final imageWidth = screenWidth / 2.35;

        final imageHeight = imageWidth.clamp(95.0, 150.0);
        final spacing = 8.0;

        final cycleWidth =
            (_row1Images.length * (imageWidth + spacing));

        return ClipRect(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controllerRow1,
                builder: (context, child) {
                  // الصف الأول يتحرك باستمرار إلى اليمين.
                  final offset =
                      -cycleWidth +
                      (_controllerRow1.value * cycleWidth);

                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: WelcomeImageRow(
                      images: _row1Images,
                      imageWidth: imageWidth,
                      imageHeight: imageHeight,
                      spacing: spacing,
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              AnimatedBuilder(
                animation: _controllerRow2,
                builder: (context, child) {
                  // الصف الثاني يتحرك باستمرار إلى اليسار.
                  final offset =
                      -(_controllerRow2.value * cycleWidth);

                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: WelcomeImageRow(
                      images: _row2Images,
                      imageWidth: imageWidth,
                      imageHeight: imageHeight,
                      spacing: spacing,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}