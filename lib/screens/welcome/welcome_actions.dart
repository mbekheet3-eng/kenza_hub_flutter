import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:kenza_hub_flutter/screens/auth/auth_bottom_sheet.dart';

class WelcomeActions extends StatelessWidget {
  const WelcomeActions({super.key});

  static const Color primaryRed = Color(0xFFC62828);
  static const Color navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.safeOf(context);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => AuthBottomSheet.show(
              context,
              initialMode: AuthSheetMode.signUp,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: primaryRed.withOpacity(0.22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              strings.signUp,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => AuthBottomSheet.show(
              context,
              initialMode: AuthSheetMode.login,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: navy,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              strings.login,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        TextButton(
          onPressed: () => context.push('/home'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            strings.continueAsGuest,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
