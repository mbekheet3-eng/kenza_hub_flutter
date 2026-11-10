class Category {
  const Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameFr,
    required this.slug,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String nameFr;
  final String slug;

  /// Returns the category label for the selected app language.
  /// English is the safe fallback if an older API response omits a translation.
  String nameFor(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr;
      case 'fr':
        return nameFr.isNotEmpty ? nameFr : nameEn;
      case 'en':
      default:
        return nameEn;
    }
  }

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        nameAr: map['name_ar'] as String,
        nameEn: map['name_en'] as String,
        nameFr: (map['name_fr'] as String?) ?? '',
        slug: map['slug'] as String,
      );
}
