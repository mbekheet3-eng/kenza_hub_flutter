/// Application-level constants for Kenza Hub.
final class AppConstants {
  AppConstants._();

  /// Application display name.
  static const String appName = 'Kenza Hub';

  /// Maximum image upload size (in megabytes).
  static const int maxImageUploadInMb = 10;

  /// Maximum image upload size (in bytes).
  static const int maxImageUploadBytes = 10 * 1024 * 1024;

  /// Supported languages mapping (locale code -> language name).
  /// Keep only this until localization setup is finalized.
  static const Map<String, String> supportedLanguages = {
    'ar': 'Arabic',
    'en': 'English',
  };
}
