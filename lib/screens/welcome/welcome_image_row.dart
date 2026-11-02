import 'package:flutter/material.dart';

enum WelcomeImageDirection { rightToLeft, leftToRight }

class WelcomeImageRow extends StatelessWidget {
  final List<String> images;
  final double imageWidth;
  final double imageHeight;
  final double spacing;
  final double progress;
  final WelcomeImageDirection direction;

  const WelcomeImageRow({
    super.key,
    required this.images,
    required this.imageWidth,
    required this.imageHeight,
    required this.progress,
    required this.direction,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final cycleWidth = images.length * (imageWidth + spacing);
    final isMovingRight = direction == WelcomeImageDirection.leftToRight;
    final offset = isMovingRight
        ? -cycleWidth + (progress * cycleWidth)
        : -(progress * cycleWidth);

    Widget imageSequence() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final image in images)
            Padding(
              padding: EdgeInsets.only(right: spacing),
              child: _WelcomeImage(
                path: image,
                width: imageWidth,
                height: imageHeight,
              ),
            ),
        ],
      );
    }

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
              children: [
                imageSequence(),
                imageSequence(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeImage extends StatelessWidget {
  final String path;
  final double width;
  final double height;

  const _WelcomeImage({
    required this.path,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF1F5F9),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
