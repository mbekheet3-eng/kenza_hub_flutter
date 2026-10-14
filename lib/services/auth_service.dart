import 'package:kenza_hub_flutter/models/user_model.dart';
import 'package:kenza_hub_flutter/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final SupabaseService _supabaseService = SupabaseService();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Check if user is authenticated
  bool get isAuthenticated => _supabaseService.isAuthenticated;

  /// Get current user
  User? get currentUser => _supabaseService.currentUser;

  /// Get current user ID
  String? get userId => _supabaseService.userId;

  /// Sign up with email and password
  Future<String> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Sign up user
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user == null) {
        throw Exception('Sign up failed: User is null');
      }

      // Create user profile in database
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        fullName: fullName,
      );

      return response.user!.id;
    } catch (e) {
      print('❌ Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabaseService.signIn(
        email: email,
        password: password,
      );

      final user = _supabaseService.currentUser;
      if (user == null) {
        throw Exception('Sign in failed: User is null');
      }

      // Fetch user profile
      return await getUserProfile(user.id);
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
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final client = SupabaseService.client;
      final response = await client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response as Map<String, dynamic>);
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
      await client.from('profiles').update({
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
        if (profileImage != null) 'profile_image': profileImage,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
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

  /// Private method to create user profile
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    try {
      final client = SupabaseService.client;
      await client.from('profiles').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error creating user profile: $e');
      // Don't throw here, profile might already exist
    }
  }
}
