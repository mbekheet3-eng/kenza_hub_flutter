import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

class WelcomeActions extends StatelessWidget {
  const WelcomeActions({super.key});

  static const Color primaryRed = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    // Safe localization access
    final strings = AppLocalizations.safeOf(context);

    return Column(
      children: [
        // Sign Up Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              context.push('/sign-up');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              strings.signUp,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Login Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              context.push('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              strings.login,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Continue as Guest Button
        TextButton(
          onPressed: () {
            context.push('/home');
          },
          child: Text(
            strings.continueAsGuest,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

}
