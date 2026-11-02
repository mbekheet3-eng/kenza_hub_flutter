class Product {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String? subcategory;
  final String condition;
  final String? color;
  final String? size;
  final String? brand;
  final List<String> imageUrls;
  final List<String> imagePaths; // Local cache paths
  final int views;
  final int likes;
  final double? rating;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final String? location;
  final bool isSold;
  final String? sellerName;
  final String? sellerAvatar;

  Product({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.subcategory,
    required this.condition,
    this.color,
    this.size,
    this.brand,
    required this.imageUrls,
    required this.imagePaths,
    this.views = 0,
    this.likes = 0,
    this.rating,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.location,
    this.isSold = false,
    this.sellerName,
    this.sellerAvatar,
  });

  // Check if category is "home" (furniture & home items)
  bool get isHomeCategory => category.toLowerCase() == 'home';

  // Get primary image
  String get primaryImage => imageUrls.isNotEmpty ? imageUrls[0] : '';

  // Get primary image (alias for compatibility)
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls[0] : '';

  // Get primary image path (for caching)
  String? get primaryImagePath => imagePaths.isNotEmpty ? imagePaths[0] : null;

  // Price display with currency
  String get priceDisplay => '${price.toStringAsFixed(2)} ج.م';

  // Check if product is available (not sold and is active)
  bool get isAvailable => !isSold && isActive;

  // Rating display
  String get ratingDisplay => rating != null ? rating!.toStringAsFixed(1) : 'بدون تقييم';

  // Review count display
  int get reviewCount => rating != null ? (rating! * 20).toInt() : 0; // Estimate

  static Map<String, dynamic>? _relation(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final categoryData = _relation(json, 'category') ??
        _relation(json, 'categories');
    final conditionData = _relation(json, 'condition') ??
        _relation(json, 'product_conditions');
    final colorData = _relation(json, 'color') ??
        _relation(json, 'product_colors');
    final sizeData = _relation(json, 'size') ??
        _relation(json, 'product_sizes');
    final statusData = _relation(json, 'status') ??
        _relation(json, 'product_statuses');
    final sellerData = _relation(json, 'seller') ??
        _relation(json, 'seller_profiles');

    final rawImages = json['images'] ?? json['product_images'];
    final imageRows = rawImages is List ? rawImages : const [];
    final sortedImages = imageRows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
      ..sort((a, b) =>
          ((a['display_order'] as num?)?.toInt() ?? 0).compareTo(
            (b['display_order'] as num?)?.toInt() ?? 0,
          ));
    final imageUrls = sortedImages
        .map((row) => row['image_url'])
        .whereType<String>()
        .toList();

    final statusSlug = statusData?['slug'] as String? ?? 'active';
    final sellerProfileId = json['seller_id'] as String?;

    return Product(
      id: json['id'] as String,
      userId: sellerData?['owner_user_id'] as String? ??
          sellerProfileId ??
          '',
      title: json['title_ar'] as String? ??
          json['title_en'] as String? ??
          json['title'] as String? ??
          '',
      description: json['description_ar'] as String? ??
          json['description_en'] as String? ??
          json['description'] as String? ??
          '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: categoryData?['slug'] as String? ??
          json['category'] as String? ??
          '',
      subcategory: categoryData?['parent_id'] as String? ??
          json['subcategory'] as String?,
      condition: conditionData?['label_ar'] as String? ??
          json['condition'] as String? ??
          '',
      color: colorData?['label_ar'] as String? ??
          json['color'] as String?,
      size: sizeData?['label_ar'] as String? ?? json['size'] as String?,
      brand: json['brand'] as String?,
      imageUrls: imageUrls.isNotEmpty
          ? imageUrls
          : List<String>.from(json['image_urls'] as List? ?? const []),
      imagePaths: List<String>.from(json['image_paths'] as List? ?? const []),
      views: (json['views_count'] as num?)?.toInt() ??
          (json['views'] as num?)?.toInt() ??
          0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      isActive: statusSlug == 'active',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      isSold: statusSlug == 'sold',
      sellerName: sellerData?['display_name'] as String? ??
          json['seller_name'] as String?,
      sellerAvatar: sellerData?['avatar_url'] as String? ??
          json['seller_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId, // ✅ FIXED: snake_case
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'subcategory': subcategory,
      'condition': condition,
      'color': color,
      'size': size,
      'brand': brand,
      'image_urls': imageUrls, // ✅ FIXED: snake_case
      'image_paths': imagePaths, // ✅ FIXED: snake_case
      'views': views,
      'likes': likes,
      'rating': rating,
      'is_active': isActive, // ✅ FIXED: snake_case
      'created_at': createdAt.toIso8601String(), // ✅ FIXED: snake_case
      'updated_at': updatedAt.toIso8601String(), // ✅ FIXED: snake_case
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'is_sold': isSold, // ✅ FIXED: snake_case
      'seller_name': sellerName, // ✅ FIXED: snake_case
      'seller_avatar': sellerAvatar, // ✅ FIXED: snake_case
    };
  }

  // Copy with method
  Product copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? subcategory,
    String? condition,
    String? color,
    String? size,
    String? brand,
    List<String>? imageUrls,
    List<String>? imagePaths,
    int? views,
    int? likes,
    double? rating,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    String? location,
    bool? isSold,
    String? sellerName,
    String? sellerAvatar,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      condition: condition ?? this.condition,
      color: color ?? this.color,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      imageUrls: imageUrls ?? this.imageUrls,
      imagePaths: imagePaths ?? this.imagePaths,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      isSold: isSold ?? this.isSold,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
    );
  }
}

class ProductImage {
  final String id;
  final String productId;
  final String imageUrl;
  final String localPath;
  final int order;
  final DateTime createdAt;

  ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    required this.localPath,
    required this.order,
    required this.createdAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] as String,
      productId: json['product_id'] as String, // ✅ FIXED: snake_case
      imageUrl: json['image_url'] as String, // ✅ FIXED: snake_case
      localPath: json['local_path'] as String? ?? '',
      order: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String), // ✅ FIXED: snake_case
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId, // ✅ FIXED: snake_case
      'image_url': imageUrl, // ✅ FIXED: snake_case
      'display_order': order,
      'created_at': createdAt.toIso8601String(), // ✅ FIXED: snake_case
    };
  }
}

// Size translations for Arabic market
const Map<String, String> sizeTranslations = {
  'XS': 'إكس سمول',
  'S': 'سمول',
  'M': 'ميديوم',
  'L': 'لارج',
  'XL': 'إكس لارج',
  'XXL': 'دبل إكس لارج',
  'One Size': 'مقاس واحد',
};

// Condition options
const List<String> conditionOptions = [
  'مستخدم نادراً - Like New',
  'مستخدم بحالة جيدة - Good',
  'مستخدم - Fair',
  'للإصلاح - For Repair',
];

// Category mappings
const Map<String, String> categoryTranslations = {
  'clothes': 'ملابس',
  'shoes': 'أحذية',
  'kids': 'مستلزمات أطفال',
  'home': 'مستلزمات المنزل',
};

const Map<String, bool> categorySkipFields = {
  'clothes': false,
  'shoes': false,
  'kids': true,
  'home': true, // Skip size, color, brand for home category
};
