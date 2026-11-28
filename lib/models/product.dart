class ProductVariant {
  const ProductVariant({this.id, this.color, this.size, required this.quantity});
  final String? id;
  final String? color;
  final String? size;
  final int quantity;

  String colorLabel(String languageCode) {
    const labels = {
      'black': ['أسود', 'Black', 'Noir'], 'white': ['أبيض', 'White', 'Blanc'],
      'blue': ['أزرق', 'Blue', 'Bleu'], 'red': ['أحمر', 'Red', 'Rouge'],
      'green': ['أخضر', 'Green', 'Vert'], 'yellow': ['أصفر', 'Yellow', 'Jaune'],
      'pink': ['وردي', 'Pink', 'Rose'], 'brown': ['بني', 'Brown', 'Marron'],
      'gray': ['رمادي', 'Gray', 'Gris'], 'beige': ['بيج', 'Beige', 'Beige'],
    };
    final values = labels[color?.toLowerCase()];
    if (values == null) return color ?? '';
    final index = languageCode == 'ar' ? 0 : languageCode == 'fr' ? 2 : 1;
    return values[index];
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) => ProductVariant(
    id: map['id'] as String?, color: map['color'] as String?,
    size: map['size'] as String?, quantity: (map['quantity'] as num).toInt(),
  );
  Map<String, dynamic> toInsertMap(String productId) => {
    'product_id': productId, 'color': color, 'size': size, 'quantity': quantity,
  };
}
class Product {
  const Product({
    required this.id, required this.ownerId, required this.categoryId,
    required this.title, required this.description, required this.price,
    required this.currency, required this.audience, this.customCategoryName,
    this.status = 'published', required this.createdAt,
    required this.imagePaths, required this.imageUrls,
    this.hasVariants = false, this.variants = const [],
    this.condition, this.location, this.quantity = 1,
  });
  final String id, ownerId, categoryId, title, description, currency, audience, status;
  final double price;
  final String? customCategoryName;
  final String? condition;
  final String? location;
  final int quantity;
  final DateTime createdAt;
  final List<String> imagePaths, imageUrls;
  final bool hasVariants;
  final List<ProductVariant> variants;
  int get availableQuantity => hasVariants ? variants.fold(0, (sum, v) => sum + v.quantity) : quantity;
  String? get primaryImage => imageUrls.isEmpty ? null : imageUrls.first;
  factory Product.fromMap(Map<String, dynamic> map, {
    required List<String> signedImageUrls, required List<String> paths,
  }) => Product(
    id: map['id'] as String, ownerId: map['owner_id'] as String,
    categoryId: map['category_id'] as String, title: map['title'] as String,
    description: (map['description'] as String?) ?? '',
    price: (map['price'] as num).toDouble(),
    currency: (map['currency'] as String?) ?? 'EGP',
    audience: (map['audience'] as String?) ?? 'all',
    customCategoryName: map['custom_category_name'] as String?,
    status: (map['status'] as String?) ?? 'published',
    createdAt: DateTime.parse(map['created_at'] as String),
    imagePaths: paths, imageUrls: signedImageUrls,
    hasVariants: map['has_variants'] == true,
    condition: map['condition'] as String?,
    location: map['location'] as String?,
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    variants: ((map['product_variants'] as List<dynamic>?) ?? const [])
      .map((row) => ProductVariant.fromMap(Map<String,dynamic>.from(row as Map))).toList(growable:false),
  );
}
