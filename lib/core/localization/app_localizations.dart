import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kenza_hub_flutter/l10n/app_strings.dart';

/// Compatibility facade backed by Flutter gen_l10n and ARB resources.
class AppLocalizations {
  final Locale locale;
  late final AppStrings _strings = AppStrings(locale.languageCode);
  AppLocalizations(this.locale);

  static const supportedLocales = [Locale('ar'), Locale('en'), Locale('fr')];
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
      (item) => item.languageCode == languageCode,
      orElse: () => const Locale('ar'),
    );
    if (localeNotifier.value.languageCode != locale.languageCode) {
      localeNotifier.value = locale;
    }
    if (persist) {
      SharedPreferences.getInstance().then((preferences) =>
          preferences.setString(_localePreferenceKey, locale.languageCode));
    }
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (value == null) {
      throw FlutterError('AppLocalizations could not be found in the widget tree.');
    }
    return value;
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
  String get notificationsTooltip => _strings.notificationsTooltip;
  String get cartTitle => _strings.cartTitle;
  String get cartEmpty => _strings.cartEmpty;
  String get searchProducts => _strings.searchProducts;
  String get singleItem => _strings.singleItem;
  String get subtotal => _strings.subtotal;
  String get shippingLabel => _strings.shippingLabel;
  String get shippingCalculated => _strings.shippingCalculated;
  String get itemsTotal => _strings.itemsTotal;
  String get shippingDisclaimer => _strings.shippingDisclaimer;
  String get checkout => _strings.checkout;
  String get continueShopping => _strings.continueShopping;
  String get clearCart => _strings.clearCart;
  String get confirmClearCart => _strings.confirmClearCart;
  String get cartCleared => _strings.cartCleared;
  String get clear => _strings.clear;
  String get checkoutTitle => _strings.checkoutTitle;
  String get loginToContinuePurchase => _strings.loginToContinuePurchase;
  String get confirmOrder => _strings.confirmOrder;
  String get orderConfirmUnavailable => _strings.orderConfirmUnavailable;
  String get secureOrderNotice => _strings.secureOrderNotice;
  String get backToCart => _strings.backToCart;
  String get orderSummary => _strings.orderSummary;
  String get shippingOnAgreement => _strings.shippingOnAgreement;
  String get total => _strings.total;
  String get deliveryAddress => _strings.deliveryAddress;
  String get noSavedAddresses => _strings.noSavedAddresses;
  String get defaultAddress => _strings.defaultAddress;
  String get paymentMethod => _strings.paymentMethod;
  String get cashOnDelivery => _strings.cashOnDelivery;
  String get noOrderCreatedNotice => _strings.noOrderCreatedNotice;
  String get backToHome => _strings.backToHome;
  String get loginToViewOrders => _strings.loginToViewOrders;
  String get noOrders => _strings.noOrders;
  String get orderPrefix => _strings.orderPrefix;
  String get dateLabel => _strings.dateLabel;
  String get amountLabel => _strings.amountLabel;
  String get orderDetails => _strings.orderDetails;
  String get disputeEvidenceLabel => _strings.disputeEvidenceLabel;
  String get trackingTitle => _strings.trackingTitle;
  String get orderNotFound => _strings.orderNotFound;
  String get trackingIntro => _strings.trackingIntro;
  String get reload => _strings.reload;
  String get orderNumber => _strings.orderNumber;
  String get orderDate => _strings.orderDate;
  String get progress => _strings.progress;
  String get progressComplete => _strings.progressComplete;
  String get orderStatus => _strings.orderStatus;
  String get noUpdates => _strings.noUpdates;
  String get updatedDate => _strings.updatedDate;
  String get notes => _strings.notes;
  String get somethingWentWrong => _strings.somethingWentWrong;
  String get tryAgain => _strings.tryAgain;
  String get initializationError => _strings.initializationError;
  String get initializationRetryHint => _strings.initializationRetryHint;
  String get loginToFavorite => _strings.loginToFavorite;
  String get favoriteUpdateError => _strings.favoriteUpdateError;
  String get loginToBuy => _strings.loginToBuy;
  String get productUnavailable => _strings.productUnavailable;
  String get ownProductCannotBuy => _strings.ownProductCannotBuy;
  String get proSellerCartOnly => _strings.proSellerCartOnly;
  String get productDetailsTitle => _strings.productDetailsTitle;
  String get addToCart => _strings.addToCart;
  String get buyNow => _strings.buyNow;
  String get description => _strings.description;
  String get details => _strings.details;
  String get seller => _strings.seller;
  String get productLoadError => _strings.productLoadError;
  String get brandLabel => _strings.brandLabel;
  String get colorLabel => _strings.colorLabel;
  String get sizeLabel => _strings.sizeLabel;
  String get conditionLabel => _strings.conditionLabel;
  String get unspecified => _strings.unspecified;
  String get newCondition => _strings.newCondition;
  String get sellerOnKenza => _strings.sellerOnKenza;
  String get productAddedToCart => _strings.productAddedToCart;
  String get alreadyInCart => _strings.alreadyInCart;
  String get discover => _strings.discover;
  String get productsCount => _strings.productsCount;
  String get clearFilters => _strings.clearFilters;
  String get discoverDresses => _strings.discoverDresses;
  String get advancedFilters => _strings.advancedFilters;
  String get newest => _strings.newest;
  String get priceLowToHigh => _strings.priceLowToHigh;
  String get priceHighToLow => _strings.priceHighToLow;
  String get mostViewed => _strings.mostViewed;
  String get searchLoadError => _strings.searchLoadError;
  String get noSearchResults => _strings.noSearchResults;
  String get changeFilters => _strings.changeFilters;
  String get clearPriceFilter => _strings.clearPriceFilter;
  String get applyFilters => _strings.applyFilters;
  String get photos => _strings.photos;
  String get productInfo => _strings.productInfo;
  String get optionalDetails => _strings.optionalDetails;
  String get colorSizeBrand => _strings.colorSizeBrand;
  String get chooseCategoryFirst => _strings.chooseCategoryFirst;
  String get reviewAndPublish => _strings.reviewAndPublish;
  String get chooseDeliveryArea => _strings.chooseDeliveryArea;
  String get verifyPhone => _strings.verifyPhone;
  String get phoneVerificationRequired => _strings.phoneVerificationRequired;
  String get publishProduct => _strings.publishProduct;
  String get sellProduct => _strings.sellProduct;
  String get loginToSell => _strings.loginToSell;
  String get next => _strings.next;
  String get publish => _strings.publish;
  String get previous => _strings.previous;
  String get brandOptionalNote => _strings.brandOptionalNote;
  String get brandLoadError => _strings.brandLoadError;
  String get chooseBrandOptional => _strings.chooseBrandOptional;
  String get noBrand => _strings.noBrand;
  String get noActiveCategories => _strings.noActiveCategories;
  String get categorySelected => _strings.categorySelected;
  String get categoryLoadDatabaseError => _strings.categoryLoadDatabaseError;
  String get productCondition => _strings.productCondition;
  String get optionalColorSize => _strings.optionalColorSize;
  String get productConditionsLoadError => _strings.productConditionsLoadError;
  String get noActiveProductConditions => _strings.noActiveProductConditions;
  String get colorsLoadError => _strings.colorsLoadError;
  String get noColorsForCategory => _strings.noColorsForCategory;
  String get sizesLoadError => _strings.sizesLoadError;
  String get noSizesForCategory => _strings.noSizesForCategory;
  String get fromGallery => _strings.fromGallery;
  String get takePhoto => _strings.takePhoto;
  String get addProductPhotosLimit => _strings.addProductPhotosLimit;
  String get addPhotos => _strings.addPhotos;
  String get of8ImagesAdded => _strings.of8ImagesAdded;
  String get clearPhotoTips => _strings.clearPhotoTips;
  String get photoTipsTitle => _strings.photoTipsTitle;
  String get setProductPrice => _strings.setProductPrice;
  String get pricingTip => _strings.pricingTip;
  String get competitivePriceTip => _strings.competitivePriceTip;
  String get quickOptions => _strings.quickOptions;
  String get selectedPrice => _strings.selectedPrice;
  String get profileSaved => _strings.profileSaved;
  String get editProfileTitle => _strings.editProfileTitle;
  String get loginToEditProfile => _strings.loginToEditProfile;
  String get changePhoto => _strings.changePhoto;
  String get loginToViewSellerDashboard => _strings.loginToViewSellerDashboard;
  String get verificationStatus => _strings.verificationStatus;
  String get storeAppearanceSettings => _strings.storeAppearanceSettings;
  String get previewStorePage => _strings.previewStorePage;
  String get upgradeProSeller => _strings.upgradeProSeller;
  String get businessTypeRequested => _strings.businessTypeRequested;
  String get reviewNote => _strings.reviewNote;
  String get upgradeApprovalUnavailable => _strings.upgradeApprovalUnavailable;
  String get teamManagement => _strings.teamManagement;
  String get manageMyProducts => _strings.manageMyProducts;
  String get sellerStoreLoadError => _strings.sellerStoreLoadError;
  String get storeProducts => _strings.storeProducts;
  String get noStoreProducts => _strings.noStoreProducts;
  String get areaLabel => _strings.areaLabel;
  String get storefrontDisplayed => _strings.storefrontDisplayed;
  String get uploadImageSuccess => _strings.uploadImageSuccess;
  String get uploadImageError => _strings.uploadImageError;
  String get enterStoreAddress => _strings.enterStoreAddress;
  String get chooseStorefrontImage => _strings.chooseStorefrontImage;
  String get displayNameLength => _strings.displayNameLength;
  String get storeSaved => _strings.storeSaved;
  String get saveError => _strings.saveError;
  String get storeSettingsTitle => _strings.storeSettingsTitle;
  String get storeDataLoadError => _strings.storeDataLoadError;
  String get ownerOnlyStoreEdit => _strings.ownerOnlyStoreEdit;
  String get chooseLogoImage => _strings.chooseLogoImage;
  String get storeDirectoryPrivacy => _strings.storeDirectoryPrivacy;
  String get showStorefront => _strings.showStorefront;
  String get storefrontPrivacy => _strings.storefrontPrivacy;
  String get noOnlineStoreAddress => _strings.noOnlineStoreAddress;
  String get optionalSocialLinks => _strings.optionalSocialLinks;
  String get settingsTitle => _strings.settingsTitle;
  String get notAvailable => _strings.notAvailable;
  String get appVersion => _strings.appVersion;
  String get featureUnavailable => _strings.featureUnavailable;
  String get accountDeactivateDelete => _strings.accountDeactivateDelete;
  String get accountDeletionUnavailable => _strings.accountDeletionUnavailable;
  String get ok => _strings.ok;
  String get signupAgreeTerms => _strings.signupAgreeTerms;
  String get orCreateAccountWith => _strings.orCreateAccountWith;
  String get invalidResetLink => _strings.invalidResetLink;
  String get evidenceUploaded => _strings.evidenceUploaded;
  String get evidenceUploadError => _strings.evidenceUploadError;
  String get evidenceLinkError => _strings.evidenceLinkError;
  String get evidenceOpenError => _strings.evidenceOpenError;
  String get evidenceInstructions => _strings.evidenceInstructions;
  String get chooseImage => _strings.chooseImage;
  String get uploadingEvidence => _strings.uploadingEvidence;
  String get registeredEvidence => _strings.registeredEvidence;
  String get noEvidenceYet => _strings.noEvidenceYet;
  String get evidenceHash => _strings.evidenceHash;
  String get viewEvidence => _strings.viewEvidence;
  String get downloadEvidence => _strings.downloadEvidence;
  String get evidenceCaptionOptional => _strings.evidenceCaptionOptional;
  String get attachedEvidence => _strings.attachedEvidence;
  String get chooseStorefrontPhoto => _strings.chooseStorefrontPhoto;
  String get chooseCoverPhoto => _strings.chooseCoverPhoto;
  String get passwordsDoNotMatch => _strings.passwordsDoNotMatch;
  String get termsRequired => _strings.termsRequired;
  String get passwordRequired => _strings.passwordRequired;
  String get passwordMinLength => _strings.passwordMinLength;
  String get currentLanguage => _strings.languageName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (item) => item.languageCode == locale.languageCode,
      );
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
