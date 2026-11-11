import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_notification_service.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  static const _authRedirectUrl = 'com.kenza.hub://login-callback/';

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
    required String gender,
  }) async {
    if (gender != 'male' && gender != 'female') {
      throw ArgumentError('يجب اختيار النوع');
    }
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: _authRedirectUrl,
      data: {'display_name': displayName.trim(), 'gender': gender},
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _authRedirectUrl,
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: _authRedirectUrl,
    );
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _authRedirectUrl,
    );
  }

  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> updateDisplayName(String displayName) async {
    await _client.auth.updateUser(
      UserAttributes(data: {'display_name': displayName.trim()}),
    );
  }

  Future<void> signOut() async {
    await PushNotificationService.instance.deactivateCurrentDevice();
    await _client.auth.signOut();
  }
}
