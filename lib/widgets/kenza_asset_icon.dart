import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';

/// Displays only the visible artwork of a PNG, trimming transparent margins
/// at runtime so icons with different source canvases appear consistently sized.
class KenzaAssetIcon extends StatelessWidget {
  const KenzaAssetIcon(
    this.asset, {
    super.key,
    required this.size,
    this.scale = 1.0,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double size;

  /// Kept for source compatibility with existing call sites.
  /// Artwork is now normalized from its alpha bounds, so this value is unused.
  @Deprecated('Artwork is normalized automatically from its visible alpha bounds.')
  final double scale;

  /// Kept for source compatibility. Cropped artwork is always contained.
  final BoxFit fit;

  static final Map<String, Future<_VisibleIcon>> _cache = {};

  static Future<_VisibleIcon> _load(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (pixels == null) {
      return _VisibleIcon(
        image,
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      );
    }

    var minX = image.width;
    var minY = image.height;
    var maxX = -1;
    var maxY = -1;
    final bytes = pixels.buffer.asUint8List();

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final alpha = bytes[(y * image.width + x) * 4 + 3];
        if (alpha > 10) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    final source = maxX < minX
        ? ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble())
        : ui.Rect.fromLTRB(
            minX.toDouble(),
            minY.toDouble(),
            (maxX + 1).toDouble(),
            (maxY + 1).toDouble(),
          );

    return _VisibleIcon(image, source);
  }

  @override
  Widget build(BuildContext context) {
    final future = _cache.putIfAbsent(asset, () => _load(asset));

    return SizedBox.square(
      dimension: size,
      child: FutureBuilder<_VisibleIcon>(
        future: future,
        builder: (context, snapshot) {
          final visible = snapshot.data;
          if (visible == null) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            painter: _VisibleIconPainter(visible),
            size: Size.square(size),
          );
        },
      ),
    );
  }
}

class _VisibleIcon {
  const _VisibleIcon(this.image, this.source);

  final ui.Image image;
  final ui.Rect source;
}

class _VisibleIconPainter extends CustomPainter {
  const _VisibleIconPainter(this.icon);

  final _VisibleIcon icon;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    const inset = 0.05;
    final maxWidth = size.width * (1 - inset * 2);
    final maxHeight = size.height * (1 - inset * 2);
    final aspect = icon.source.width / icon.source.height;

    late double width;
    late double height;
    if (aspect >= maxWidth / maxHeight) {
      width = maxWidth;
      height = width / aspect;
    } else {
      height = maxHeight;
      width = height * aspect;
    }

    final destination = ui.Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
    );

    canvas.drawImageRect(
      icon.image,
      icon.source,
      destination,
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _VisibleIconPainter oldDelegate) =>
      oldDelegate.icon.image != icon.image ||
      oldDelegate.icon.source != icon.source;
}
