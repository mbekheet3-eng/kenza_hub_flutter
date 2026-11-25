import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import 'email_confirmation_success_screen.dart';
import 'gender_onboarding_screen.dart';
import 'main_navigation_screen.dart';
import 'password_recovery_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();
  bool _clearingConfirmationNotice = false;

  Future<void> _continueAfterEmailConfirmation() async {
    if (_clearingConfirmationNotice) return;
    setState(() => _clearingConfirmationNotice = true);
    try {
      await _auth.dismissEmailConfirmationNotice();
    } finally {
      if (mounted) setState(() => _clearingConfirmationNotice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _auth.authChanges,
      builder: (context, snapshot) {
        if (AuthService.isPasswordRecoveryPending ||
            snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return const PasswordRecoveryScreen();
        }

        final user = _auth.currentUser;
        if (user == null) return const WelcomeScreen();

        if (user.userMetadata?['signup_confirmation_pending'] == true) {
          return EmailConfirmationSuccessScreen(
            onContinue: _continueAfterEmailConfirmation,
            busy: _clearingConfirmationNotice,
          );
        }

        return _MemberGenderGate(key: ValueKey(user.id), userId: user.id);
      },
    );
  }
}

class _MemberGenderGate extends StatefulWidget {
  const _MemberGenderGate({super.key, required this.userId});

  final String userId;

  @override
  State<_MemberGenderGate> createState() => _MemberGenderGateState();
}

class _MemberGenderGateState extends State<_MemberGenderGate> {
  late Future<String?> _gender;

  @override
  void initState() {
    super.initState();
    _loadGender();
  }

  void _loadGender() {
    _gender = Supabase.instance.client
        .from('profiles')
        .select('gender')
        .eq('id', widget.userId)
        .maybeSingle()
        .then((row) => row?['gender'] as String?);
  }

  void _completed() {
    setState(_loadGender);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _gender,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${AppStrings.of(context)!.accountDataLoadFailed}: ${snapshot.error}'),
              ),
            ),
          );
        }
        if (snapshot.data != 'male' && snapshot.data != 'female') {
          return GenderOnboardingScreen(onCompleted: _completed);
        }
        return const MainNavigationScreen();
      },
    );
  }
}
