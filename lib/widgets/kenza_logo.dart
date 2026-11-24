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
      // This asset is byte-for-byte the same image used by Android's
      // mipmap/ic_launcher.jpg, packaged as a Flutter asset for the welcome UI.
      'assets/logos/kenza_mark.jpg',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: width,
        height: height,
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'kenza',
            style: TextStyle(
              fontFamily: 'cursive',
              fontSize: 34,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC62828),
            ),
          ),
        ),
      ),
    );
  }
}
