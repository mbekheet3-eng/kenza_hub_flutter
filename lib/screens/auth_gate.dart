import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import 'gender_onboarding_screen.dart';
import 'main_navigation_screen.dart';
import 'password_recovery_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<AuthState>(
      stream: auth.authChanges,
      builder: (context, snapshot) {
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return const PasswordRecoveryScreen();
        }

        final userId = auth.currentUser?.id;
        if (userId == null) return const WelcomeScreen();

        return _MemberGenderGate(key: ValueKey(userId), userId: userId);
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
