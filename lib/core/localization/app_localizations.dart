import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(const Locale('ar'));

  static Locale get currentLocale => localeNotifier.value;

  static void setLocale(String languageCode) {
    final locale = supportedLocales.firstWhere(
      (supportedLocale) =>
          supportedLocale.languageCode == languageCode,
      orElse: () => const Locale('ar'),
    );

    if (localeNotifier.value.languageCode != locale.languageCode) {
      localeNotifier.value = locale;
    }
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    if (localizations == null) {
      throw FlutterError(
        'AppLocalizations could not be found in the widget tree.',
      );
    }

    return localizations;
  }

  bool get isArabic => locale.languageCode == 'ar';

  String get languageName {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'ar':
      default:
        return 'العربية';
    }
  }

  String get currentLanguage => languageName;

  String get welcomeTitle {
    switch (locale.languageCode) {
      case 'en':
        return "If you don't need it...\nsomeone else does";
      case 'fr':
        return "Si vous n'en avez plus besoin...\nquelqu'un d'autre en a besoin";
      case 'ar':
      default:
        return 'لو مش محتاجها...\nغيرك محتاجها';
    }
  }

  String get welcomeSubtitle {
    switch (locale.languageCode) {
      case 'en':
        return 'Buy and sell easily with no commission';
      case 'fr':
        return 'Achetez et vendez facilement sans commission';
      case 'ar':
      default:
        return 'بيع واشتري بسهولة من غير عمولة';
    }
  }

  String get signUp {
    switch (locale.languageCode) {
      case 'en':
        return 'Sign Up';
      case 'fr':
        return 'Créer un compte';
      case 'ar':
      default:
        return 'إنشاء حساب';
    }
  }

  String get login {
    switch (locale.languageCode) {
      case 'en':
        return 'Log In';
      case 'fr':
        return 'Se connecter';
      case 'ar':
      default:
        return 'تسجيل الدخول';
    }
  }

  String get enter {
    switch (locale.languageCode) {
      case 'en':
        return 'Log In';
      case 'fr':
        return 'Connexion';
      case 'ar':
      default:
        return 'دخول';
    }
  }

  String get continueAsGuest {
    switch (locale.languageCode) {
      case 'en':
        return 'Continue as Guest';
      case 'fr':
        return 'Continuer en tant qu’invité';
      case 'ar':
      default:
        return 'التصفح كزائر';
    }
  }

  String get email {
    switch (locale.languageCode) {
      case 'en':
        return 'Email';
      case 'fr':
        return 'E-mail';
      case 'ar':
      default:
        return 'البريد الإلكتروني';
    }
  }

  String get password {
    switch (locale.languageCode) {
      case 'en':
        return 'Password';
      case 'fr':
        return 'Mot de passe';
      case 'ar':
      default:
        return 'كلمة المرور';
    }
  }

  String get aboutUs {
    switch (locale.languageCode) {
      case 'en':
        return 'About Us';
      case 'fr':
        return 'À propos de nous';
      case 'ar':
      default:
        return 'من نحن';
    }
  }

  String get termsAndConditions {
    switch (locale.languageCode) {
      case 'en':
        return 'Terms & Conditions';
      case 'fr':
        return 'Conditions générales';
      case 'ar':
      default:
        return 'الشروط والأحكام';
    }
  }

  String get privacyPolicy {
    switch (locale.languageCode) {
      case 'en':
        return 'Privacy Policy';
      case 'fr':
        return 'Politique de confidentialité';
      case 'ar':
      default:
        return 'سياسة الخصوصية';
    }
  }

  String get loginTitle {
    switch (locale.languageCode) {
      case 'en':
        return 'Log In';
      case 'fr':
        return 'Se connecter';
      case 'ar':
      default:
        return 'تسجيل الدخول';
    }
  }

  String get welcomeBack {
    switch (locale.languageCode) {
      case 'en':
        return 'Welcome back';
      case 'fr':
        return 'Bon retour';
      case 'ar':
      default:
        return 'مرحباً بعودتك';
    }
  }

  String get loginSubtitle {
    switch (locale.languageCode) {
      case 'en':
        return 'Log in to your account to continue';
      case 'fr':
        return 'Connectez-vous à votre compte pour continuer';
      case 'ar':
      default:
        return 'سجل دخول لحسابك للاستمرار';
    }
  }

  String get noAccount {
    switch (locale.languageCode) {
      case 'en':
        return "Don't have an account? ";
      case 'fr':
        return "Vous n'avez pas de compte ? ";
      case 'ar':
      default:
        return 'ليس لديك حساب؟ ';
    }
  }

  String get fullName {
    switch (locale.languageCode) {
      case 'en':
        return 'Full Name';
      case 'fr':
        return 'Nom complet';
      case 'ar':
      default:
        return 'الاسم الكامل';
    }
  }

  String get signupTitle {
    switch (locale.languageCode) {
      case 'en':
        return 'Sign Up';
      case 'fr':
        return 'Créer un compte';
      case 'ar':
      default:
        return 'إنشاء حساب';
    }
  }

  String get joinUs {
    switch (locale.languageCode) {
      case 'en':
        return 'Join us now';
      case 'fr':
        return 'Rejoignez-nous maintenant';
      case 'ar':
      default:
        return 'انضم إلينا الآن';
    }
  }

  String get signupSubtitle {
    switch (locale.languageCode) {
      case 'en':
        return 'Create your account to start buying and selling';
      case 'fr':
        return 'Créez votre compte pour commencer à acheter et vendre';
      case 'ar':
      default:
        return 'أنشئ حسابك للبدء في البيع والشراء';
    }
  }

  String get confirmPassword {
    switch (locale.languageCode) {
      case 'en':
        return 'Confirm Password';
      case 'fr':
        return 'Confirmer le mot de passe';
      case 'ar':
      default:
        return 'تأكيد كلمة المرور';
    }
  }

  String get agreeToTerms {
    switch (locale.languageCode) {
      case 'en':
        return 'I agree to the Terms of Service and Privacy Policy';
      case 'fr':
        return "J'accepte les conditions d'utilisation et la politique de confidentialité";
      case 'ar':
      default:
        return 'أوافق على شروط الخدمة والسياسة';
    }
  }

  String get haveAccount {
    switch (locale.languageCode) {
      case 'en':
        return 'Already have an account? ';
      case 'fr':
        return 'Vous avez déjà un compte ? ';
      case 'ar':
      default:
        return 'لديك حساب بالفعل؟ ';
    }
  }

  String get categories {
    switch (locale.languageCode) {
      case 'en':
        return 'Categories';
      case 'fr':
        return 'Catégories';
      case 'ar':
      default:
        return 'الفئات';
    }
  }

  String get trendingProducts {
    switch (locale.languageCode) {
      case 'en':
        return 'Trending Products';
      case 'fr':
        return 'Produits tendance';
      case 'ar':
      default:
        return 'المنتجات الرائجة';
    }
  }

  String get viewAll {
    switch (locale.languageCode) {
      case 'en':
        return 'View All';
      case 'fr':
        return 'Voir tout';
      case 'ar':
      default:
        return 'عرض الكل';
    }
  }

  String get sellNow {
    switch (locale.languageCode) {
      case 'en':
        return 'Sell Now';
      case 'fr':
        return 'Vendre maintenant';
      case 'ar':
      default:
        return 'بيع الآن';
    }
  }

  String get searchProduct {
    switch (locale.languageCode) {
      case 'en':
        return 'Search for a product...';
      case 'fr':
        return 'Rechercher un produit...';
      case 'ar':
      default:
        return 'ابحث عن منتج...';
    }
  }

  String get clothes {
    switch (locale.languageCode) {
      case 'en':
        return 'Clothes';
      case 'fr':
        return 'Vêtements';
      case 'ar':
      default:
        return 'ملابس';
    }
  }

  String get shoes {
    switch (locale.languageCode) {
      case 'en':
        return 'Shoes';
      case 'fr':
        return 'Chaussures';
      case 'ar':
      default:
        return 'أحذية';
    }
  }

  String get kids {
    switch (locale.languageCode) {
      case 'en':
        return 'Kids Clothes';
      case 'fr':
        return 'Vêtements enfants';
      case 'ar':
      default:
        return 'ملابس أطفال';
    }
  }

  String get home {
    switch (locale.languageCode) {
      case 'en':
        return 'Home';
      case 'fr':
        return 'Maison';
      case 'ar':
      default:
        return 'منزل';
    }
  }

  String get error {
    switch (locale.languageCode) {
      case 'en':
        return 'Error';
      case 'fr':
        return 'Erreur';
      case 'ar':
      default:
        return 'خطأ';
    }
  }

  String get noProducts {
    switch (locale.languageCode) {
      case 'en':
        return 'No products available';
      case 'fr':
        return 'Aucun produit disponible';
      case 'ar':
      default:
        return 'لا توجد منتجات';
    }
  }

  String get oldClothes {
    switch (locale.languageCode) {
      case 'en':
        return 'Have old clothes?';
      case 'fr':
        return 'Vous avez des vêtements anciens ?';
      case 'ar':
      default:
        return 'هل لديك ملابس قديمة؟';
    }
  }

  String get sellAndEarn {
    switch (locale.languageCode) {
      case 'en':
        return 'Sell your clothes easily and earn money';
      case 'fr':
        return 'Vendez vos vêtements facilement et gagnez de l’argent';
      case 'ar':
      default:
        return 'بيع ملابسك بسهولة واربح أموالاً';
    }
  }

  String get startSelling {
    switch (locale.languageCode) {
      case 'en':
        return 'Start Selling Now';
      case 'fr':
        return 'Commencer à vendre';
      case 'ar':
      default:
        return 'ابدأ البيع الآن';
    }
  }

  String get currency {
    switch (locale.languageCode) {
      case 'en':
        return 'EGP';
      case 'fr':
        return 'EGP';
      case 'ar':
      default:
        return 'ج.م';
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) =>
          supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
