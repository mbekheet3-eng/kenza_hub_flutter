import 'package:material_ui/material_ui.dart';

import 'kenza_logo.dart';

/// Compact shared Kenza identity for policy, about, and future support pages.
class KenzaPageBrandHeader extends StatelessWidget {
  const KenzaPageBrandHeader({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Center(
        child: KenzaLogo(width: size, height: size),
      ),
    );
  }
}
