import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
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

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kenza_notifications',
    'Kenza notifications',
    description: 'Messages, offers and purchase updates from Kenza Hub',
    importance: Importance.max,
  );

  final SupabaseClient _client = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || defaultTargetPlatform != TargetPlatform.android) return;
    if (Firebase.apps.isEmpty) return;

    _initialized = true;

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (_) => _openNotifications(),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

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
      final settings = await FirebaseMessaging.instance.requestPermission(
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
    if (_client.auth.currentUser == null || token.isEmpty) return;

    try {
      await _client.rpc(
        'register_device_token',
        params: {
          'p_token': token,
          'p_platform': 'android',
        },
      );
      debugPrint('Kenza Hub FCM device token registered.');
    } catch (error, stackTrace) {
      debugPrint('Could not save the FCM device token in Supabase: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> deactivateCurrentDevice() async {
    if (defaultTargetPlatform != TargetPlatform.android || Firebase.apps.isEmpty) {
      return;
    }

    if (_client.auth.currentUser == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _client.rpc(
        'deactivate_device_token',
        params: {'p_token': token},
      );
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

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title?.trim();
    final body = message.notification?.body?.trim();
    final notificationTitle =
        title == null || title.isEmpty ? 'كنزة هب' : title;
    final notificationBody =
        body == null || body.isEmpty ? 'لديك إشعار جديد' : body;

    final notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    await _localNotifications.show(
      notificationId,
      notificationTitle,
      notificationBody,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kenza_notifications',
          'Kenza notifications',
          channelDescription:
              'Messages, offers and purchase updates from Kenza Hub',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: message.data['notification_id']?.toString(),
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
