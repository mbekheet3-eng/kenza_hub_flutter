import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
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

  // Get primary image path (for caching)
  String? get primaryImagePath => imagePaths.isNotEmpty ? imagePaths[0] : null;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

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

@JsonSerializable()
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

  factory ProductImage.fromJson(Map<String, dynamic> json) => _$ProductImageFromJson(json);
  Map<String, dynamic> toJson() => _$ProductImageToJson(this);
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
