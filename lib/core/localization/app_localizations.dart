import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kenza_hub_flutter/l10n/app_strings.dart';

/// Backwards-compatible facade over Flutter's generated ARB localizations.
/// Keep locale persistence and existing call sites stable while screens migrate.
class AppLocalizations {
  final Locale locale;
  late final AppStrings _strings = AppStrings(locale);

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(const Locale('ar'));

  static const String _localePreferenceKey = 'kenza_hub_locale';

  static Locale get currentLocale => localeNotifier.value;

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_localePreferenceKey);
    if (savedLanguage != null) {
      setLocale(savedLanguage, persist: false);
    } else {
      final deviceLanguage =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      setLocale(deviceLanguage, persist: false);
    }
  }

  static void setLocale(String languageCode, {bool persist = true}) {
    final locale = supportedLocales.firstWhere(
      (supportedLocale) => supportedLocale.languageCode == languageCode,
      orElse: () => const Locale('ar'),
    );

    if (localeNotifier.value.languageCode != locale.languageCode) {
      localeNotifier.value = locale;
    }
    if (persist) {
      SharedPreferences.getInstance().then(
        (preferences) => preferences.setString(
          _localePreferenceKey,
          locale.languageCode,
        ),
      );
    }
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (localizations == null) {
      throw FlutterError(
        'AppLocalizations could not be found in the widget tree.',
      );
    }
    return localizations;
  }

  static AppLocalizations safeOf(BuildContext context) {
    try {
      return of(context);
    } catch (_) {
      return AppLocalizations(currentLocale);
    }
  }

  bool get isArabic => locale.languageCode == 'ar';
  String get languageName => _strings.languageName;
  String get welcomeTitle => _strings.welcomeTitle;
  String get welcomeSubtitle => _strings.welcomeSubtitle;
  String get signUp => _strings.signUp;
  String get login => _strings.login;
  String get enter => _strings.enter;
  String get continueAsGuest => _strings.continueAsGuest;
  String get email => _strings.email;
  String get password => _strings.password;
  String get aboutUs => _strings.aboutUs;
  String get termsAndConditions => _strings.termsAndConditions;
  String get privacyPolicy => _strings.privacyPolicy;
  String get loginTitle => _strings.loginTitle;
  String get welcomeBack => _strings.welcomeBack;
  String get loginSubtitle => _strings.loginSubtitle;
  String get noAccount => _strings.noAccount;
  String get fullName => _strings.fullName;
  String get signupTitle => _strings.signupTitle;
  String get joinUs => _strings.joinUs;
  String get signupSubtitle => _strings.signupSubtitle;
  String get confirmPassword => _strings.confirmPassword;
  String get agreeToTerms => _strings.agreeToTerms;
  String get haveAccount => _strings.haveAccount;
  String get categories => _strings.categories;
  String get trendingProducts => _strings.trendingProducts;
  String get viewAll => _strings.viewAll;
  String get sellNow => _strings.sellNow;
  String get searchProduct => _strings.searchProduct;
  String get clothes => _strings.clothes;
  String get shoes => _strings.shoes;
  String get kids => _strings.kids;
  String get home => _strings.home;
  String get error => _strings.error;
  String get noProducts => _strings.noProducts;
  String get oldClothes => _strings.oldClothes;
  String get sellAndEarn => _strings.sellAndEarn;
  String get startSelling => _strings.startSelling;
  String get currency => _strings.currency;
  String get forgotPassword => _strings.forgotPassword;
  String get resetPasswordTitle => _strings.resetPasswordTitle;
  String get resetPasswordSubtitle => _strings.resetPasswordSubtitle;
  String get sendResetLink => _strings.sendResetLink;
  String get resetEmailSent => _strings.resetEmailSent;
  String get backToLogin => _strings.backToLogin;
  String get invalidEmail => _strings.invalidEmail;
  String get emailRequired => _strings.emailRequired;
  String get currentLanguage => _strings.languageName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
