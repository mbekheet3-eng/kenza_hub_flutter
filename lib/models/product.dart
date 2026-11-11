class Product {
  const Product({
    required this.id,
    required this.ownerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.audience,
    required this.createdAt,
    required this.imagePaths,
    required this.imageUrls,
  });

  final String id;
  final String ownerId;
  final String categoryId;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String audience;
  final DateTime createdAt;
  final List<String> imagePaths;
  final List<String> imageUrls;

  String? get primaryImage => imageUrls.isEmpty ? null : imageUrls.first;

  factory Product.fromMap(
    Map<String, dynamic> map, {
    required List<String> signedImageUrls,
    required List<String> paths,
  }) {
    return Product(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      categoryId: map['category_id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      price: (map['price'] as num).toDouble(),
      currency: (map['currency'] as String?) ?? 'EGP',
      audience: (map['audience'] as String?) ?? 'all',
      createdAt: DateTime.parse(map['created_at'] as String),
      imagePaths: paths,
      imageUrls: signedImageUrls,
    );
  }
}
