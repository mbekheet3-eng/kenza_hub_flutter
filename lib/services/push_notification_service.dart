import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../screens/notifications_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || defaultTargetPlatform != TargetPlatform.android) return;
    if (Firebase.apps.isEmpty) return;

    _initialized = true;
    _authSubscription = _client.auth.onAuthStateChange.listen((state) {
      if (state.session != null) {
        unawaited(_requestPermissionAndRegister());
      }
    });

    _tokenSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_saveToken(token));
    });

    _openedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());

    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen(_showForegroundMessage);

    if (_client.auth.currentUser != null) {
      await _requestPermissionAndRegister();
    }

    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNotifications();
      });
    }
  }

  Future<void> _requestPermissionAndRegister() async {
    try {
      final settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Kenza Hub push notifications permission was denied.');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }
    } catch (error, stackTrace) {
      debugPrint('Could not register the FCM device token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || token.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': 'android',
          'is_active': true,
          'updated_at': now,
          'last_seen_at': now,
        },
        onConflict: 'token',
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save the FCM device token in Supabase: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> deactivateCurrentDevice() async {
    if (defaultTargetPlatform != TargetPlatform.android || Firebase.apps.isEmpty) {
      return;
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _client
          .from('device_tokens')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('token', token);
    } catch (error, stackTrace) {
      // Do not block sign-out if FCM is temporarily unavailable.
      debugPrint('Could not deactivate the FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _foregroundSubscription?.cancel();
  }

  void _showForegroundMessage(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title;
    final body = message.notification?.body;
    final content = [title, body]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' — ');

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(content.isEmpty ? AppStrings.of(context)!.newNotification : content),
        action: SnackBarAction(
          label: AppStrings.of(context)!.viewNotification,
          onPressed: _openNotifications,
        ),
      ),
    );
  }

  void _openNotifications() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }
}
