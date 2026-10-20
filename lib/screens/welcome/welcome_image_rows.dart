import 'package:flutter/material.dart';
import 'welcome_image_row.dart';

class WelcomeImageRows extends StatefulWidget {
  const WelcomeImageRows({super.key});

  @override
  State<WelcomeImageRows> createState() => _WelcomeImageRowsState();
}

class _WelcomeImageRowsState extends State<WelcomeImageRows>
    with TickerProviderStateMixin {
  late ScrollController _scrollControllerRow1;
  late ScrollController _scrollControllerRow2;

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
    _scrollControllerRow1 = ScrollController();
    _scrollControllerRow2 = ScrollController();

    // Auto scroll Row 1 to the left
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollRow1();
    });

    // Auto scroll Row 2 to the right
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), _autoScrollRow2);
    });
  }

  void _autoScrollRow1() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scrollControllerRow1.hasClients) {
        _scrollControllerRow1.animateTo(
          _scrollControllerRow1.offset + 3,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
        // Reset to start for infinite loop
        if (_scrollControllerRow1.offset >= _scrollControllerRow1.position.maxScrollExtent / 2) {
          _scrollControllerRow1.jumpTo(0);
        }
      }
    }
  }

  void _autoScrollRow2() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (_scrollControllerRow2.hasClients) {
        _scrollControllerRow2.animateTo(
          _scrollControllerRow2.offset - 2.5,
          duration: const Duration(milliseconds: 60),
          curve: Curves.linear,
        );
        // Reset to start for infinite loop
        if (_scrollControllerRow2.offset <= 0) {
          _scrollControllerRow2.jumpTo(_scrollControllerRow2.position.maxScrollExtent / 2);
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollControllerRow1.dispose();
    _scrollControllerRow2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallScreen = screenHeight < 700;
    final imageWidth = screenWidth * (isSmallScreen ? 0.26 : 0.28);
    final imageHeight = imageWidth * 1.3;

    return Column(
      children: [
        // Row 1: Scrolls to the left
        SizedBox(
          height: imageHeight,
          child: ListView(
            controller: _scrollControllerRow1,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              WelcomeImageRow(
                images: _row1Images,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
              ),
              WelcomeImageRow(
                images: _row1Images,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        
        // Row 2: Scrolls to the right
        SizedBox(
          height: imageHeight * 0.9,
          child: ListView(
            controller: _scrollControllerRow2,
            scrollDirection: Axis.horizontal,
            reverse: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              WelcomeImageRow(
                images: _row2Images,
                imageWidth: imageWidth * 0.9,
                imageHeight: imageHeight * 0.9,
              ),
              WelcomeImageRow(
                images: _row2Images,
                imageWidth: imageWidth * 0.9,
                imageHeight: imageHeight * 0.9,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
