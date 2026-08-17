import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

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
<<<<<<< ours
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
||||||| base
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
=======
    final repeatedImages = [...images, ...images];

    return Row(
      mainAxisSize: MainAxisSize.min,
>>>>>>> theirs
      children: [
<<<<<<< ours
        _footerLink(AppLocalizations.of(context).aboutUs),
        _separator(),
        _footerLink(AppLocalizations.of(context).termsAndConditions),
        _separator(),
        _footerLink(AppLocalizations.of(context).privacyPolicy),
||||||| base
        _footerLink('من نحن'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
        ),
        _footerLink('الشروط والأحكام'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
        ),
        _footerLink('سياسة الخصوصية'),
=======
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
>>>>>>> theirs
      ],
    );
  }
<<<<<<< ours

  Widget _separator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '|',
        style: TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _footerLink(String text) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
||||||| base

  Widget _footerLink(String text) {
    return TextButton(
      onPressed: () {
        // سيتم إضافة الشاشات لاحقاً
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
=======
}
>>>>>>> theirs
