// App Constants
abstract class AppConstants {
  // App info
  static const String appName = 'كينزا هب';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Image constraints
  static const int maxProductImages = 8;
  static const int imageQuality = 80;
  static const int imageMaxHeight = 1920;
  static const int imageMaxWidth = 1080;
  static const int maxImageFileSize = 52428800; // 50MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int defaultOffset = 0;

  // Timeouts
  static const int connectionTimeout = 30000; // ms
  static const int receiveTimeout = 30000; // ms

  // Cache durations
  static const Duration cacheDurationShort = Duration(minutes: 5);
  static const Duration cacheDurationMedium = Duration(minutes: 30);
  static const Duration cacheDurationLong = Duration(hours: 24);

  // Price constraints
  static const double minProductPrice = 0.0;
  static const double maxProductPrice = 999999.99;

  // Text constraints
  static const int minProductTitleLength = 5;
  static const int maxProductTitleLength = 255;
  static const int minProductDescriptionLength = 10;
  static const int maxProductDescriptionLength = 5000;

  // API Endpoints (for future use)
  static const String baseApiUrl = 'https://api.kenzahub.com';
  static const String productsEndpoint = '/products';
  static const String usersEndpoint = '/users';
  static const String ordersEndpoint = '/orders';
}

// Category Constants
abstract class CategoryConstants {
  static const List<String> categories = ['clothes', 'shoes', 'kids', 'home'];
  
  static const Map<String, String> categoryLabels = {
    'clothes': 'ملابس',
    'shoes': 'أحذية',
    'kids': 'ملابس أطفال',
    'home': 'منزل وأثاث',
  };

  static const Map<String, bool> categorySkipFields = {
    'clothes': false,
    'shoes': false,
    'kids': false,
    'home': true,
  };
}

// Condition Constants
abstract class ConditionConstants {
  static const List<String> conditions = [
    'مستخدم نادراً - Like New',
    'مستخدم بحالة جيدة - Good',
    'مستخدم - Fair',
    'للإصلاح - For Repair',
  ];
}

// Size Constants
abstract class SizeConstants {
  static const Map<String, List<String>> sizesByCategory = {
    'clothes': ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
    'shoes': ['35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45'],
    'kids': ['2Y', '3Y', '4Y', '5Y', '6Y', '7Y', '8Y', '9Y', '10Y', '12Y'],
  };

  static const Map<String, String> sizeTranslations = {
    'XS': 'إكس سمول',
    'S': 'سمول',
    'M': 'ميديوم',
    'L': 'لارج',
    'XL': 'إكس لارج',
    'XXL': 'دبل إكس لارج',
    'One Size': 'مقاس واحد',
  };
}

// Color Constants
abstract class ColorConstants {
  static const List<String> colors = [
    'أسود',
    'أبيض',
    'رمادي',
    'أحمر',
    'أزرق',
    'أخضر',
    'أصفر',
    'برتقالي',
    'بنفسجي',
    'وردي',
    'بني',
    'متعدد الألوان',
  ];
}

// Order Status Constants
abstract class OrderStatusConstants {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String disputed = 'disputed';

  static const Map<String, String> statusLabels = {
    'pending': 'قيد الانتظار',
    'accepted': 'مقبول',
    'shipped': 'تم الشحن',
    'delivered': 'تم التسليم',
    'completed': 'مكتمل',
    'cancelled': 'ملغى',
    'disputed': 'قيد النزاع',
  };
}

// Routing Constants
abstract class RoutingConstants {
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String sell = '/sell';
  static const String search = '/search';
  static const String productDetail = '/product/:id';
  static const String profile = '/profile';
  static const String orders = '/orders';
}

// Storage Keys (for local storage)
abstract class StorageKeys {
  static const String userKey = 'kenza_user';
  static const String authTokenKey = 'kenza_auth_token';
  static const String favoritesKey = 'kenza_favorites';
  static const String cartKey = 'kenza_cart';
  static const String languageKey = 'kenza_language';
  static const String themeKey = 'kenza_theme';
  static const String lastSearchesKey = 'kenza_last_searches';
}

// Regex Patterns
abstract class RegexPatterns {
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[+]?[(]?[0-9]{1,4}[)]?[-\s.]?[(]?[0-9]{1,4}[)]?[-\s.]?[0-9]{1,9}$';
  static const String urlPattern = r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$';
}
