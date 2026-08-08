import 'package:flutter/material.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key});

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<String> _row1 = const [
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

  final List<String> _row2 = const [
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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _image(String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 105,
          height: 130,
          child: Image.asset(
            path,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _animatedRow(
    List<String> images, {
    required bool reverse,
  }) {
    final repeatedImages = [...images, ...images, ...images];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        const double travelDistance = 440;

        final double progress = _controller.value;

        final double offset = reverse
            ? progress * travelDistance
            : -progress * travelDistance;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: repeatedImages.map(_image).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 275,
      child: ClipRect(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 130,
              child: _animatedRow(
                _row1,
                reverse: false,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 130,
              child: _animatedRow(
                _row2,
                reverse: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}