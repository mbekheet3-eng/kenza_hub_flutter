class Product {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final int stock;
  final List<String>? sizes;
  final List<String>? colors;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.storeId,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.stock,
    this.sizes,
    this.colors,
    this.rating,
    this.reviewCount,
    required this.createdAt,
  });

  // Convert from JSON (Supabase)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String? ?? 'أخرى',
      stock: json['stock'] as int? ?? 0,
      sizes: (json['sizes'] as List<dynamic>?)?.cast<String>(),
      colors: (json['colors'] as List<dynamic>?)?.cast<String>(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'store_id': storeId,
    'title': title,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'category': category,
    'stock': stock,
    'sizes': sizes,
    'colors': colors,
    'rating': rating,
    'review_count': reviewCount,
    'created_at': createdAt.toIso8601String(),
  };

  // Copy with
  Product copyWith({
    String? id,
    String? storeId,
    String? title,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    int? stock,
    List<String>? sizes,
    List<String>? colors,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Product(id: $id, title: $title, price: $price)';
}
