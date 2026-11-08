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
  final List<String> imagePaths; // Supabase object paths used for image retrieval
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
  final bool isDeleted;
  final String? sellerName;
  final String? sellerAvatar;
  final String? sellerProfileId;
  final String? categoryId;
  final String? conditionId;
  final String? statusId;
  final String statusSlug;
  final String moderationStatus;
  final String? currencyId;
  final String? colorId;
  final String? sizeId;
  final String? brandId;
  final String audience;
  final String sellerType;
  final double? weightKg;

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
    this.isDeleted = false,
    this.sellerName,
    this.sellerAvatar,
    this.sellerProfileId,
    this.categoryId,
    this.conditionId,
    this.statusId,
    this.statusSlug = 'active',
    this.moderationStatus = 'approved',
    this.currencyId,
    this.colorId,
    this.sizeId,
    this.brandId,
    this.audience = 'public',
    this.sellerType = 'seller',
    this.weightKg,
  });

  // Check if category is "home" (furniture & home items)
  bool get isHomeCategory => category.toLowerCase() == 'home-supplies';

  // Get primary image
  String get primaryImage => imageUrls.isNotEmpty ? imageUrls[0] : '';

  // Get primary image (alias for compatibility)
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls[0] : '';

  // Get primary image path (for caching)
  String? get primaryImagePath => imagePaths.isNotEmpty ? imagePaths[0] : null;

  // Price display with currency
  String get priceDisplay => '${price.toStringAsFixed(2)} ج.م';

  // Check if product is available (not sold and is active)
  bool get isAvailable =>
      !isSold &&
      !isDeleted &&
      isActive &&
      statusSlug == 'available' &&
      moderationStatus == 'approved';

  bool get isPendingReview =>
      statusSlug == 'pending_review' ||
      moderationStatus == 'pending' ||
      moderationStatus == 'pending_review';

  // Rating display
  String get ratingDisplay => rating != null ? rating!.toStringAsFixed(1) : 'بدون تقييم';

  // Review count display
  // Review counts must come from real review rows, never be estimated from ratings.
  int get reviewCount => 0;

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
    final parentCategoryData = categoryData == null
        ? null
        : _relation(categoryData, 'parent');
    var rootCategoryData = categoryData;
    var ancestorCategoryData = parentCategoryData;
    while (ancestorCategoryData != null) {
      rootCategoryData = ancestorCategoryData;
      ancestorCategoryData = _relation(ancestorCategoryData, 'parent');
    }
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

    // Missing status metadata must fail closed rather than making a product
    // look active when its lifecycle relation could not be loaded.
    final statusSlug = statusData?['slug'] as String? ?? 'unknown';
    final sellerProfileId = json['seller_id'] as String?;

    return Product(
      id: json['id'] as String,
      // seller_id is a seller_profiles ID, never an auth.users ID.
      // Do not substitute it when the owner relation is unavailable.
      userId: sellerData?['owner_user_id'] as String? ?? '',
      title: json['title_ar'] as String? ??
          json['title_en'] as String? ??
          json['title'] as String? ??
          '',
      description: json['description_ar'] as String? ??
          json['description_en'] as String? ??
          json['description'] as String? ??
          '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      // Home filtering uses the top-level category when this is a child category.
      category: rootCategoryData?['slug'] as String? ??
          json['category'] as String? ??
          '',
      subcategory: parentCategoryData != null
          ? (categoryData == null ? null : categoryData['slug'] as String?)
          : json['subcategory'] as String?,
      condition: conditionData?['name_ar'] as String? ?? conditionData?['label_ar'] as String? ??
          json['condition'] as String? ??
          '',
      color: colorData?['name_ar'] as String? ?? colorData?['label_ar'] as String? ??
          json['color'] as String?,
      size: sizeData?['name_ar'] as String? ?? sizeData?['label_ar'] as String? ?? json['size'] as String?,
      brand: json['brand_name'] as String? ?? json['brand'] as String?,
      imageUrls: imageUrls.isNotEmpty
          ? imageUrls
          : List<String>.from(json['image_urls'] as List? ?? const []),
      imagePaths: List<String>.from(json['image_paths'] as List? ?? const []),
      views: (json['views_count'] as num?)?.toInt() ??
          (json['views'] as num?)?.toInt() ??
          0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      isActive: statusSlug == 'available' || statusSlug == 'active',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      isSold: statusSlug == 'sold',
      isDeleted: statusSlug == 'hidden' || statusSlug == 'deleted',
      sellerName: sellerData?['display_name'] as String? ??
          json['seller_name'] as String?,
      sellerAvatar: sellerData?['avatar_url'] as String? ??
          json['seller_avatar'] as String?,
      sellerProfileId: sellerProfileId,
      sellerType: sellerData?['seller_type'] as String? ?? 'seller',
      categoryId: json['category_id'] as String?,
      conditionId: json['condition_id'] as String?,
      statusId: json['status_id'] as String?,
      statusSlug: statusSlug,
      moderationStatus: json['moderation_status'] as String? ?? 'pending',
      currencyId: json['currency_id'] as String?,
      colorId: json['color_id'] as String?,
      sizeId: json['size_id'] as String?,
      brandId: json['brand_id'] as String?,
      audience: json['audience'] as String? ?? 'public',
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
    );
  }

  /// Current products table fields only. Images are stored separately.
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (sellerProfileId != null) 'seller_id': sellerProfileId,
      if (categoryId != null) 'category_id': categoryId,
      'title_ar': title,
      'title_en': title,
      'description_ar': description,
      'description_en': description,
      'price': price,
      if (conditionId != null) 'condition_id': conditionId,
      if (statusId != null) 'status_id': statusId,
      if (currencyId != null) 'currency_id': currencyId,
      if (brandId != null) 'brand_id': brandId,
      if (brand != null) 'brand_name': brand,
      if (colorId != null) 'color_id': colorId,
      if (sizeId != null) 'size_id': sizeId,
      'audience': audience,
      if (weightKg != null) 'weight_kg': weightKg,
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
    bool? isDeleted,
    String? sellerName,
    String? sellerAvatar,
    String? sellerProfileId,
    String? categoryId,
    String? conditionId,
    String? statusId,
    String? currencyId,
    String? colorId,
    String? sizeId,
    String? brandId,
    String? audience,
    String? statusSlug,
    String? moderationStatus,
    String? sellerType,
    double? weightKg,
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
      isDeleted: isDeleted ?? this.isDeleted,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      sellerProfileId: sellerProfileId ?? this.sellerProfileId,
      categoryId: categoryId ?? this.categoryId,
      conditionId: conditionId ?? this.conditionId,
      statusId: statusId ?? this.statusId,
      statusSlug: statusSlug ?? this.statusSlug,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      currencyId: currencyId ?? this.currencyId,
      colorId: colorId ?? this.colorId,
      sizeId: sizeId ?? this.sizeId,
      brandId: brandId ?? this.brandId,
      audience: audience ?? this.audience,
      sellerType: sellerType ?? this.sellerType,
      weightKg: weightKg ?? this.weightKg,
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
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'image_url': imageUrl,
        'display_order': order,
      };
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
  'جديد بالبطاقة',
  'جديد بدون بطاقة',
  'ممتاز - مستخدم نادراً',
  'جيد - مستخدم بعناية',
  'مقبول - به آثار استخدام',
  'للتصليح أو القطع',
];

// Category mappings
const Map<String, String> categoryTranslations = {
  'clothes': 'ملابس',
  'shoes': 'أحذية',
  'kids-supplies': 'مستلزمات أطفال',
  'home-supplies': 'مستلزمات المنزل',
};

const Map<String, bool> categorySkipFields = {
  'clothes': false,
  'shoes': false,
  'kids-supplies': true,
  'home-supplies': true, // Skip size, color, brand for home category
};
