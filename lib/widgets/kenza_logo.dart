import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KenzaLogo extends StatelessWidget {
  const KenzaLogo({
    super.key,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  final double width;
  final double height;
  final BoxFit fit;

  static final Future<String> _encodedLogo = rootBundle.loadString(
    'assets/logos/kenza_mark.png.base64',
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _encodedLogo,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            base64Decode(snapshot.data!),
            width: width,
            height: height,
            fit: fit,
          );
        }
        return SizedBox(
          width: width,
          height: height,
          child: const Icon(
            Icons.storefront_rounded,
            size: 72,
            color: Color(0xFF17366F),
          ),
        );
      },
    );
  }
}
