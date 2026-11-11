import '../data/category_labels.dart';

class Category {
  const Category({
    required this.id,
    required this.parentId,
    required this.nameAr,
    required this.nameEn,
    required this.nameFr,
    required this.slug,
    required this.sortOrder,
  });

  final String id;
  final String? parentId;
  final String nameAr;
  final String nameEn;
  final String nameFr;
  final String slug;
  final int sortOrder;

  bool get isRoot => parentId == null;

  String nameFor(String languageCode) => CategoryLabels.name(
        slug,
        languageCode,
        nameAr,
        nameEn,
        nameFr,
      );

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        parentId: map['parent_id'] as String?,
        nameAr: map['name_ar'] as String,
        nameEn: map['name_en'] as String,
        nameFr: (map['name_fr'] as String?) ?? '',
        slug: map['slug'] as String,
        sortOrder: (map['sort_order'] as int?) ?? 0,
      );
}
