class Category {
  const Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String slug;

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        nameAr: map['name_ar'] as String,
        nameEn: map['name_en'] as String,
        slug: map['slug'] as String,
      );
}
