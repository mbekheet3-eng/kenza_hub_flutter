import 'package:flutter/material.dart';

class WelcomeImageRow extends StatelessWidget {
  final List<String> images;
  final double speed; // سرعة الحركة (بالثواني)
  final bool reverse; // true = حركة عكسية

  const WelcomeImageRow({
    super.key,
    required this.images,
    required this.speed,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length * 3,
        itemBuilder: (context, index) {
          final imageIndex = index % images.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                images[imageIndex],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
