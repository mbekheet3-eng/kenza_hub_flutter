import 'package:flutter/material.dart';

class WelcomeImageRow extends StatelessWidget {
  final List<String> images;
  final double imageWidth;
  final double imageHeight;
  final double spacing;

  const WelcomeImageRow({
    super.key,
    required this.images,
    required this.imageWidth,
    required this.imageHeight,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final repeatedImages = [...images, ...images];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final image in repeatedImages)
          Padding(
            padding: EdgeInsets.only(right: spacing),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: imageWidth,
                    height: imageHeight,
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF94A3B8),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}