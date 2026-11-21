import 'package:material_ui/material_ui.dart';

/// Displays a PNG icon while compensating for transparent padding inside
/// the source image. The viewport stays fixed; only the visible artwork grows.
class KenzaAssetIcon extends StatelessWidget {
  const KenzaAssetIcon(
    this.asset, {
    super.key,
    required this.size,
    this.scale = 1.25,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double size;
  final double scale;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: fit,
          ),
        ),
      ),
    );
  }
}
