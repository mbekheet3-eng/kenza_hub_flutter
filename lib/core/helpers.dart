import 'dart:math' as math;
/// Helper functions والـ utilities الأساسية

/// String Helpers
class StringHelpers {
  /// التحقق من أن النص فارغ أو فقط مسافات
  static bool isEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// التحقق من أن النص ليس فارغاً
  static bool isNotEmpty(String? text) {
    return !isEmpty(text);
  }

  /// التحقق من صحة البريد الإلكتروني
  static bool isValidEmail(String? email) {
    if (isEmpty(email)) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email!);
  }

  /// التحقق من صحة رقم الهاتف
  static bool isValidPhoneNumber(String? phone) {
    if (isEmpty(phone)) return false;
    final phoneRegex = RegExp(
      r'^[+]?[(]?[0-9]{1,4}[)]?[-\s.]?[(]?[0-9]{1,4}[)]?[-\s.]?[0-9]{1,9}$',
    );
    return phoneRegex.hasMatch(phone!);
  }

  /// التحقق من صحة رابط URL
  static bool isValidUrl(String? url) {
    if (isEmpty(url)) return false;
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    return urlRegex.hasMatch(url!);
  }

  /// تقطيع النص إلى عدد معين من الأحرف مع إضافة ...
  static String truncate(String text, int length) {
    if (text.length <= length) return text;
    return '${text.substring(0, length)}...';
  }

  /// تحويل النص الأول إلى حرف كبير
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// إزالة المسافات الزائدة
  static String trimWhitespace(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

/// Number Helpers
class NumberHelpers {
  /// تنسيق السعر بفاصل آلاف
  static String formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// التحقق من أن الرقم موجب
  static bool isPositive(num number) {
    return number > 0;
  }

  /// التحقق من أن الرقم في النطاق
  static bool isInRange(num number, num min, num max) {
    return number >= min && number <= max;
  }

  /// تقريب الرقم لعدد معين من المنازل العشرية
  static double round(double number, int places) {
    final factor = math.pow(10, places).toDouble();
    return (number * factor).round() / factor;
  }
}

/// Date Helpers
class DateHelpers {
  /// التحقق من أن التاريخ في الماضي
  static bool isPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  /// التحقق من أن التاريخ في المستقبل
  static bool isFuture(DateTime dateTime) {
    return dateTime.isAfter(DateTime.now());
  }

  /// حساب الفرق بالأيام
  static int daysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }

  /// تنسيق التاريخ بصيغة سهلة الفهم
  static String formatDateArabic(DateTime dateTime) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  /// تحويل الوقت النسبي (منذ ساعة، منذ يومين، إلخ)
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inDays < 30) {
      return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
    } else {
      return 'منذ ${(difference.inDays / 30).floor()} شهر';
    }
  }
}

/// Math Helper
int pow(int base, int exponent) {
  if (exponent == 0) return 1;
  int result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

/// List Helpers
class ListHelpers {
  /// التحقق من أن القائمة فارغة
  static bool isEmpty<T>(List<T>? list) {
    return list == null || list.isEmpty;
  }

  /// التحقق من أن القائمة ليست فارغة
  static bool isNotEmpty<T>(List<T>? list) {
    return !isEmpty(list);
  }

  /// الحصول على العنصر الأول أو null
  static T? firstOrNull<T>(List<T>? list) {
    return isEmpty(list) ? null : list!.first;
  }

  /// الحصول على العنصر الأخير أو null
  static T? lastOrNull<T>(List<T>? list) {
    return isEmpty(list) ? null : list!.last;
  }

  /// تقسيم القائمة إلى أجزاء
  static List<List<T>> chunk<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  /// إزالة التكرارات
  static List<T> unique<T>(List<T> list) {
    return list.toSet().toList();
  }
}

/// Map Helpers
class MapHelpers {
  /// التحقق من أن Map فارغة
  static bool isEmpty<K, V>(Map<K, V>? map) {
    return map == null || map.isEmpty;
  }

  /// التحقق من أن Map ليست فارغة
  static bool isNotEmpty<K, V>(Map<K, V>? map) {
    return !isEmpty(map);
  }

  /// الحصول على قيمة مع default
  static V? getOrNull<K, V>(Map<K, V>? map, K key) {
    return map?[key];
  }
}

/// Validation Helper
class ValidationHelpers {
  /// التحقق من أن الحقل مطلوب
  static String? validateRequired(String? value) {
    if (StringHelpers.isEmpty(value)) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  /// التحقق من البريد الإلكتروني
  static String? validateEmail(String? value) {
    if (StringHelpers.isEmpty(value)) {
      return 'البريد الإلكتروني مطلوب';
    }
    if (!StringHelpers.isValidEmail(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  /// التحقق من كلمة المرور
  static String? validatePassword(String? value) {
    if (StringHelpers.isEmpty(value)) {
      return 'كلمة المرور مطلوبة';
    }
    if (value!.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  /// التحقق من رقم الهاتف
  static String? validatePhoneNumber(String? value) {
    if (StringHelpers.isEmpty(value)) {
      return 'رقم الهاتف مطلوب';
    }
    if (!StringHelpers.isValidPhoneNumber(value)) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  /// التحقق من السعر
  static String? validatePrice(String? value) {
    if (StringHelpers.isEmpty(value)) {
      return 'السعر مطلوب';
    }
    final price = double.tryParse(value!);
    if (price == null || price <= 0) {
      return 'السعر يجب أن يكون رقم موجب';
    }
    return null;
  }

  /// التحقق من الطول الأدنى
  static String? validateMinLength(String? value, int minLength) {
    if (StringHelpers.isEmpty(value)) {
      return 'هذا الحقل مطلوب';
    }
    if (value!.length < minLength) {
      return 'الحد الأدنى $minLength أحرف';
    }
    return null;
  }

  /// التحقق من الطول الأقصى
  static String? validateMaxLength(String? value, int maxLength) {
    if (StringHelpers.isEmpty(value)) {
      return 'هذا الحقل مطلوب';
    }
    if (value!.length > maxLength) {
      return 'الحد الأقصى $maxLength أحرف';
    }
    return null;
  }
}
