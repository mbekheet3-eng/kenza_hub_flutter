import 'package:material_ui/material_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isApple,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isApple;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    isApple ? FontAwesomeIcons.apple : FontAwesomeIcons.google,
                    size: 20,
                    color: isApple ? Colors.black : const Color(0xFF4285F4),
                  ),
                  const SizedBox(width: 12),
                  Text(label),
                ],
              ),
      ),
    );
  }
}
