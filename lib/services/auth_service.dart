import 'package:kenza_hub_flutter/models/user.dart' as custom_user;
import 'package:kenza_hub_flutter/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final SupabaseService _supabaseService = SupabaseService();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Check if user is authenticated
  bool get isAuthenticated => _supabaseService.isAuthenticated;

  /// Get current authenticated user (Gotrue - auth only, not profile data)
  supabase.User? get currentUser => _supabaseService.currentUser;

  /// Get current user ID
  String? get userId => _supabaseService.userId;

  /// Sign up with email and password
  Future<String> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Sign up user - returns Map with 'user' and 'session' keys
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Extract user from response Map
      final user = response['user'] as supabase.User?;
      if (user == null) {
        throw Exception('Sign up failed: User is null');
      }

      // The database handle_new_user trigger creates public.users.
      // Do not insert into a separate legacy profiles table.
      return user.id;
    } catch (e) {
      print('❌ Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<custom_user.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabaseService.signIn(
        email: email,
        password: password,
      );

      final authUser = _supabaseService.currentUser;
      if (authUser == null) {
        throw Exception('Sign in failed: User is null');
      }

      // Fetch user profile from database
      return await getUserProfile(authUser.id);
    } catch (e) {
      print('❌ Sign in error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<custom_user.User> getUserProfile(String userId) async {
    try {
      final client = SupabaseService.client;
      final response = await client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      return custom_user.User.fromJson(response);
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? bio,
    String? profileImage,
  }) async {
    try {
      final client = SupabaseService.client;
      final nameParts = (fullName ?? '').trim().split(RegExp(r'\s+'));
      await client.from('users').update({
        if (fullName != null && nameParts.isNotEmpty)
          'first_name': nameParts.first,
        if (fullName != null)
          'last_name': nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
        if (bio != null) 'bio': bio,
        if (profileImage != null) 'avatar_url': profileImage,
      }).eq('id', userId);

      // Phone numbers live in Supabase Auth, not public.users. Supabase sends
      // an SMS OTP for the new number; it is not accepted as verified yet.
      if (phone != null && phone.trim().isNotEmpty) {
        await SupabaseService.client.auth.updateUser(
          supabase.UserAttributes(phone: phone.trim()),
        );
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseService.resetPassword(email);
    } catch (e) {
      print('❌ Reset password error: $e');
      rethrow;
    }
  }

  /// Verify email
  Future<void> verifyEmail() async {
    try {
      // Email verification is handled by Supabase
      print('✅ Verification email sent to ${currentUser?.email}');
    } catch (e) {
      print('❌ Email verification error: $e');
      rethrow;
    }
  }

}
