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
  String get myProductsTitle => _strings.myProductsTitle;
  String get loginToManageProducts => _strings.loginToManageProducts;
  String get addFirstProduct => _strings.addFirstProduct;
  String get pendingReview => _strings.pendingReview;
  String get sold => _strings.sold;
  String get inactive => _strings.inactive;
  String get editProduct => _strings.editProduct;
  String get deleteProduct => _strings.deleteProduct;
  String get editProductInfo => _strings.editProductInfo;
  String get cancel => _strings.cancel;
  String get invalidProductInput => _strings.invalidProductInput;
  String get saveChanges => _strings.saveChanges;
  String get hideProduct => _strings.hideProduct;
  String get confirmHideProduct => _strings.confirmHideProduct;
  String get hide => _strings.hide;
  String get marketplaceProducts => _strings.marketplaceProducts;
  String get latestProducts => _strings.latestProducts;
  String get agencyCorner => _strings.agencyCorner;
  String get onlineStores => _strings.onlineStores;
  String get imagePickGallery => _strings.imagePickGallery;
  String get imageTakeCamera => _strings.imageTakeCamera;
  String get imageSearchComingSoon => _strings.imageSearchComingSoon;
  String get imageOpenError => _strings.imageOpenError;
  String get welcomeGreeting => _strings.welcomeGreeting;
  String get notificationsComingSoon => _strings.notificationsComingSoon;
  String get productCountLabel => _strings.productCountLabel;
  String get categoriesLoadError => _strings.categoriesLoadError;
  String get retry => _strings.retry;
  String get categoriesTitle => _strings.categoriesTitle;
  String get categoriesLoadFailed => _strings.categoriesLoadFailed;
  String get noCategories => _strings.noCategories;
  String get chatsTitle => _strings.chatsTitle;
  String get chatsComingSoon => _strings.chatsComingSoon;
  String get chatsDescription => _strings.chatsDescription;
  String get profileTitle => _strings.profileTitle;
  String get pleaseLogin => _strings.pleaseLogin;
  String get ordersHistory => _strings.ordersHistory;
  String get ordersSubtitle => _strings.ordersSubtitle;
  String get sellerDashboard => _strings.sellerDashboard;
  String get sellerDashboardSubtitle => _strings.sellerDashboardSubtitle;
  String get aboutKenza => _strings.aboutKenza;
  String get aboutKenzaSubtitle => _strings.aboutKenzaSubtitle;
  String get policiesTerms => _strings.policiesTerms;
  String get policiesSubtitle => _strings.policiesSubtitle;
  String get logout => _strings.logout;
  String get userFallback => _strings.userFallback;
  String get followers => _strings.followers;
  String get ratings => _strings.ratings;
  String get edit => _strings.edit;
  String get aboutMe => _strings.aboutMe;
  String get aboutTitle => _strings.aboutTitle;
  String get brandTagline => _strings.brandTagline;
  String get brandSubtitle => _strings.brandSubtitle;
  String get ideaTitle => _strings.ideaTitle;
  String get ideaBody => _strings.ideaBody;
  String get whatYouFindTitle => _strings.whatYouFindTitle;
  String get whatYouFindBody => _strings.whatYouFindBody;
  String get howItWorksTitle => _strings.howItWorksTitle;
  String get howItWorksBody => _strings.howItWorksBody;
  String get missionTitle => _strings.missionTitle;
  String get missionBody => _strings.missionBody;
  String get aboutThanks => _strings.aboutThanks;
  String get copyright => _strings.copyright;
  String get policiesTitle => _strings.policiesTitle;
  String get policiesIntroTitle => _strings.policiesIntroTitle;
  String get policiesIntro => _strings.policiesIntro;
  String get policiesDraftNotice => _strings.policiesDraftNotice;
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
