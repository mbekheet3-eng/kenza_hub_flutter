class DatabaseCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final String slug;
  final String? iconUrl;
  final String? parentId;
  final int displayOrder;

  const DatabaseCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.iconUrl,
    this.parentId,
    this.displayOrder = 0,
  });

  factory DatabaseCategory.fromJson(Map<String, dynamic> json) {
    return DatabaseCategory(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      slug: json['slug'] as String,
      iconUrl: json['icon'] as String? ?? json['icon_url'] as String?,
      parentId: json['parent_id'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  String labelFor(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;
}
