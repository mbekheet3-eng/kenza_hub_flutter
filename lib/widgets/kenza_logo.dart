import 'package:material_ui/material_ui.dart';

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

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logos/kenza_mark.png',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/logos/logo.png',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, fallbackError, fallbackStackTrace) =>
            SizedBox(
          width: width,
          height: height,
          child: const Icon(
            Icons.storefront_rounded,
            size: 72,
            color: Color(0xFF17366F),
          ),
        ),
      ),
    );
  }
}
