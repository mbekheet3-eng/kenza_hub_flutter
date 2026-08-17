import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

class WelcomeActions extends StatelessWidget {
  const WelcomeActions({super.key});

  static const Color primaryRed = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signup');
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
              AppLocalizations.of(context).signUp,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
<<<<<<< ours
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              _showLoginBottomSheet(context);
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
              AppLocalizations.of(context).login,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
||||||| base

        // Secondary CTA - تسجيل الدخول (يظهر Bottom Sheet)
        TextButton(
          onPressed: () {
            _showLoginBottomSheet(context);
          },
          child: const Text(
            'تسجيل الدخول',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
=======

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              _showLoginBottomSheet(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'تسجيل الدخول',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
>>>>>>> theirs
            ),
          ),
        ),
<<<<<<< ours
        const SizedBox(height: 8),
||||||| base
        const SizedBox(height: 4),

        // Guest - تصفح كزائر
=======

        const SizedBox(height: 8),

>>>>>>> theirs
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/guest_home');
          },
          child: Text(
            AppLocalizations.of(context).continueAsGuest,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  void _showLoginBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).login,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).email,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).password,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).enter),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}