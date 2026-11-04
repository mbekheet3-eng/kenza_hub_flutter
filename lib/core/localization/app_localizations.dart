import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      (supportedLocale) =>
          supportedLocale.languageCode == languageCode,
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

  /// Safe version of of() that returns a default instance if not found
  static AppLocalizations safeOf(BuildContext context) {
    try {
      return of(context);
    } catch (_) {
      return AppLocalizations(currentLocale);
    }
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
        return 'Join us and sell\\nwith no fees';
      case 'fr':
        return 'Rejoignez-nous et vendez\\nsans frais';
      case 'ar':
      default:
        return 'لو مش محتاجها...\\nغيرك محتاجها';
    }
  }

  String get welcomeSubtitle {
    switch (locale.languageCode) {
      case 'en':
      case 'fr':
        return '';
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
        return 'Children’s Supplies';
      case 'fr':
        return 'Articles pour enfants';
      case 'ar':
      default:
        return 'مستلزمات أطفال';
    }
  }

  String get home {
    switch (locale.languageCode) {
      case 'en':
        return 'Home Supplies';
      case 'fr':
        return 'Articles pour la maison';
      case 'ar':
      default:
        return 'مستلزمات المنزل';
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
        return 'Have items you no longer need?';
      case 'fr':
        return 'Vous avez des articles dont vous n’avez plus besoin ?';
      case 'ar':
      default:
        return 'عندك حاجات مش محتاجها؟';
    }
  }

  String get sellAndEarn {
    switch (locale.languageCode) {
      case 'en':
        return 'Sell what you no longer need easily';
      case 'fr':
        return 'Vendez facilement ce dont vous n’avez plus besoin';
      case 'ar':
      default:
        return 'بيع الحاجات اللي مش محتاجها بسهولة';
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

  String get forgotPassword {
    switch (locale.languageCode) {
      case 'en': return 'Forgot password?';
      case 'fr': return 'Mot de passe oublié ?';
      case 'ar':
      default: return 'هل نسيت كلمة المرور؟';
    }
  }

  String get resetPasswordTitle {
    switch (locale.languageCode) {
      case 'en': return 'Reset password';
      case 'fr': return 'Réinitialiser le mot de passe';
      case 'ar':
      default: return 'استعادة كلمة المرور';
    }
  }

  String get resetPasswordSubtitle {
    switch (locale.languageCode) {
      case 'en': return 'Enter your email and we will send you a password reset link.';
      case 'fr': return 'Saisissez votre e-mail pour recevoir un lien de réinitialisation.';
      case 'ar':
      default: return 'اكتب بريدك الإلكتروني وسنرسل لك رابطًا لاستعادة كلمة المرور.';
    }
  }

  String get sendResetLink {
    switch (locale.languageCode) {
      case 'en': return 'Send reset link';
      case 'fr': return 'Envoyer le lien';
      case 'ar':
      default: return 'إرسال رابط الاستعادة';
    }
  }

  String get resetEmailSent {
    switch (locale.languageCode) {
      case 'en': return 'If this email is registered, a password reset link has been sent.';
      case 'fr': return 'Si cette adresse est enregistrée, un lien de réinitialisation a été envoyé.';
      case 'ar':
      default: return 'إذا كان البريد مسجلاً، فسيصلك رابط استعادة كلمة المرور.';
    }
  }

  String get backToLogin {
    switch (locale.languageCode) {
      case 'en': return 'Back to log in';
      case 'fr': return 'Retour à la connexion';
      case 'ar':
      default: return 'العودة لتسجيل الدخول';
    }
  }

  String get invalidEmail {
    switch (locale.languageCode) {
      case 'en': return 'Enter a valid email address';
      case 'fr': return 'Saisissez une adresse e-mail valide';
      case 'ar':
      default: return 'أدخل بريدًا إلكترونيًا صحيحًا';
    }
  }

  String get emailRequired {
    switch (locale.languageCode) {
      case 'en': return 'Email is required';
      case 'fr': return 'L’adresse e-mail est obligatoire';
      case 'ar':
      default: return 'البريد الإلكتروني مطلوب';
    }
  }


  String get passwordRequired => _localized(
        'Password is required',
        'Le mot de passe est obligatoire',
        'كلمة المرور مطلوبة',
      );

  String get passwordMinLength => _localized(
        'Password must be at least 6 characters',
        'Le mot de passe doit contenir au moins 6 caractères',
        'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      );

  String get nameRequired => _localized(
        'Full name is required',
        'Le nom complet est obligatoire',
        'الاسم الكامل مطلوب',
      );

  String get nameMinLength => _localized(
        'Name must be at least 3 characters',
        'Le nom doit contenir au moins 3 caractères',
        'الاسم يجب أن يكون 3 أحرف على الأقل',
      );

  String get confirmPasswordRequired => _localized(
        'Please confirm your password',
        'Veuillez confirmer votre mot de passe',
        'تأكيد كلمة المرور مطلوب',
      );

  String get passwordsDoNotMatch => _localized(
        'Passwords do not match',
        'Les mots de passe ne correspondent pas',
        'كلمات المرور غير متطابقة',
      );

  String get termsRequired => _localized(
        'You must agree to the terms and conditions',
        'Vous devez accepter les conditions générales',
        'يجب أن توافق على الشروط والأحكام',
      );

  String get continueWithGoogle => _localized(
        'Continue with Google',
        'Continuer avec Google',
        'المتابعة باستخدام Google',
      );

  String get continueWithApple => _localized(
        'Continue with Apple',
        'Continuer avec Apple',
        'المتابعة باستخدام Apple',
      );

  String get or => _localized('OR', 'OU', 'أو');

  String get newPasswordTitle => _localized(
        'Create a new password',
        'Créer un nouveau mot de passe',
        'إنشاء كلمة مرور جديدة',
      );

  String get updatePassword => _localized(
        'Update password',
        'Mettre à jour le mot de passe',
        'تحديث كلمة المرور',
      );

  String get passwordUpdated => _localized(
        'Your password has been updated successfully',
        'Votre mot de passe a été mis à jour',
        'تم تحديث كلمة المرور بنجاح',
      );

  String get tryChangeFilters => _localized(
        'Try changing your filters or search',
        'Essayez de modifier les filtres ou la recherche',
        'حاول تغيير المرشحات أو البحث',
      );

  String get clearFilters => _localized(
        'Clear filters',
        'Effacer les filtres',
        'إزالة المرشحات',
      );

  String get tryAgain => _localized(
        'Try again',
        'Réessayer',
        'حاول مجدداً',
      );

  String get available => _localized(
        'Available',
        'Disponible',
        'متوفر',
      );

  String get soldOut => _localized(
        'Unavailable',
        'Indisponible',
        'غير متوفر',
      );

  String _localized(String english, String french, String arabic) {
    switch (locale.languageCode) {
      case 'en':
        return english;
      case 'fr':
        return french;
      case 'ar':
      default:
        return arabic;
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