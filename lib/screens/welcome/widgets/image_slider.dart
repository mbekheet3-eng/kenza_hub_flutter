import 'package:flutter/material.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key});

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _imageWidth = 105;
  static const double _imageHeight = 130;
  static const double _imageSpacing = 5;
  static const double _rowGap = 12;

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

  double get _singleSetWidth {
    return _row1.length * (_imageWidth + (_imageSpacing * 2));
  }

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
      padding: const EdgeInsets.symmetric(
        horizontal: _imageSpacing,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: _imageWidth,
          height: _imageHeight,
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
    required bool moveRight,
  }) {
    final repeatedImages = [
      ...images,
      ...images,
      ...images,
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;

        final offset = moveRight
            ? (progress * _singleSetWidth) - _singleSetWidth
            : -(progress * _singleSetWidth);

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
      height: (_imageHeight * 2) + _rowGap,
      child: ClipRect(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _imageHeight,
              child: _animatedRow(
                _row1,
                moveRight: true,
              ),
            ),

            const SizedBox(height: _rowGap),

            SizedBox(
              height: _imageHeight,
              child: _animatedRow(
                _row2,
                moveRight: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}