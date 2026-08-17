import 'package:flutter/material.dart';
import 'welcome_image_row.dart';

class WelcomeImageRows extends StatefulWidget {
  const WelcomeImageRows({super.key});

  @override
  State<WelcomeImageRows> createState() => _WelcomeImageRowsState();
}

class _WelcomeImageRowsState extends State<WelcomeImageRows>
    with SingleTickerProviderStateMixin {
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
    // الصف الأول يتحرك بسرعة ثابتة للأمام (→)
    _controllerRow1 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    // الصف الثاني يتحرك بسرعة ثابتة للخلف (←)
    _controllerRow2 = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controllerRow1.dispose();
    _controllerRow2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الصف الأول (→ اتجاه)
        AnimatedBuilder(
          animation: _controllerRow1,
          builder: (context, child) {
            final double offset = _controllerRow1.value * 200;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: WelcomeImageRow(images: _row1Images),
            );
          },
        ),
        const SizedBox(height: 10),
        // الصف الثاني (← اتجاه معاكس)
        AnimatedBuilder(
          animation: _controllerRow2,
          builder: (context, child) {
            final double offset = -(_controllerRow2.value * 200);
            return Transform.translate(
              offset: Offset(offset, 0),
              child: WelcomeImageRow(images: _row2Images),
            );
          },
        ),
      ],
    );
  }
}
