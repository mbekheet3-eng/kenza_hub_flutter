import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Supabase
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  // App
  static String get appName => dotenv.get('APP_NAME', fallback: 'كينزا هب');
  static String get appVersion => dotenv.get('APP_VERSION', fallback: '1.0.0');
  static bool get debugMode => dotenv.get('DEBUG', fallback: 'true').toLowerCase() == 'true';

  // API
  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: 'https://api.example.com');
  static int get imageUploadTimeout => int.parse(dotenv.get('IMAGE_UPLOAD_TIMEOUT', fallback: '30000'));

  // Features
  static bool get enableAnalytics => dotenv.get('ENABLE_ANALYTICS', fallback: 'true').toLowerCase() == 'true';
  static bool get enablePushNotifications => dotenv.get('ENABLE_PUSH_NOTIFICATIONS', fallback: 'false').toLowerCase() == 'true';
  static bool get enablePayment => dotenv.get('ENABLE_PAYMENT', fallback: 'false').toLowerCase() == 'true';

  // Validation
  static bool isConfigured() {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  static void debugPrint() {
    if (debugMode) {
      print('=== Kenza Hub Config ===');
      print('App: $appName v$appVersion');
      print('Supabase URL: $supabaseUrl');
      print('Debug Mode: $debugMode');
      print('Features: Analytics=$enableAnalytics, Push=$enablePushNotifications, Payment=$enablePayment');
      print('========================');
    }
  }
}
