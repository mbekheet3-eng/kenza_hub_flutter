import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  static const ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(Locale('ar'));

  static AppLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppLocalizations(locale);
  }

  static void setLocale(String languageCode) {
    localeNotifier.value = Locale(languageCode);
  }

  bool get isArabic => locale.languageCode == 'ar';

  String get languageName {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      default:
        return 'العربية';
    }
  }

  String get welcomeTitle {
    switch (locale.languageCode) {
      case 'en':
        return 'If you don’t need it...\nSomeone else does';
      case 'fr':
        return 'Si vous n’en avez pas besoin...\nquelqu’un d’autre en a besoin';
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
      default:
        return 'بيع واشتري بسهولة من غير عمولة';
    }
  }

  String get signUp {
    switch (locale.languageCode) {
      case 'en':
        return 'Create account';
      case 'fr':
        return 'Créer un compte';
      default:
        return 'إنشاء حساب';
    }
  }

  String get login {
    switch (locale.languageCode) {
      case 'en':
        return 'Log in';
      case 'fr':
        return 'Se connecter';
      default:
        return 'تسجيل الدخول';
    }
  }

  String get guest {
    switch (locale.languageCode) {
      case 'en':
        return 'Browse as guest';
      case 'fr':
        return 'Continuer en invité';
      default:
        return 'التصفح كزائر';
    }
  }

  String get aboutUs {
    switch (locale.languageCode) {
      case 'en':
        return 'About us';
      case 'fr':
        return 'À propos';
      default:
        return 'من نحن';
    }
  }

  String get terms {
    switch (locale.languageCode) {
      case 'en':
        return 'Terms & Conditions';
      case 'fr':
        return 'Conditions générales';
      default:
        return 'الشروط والأحكام';
    }
  }

  String get privacy {
    switch (locale.languageCode) {
      case 'en':
        return 'Privacy Policy';
      case 'fr':
        return 'Politique de confidentialité';
      default:
        return 'سياسة الخصوصية';
    }
  }

  String get email {
    switch (locale.languageCode) {
      case 'en':
        return 'Email';
      case 'fr':
        return 'E-mail';
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
      default:
        return 'كلمة المرور';
    }
  }

  String get enter {
    switch (locale.languageCode) {
      case 'en':
        return 'Log in';
      case 'fr':
        return 'Connexion';
      default:
        return 'دخول';
    }
  }
}