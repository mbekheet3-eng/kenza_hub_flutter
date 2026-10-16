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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      condition: json['condition'] as String,
      color: json['color'] as String?,
      size: json['size'] as String?,
      brand: json['brand'] as String?,
      imageUrls: List<String>.from(json['imageUrls'] as List<dynamic>? ?? []),
      imagePaths: List<String>.from(json['imagePaths'] as List<dynamic>? ?? []),
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      location: json['location'] as String?,
      isSold: json['isSold'] as bool? ?? false,
      sellerName: json['sellerName'] as String?,
      sellerAvatar: json['sellerAvatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'subcategory': subcategory,
      'condition': condition,
      'color': color,
      'size': size,
      'brand': brand,
      'imageUrls': imageUrls,
      'imagePaths': imagePaths,
      'views': views,
      'likes': likes,
      'rating': rating,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'isSold': isSold,
      'sellerName': sellerName,
      'sellerAvatar': sellerAvatar,
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
      productId: json['productId'] as String,
      imageUrl: json['imageUrl'] as String,
      localPath: json['localPath'] as String,
      order: json['order'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'imageUrl': imageUrl,
      'localPath': localPath,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
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
  'kids': 'ملابس أطفال',
  'home': 'منزل وأثاث',
};

const Map<String, bool> categorySkipFields = {
  'clothes': false,
  'shoes': false,
  'kids': false,
  'home': true, // Skip size, color, brand for home category
};
