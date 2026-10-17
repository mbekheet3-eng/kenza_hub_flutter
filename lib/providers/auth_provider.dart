import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  // State
  bool _isLoading = false;
  String? _error;
  User? _currentUser;
  bool _isSignedIn = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  bool get isSignedIn => _isSignedIn;
  String? get userEmail => _currentUser?.email;
  String? get userId => _currentUser?.id;

  // Constructor
  AuthProvider() {
    _checkCurrentUser();
  }

  // Check if user is already signed in
  void _checkCurrentUser() {
    _currentUser = SupabaseService.client.auth.currentUser;
    _isSignedIn = _currentUser != null;
    notifyListeners();
  }

  // Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      _currentUser = response['user'];
      _isSignedIn = _currentUser != null;
      _isLoading = false;

      print('✅ Sign up successful');
    } catch (e) {
      _isLoading = false;
      _error = 'خطأ في التسجيل: ${_parseError(e.toString())}';
      print('❌ Sign up error: $e');
    }
    notifyListeners();
    return _isSignedIn;
  }

  // Sign In
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      _currentUser = response['user'];
      _isSignedIn = _currentUser != null;
      _isLoading = false;

      print('✅ Sign in successful');
    } catch (e) {
      _isLoading = false;
      _error = 'خطأ في تسجيل الدخول: ${_parseError(e.toString())}';
      print('❌ Sign in error: $e');
    }
    notifyListeners();
    return _isSignedIn;
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabaseService.signOut();

      _currentUser = null;
      _isSignedIn = false;
      _error = null;
      _isLoading = false;

      print('✅ Sign out successful');
    } catch (e) {
      _isLoading = false;
      _error = 'خطأ في تسجيل الخروج: ${_parseError(e.toString())}';
      print('❌ Sign out error: $e');
    }
    notifyListeners();
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabaseService.resetPassword(email);

      _isLoading = false;
      _error = null;

      print('✅ Reset password email sent');
    } catch (e) {
      _isLoading = false;
      _error = 'خطأ: ${_parseError(e.toString())}';
      print('❌ Reset password error: $e');
    }
    notifyListeners();
    return _error == null;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Parse error message
  String _parseError(String error) {
    if (error.contains('Email already exists')) {
      return 'البريد الإلكتروني مسجل بالفعل';
    } else if (error.contains('Invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    } else if (error.contains('User already exists')) {
      return 'المستخدم موجود بالفعل';
    } else if (error.contains('Password should be at least 6 characters')) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return error.split('Exception: ').last;
  }
}
