import 'package:flutter_test/flutter_test.dart';
import 'package:kenza_hub_marketplace/data/category_labels.dart';
import 'package:kenza_hub_marketplace/models/category.dart';

void main() {
  group('Category translations', () {
    const category = Category(
      id: 'category-1',
      parentId: 'women-root',
      nameAr: 'اسم عربي من قاعدة البيانات',
      nameEn: 'Database English name',
      nameFr: 'Nom français de la base',
      slug: 'clothes-women-evening-dresses',
      sortOrder: 2,
    );

    test('uses the selected Arabic, English, and French labels', () {
      expect(category.nameFor('ar'), 'فساتين سواريه');
      expect(category.nameFor('en'), 'Evening Dresses');
      expect(category.nameFor('fr'), 'Robes de soirée');
    });

    test('falls back to database translations for unknown slugs', () {
      const unknown = Category(
        id: 'category-2',
        parentId: null,
        nameAr: 'تصنيف جديد',
        nameEn: 'New category',
        nameFr: 'Nouvelle catégorie',
        slug: 'new-category-from-database',
        sortOrder: 1,
      );

      expect(unknown.nameFor('ar'), 'تصنيف جديد');
      expect(unknown.nameFor('en'), 'New category');
      expect(unknown.nameFor('fr'), 'Nouvelle catégorie');
    });

    test('identifies root categories', () {
      expect(category.isRoot, isFalse);
      const root = Category(
        id: 'root',
        parentId: null,
        nameAr: 'ملابس',
        nameEn: 'Clothes',
        nameFr: 'Vêtements',
        slug: 'clothes',
        sortOrder: 1,
      );
      expect(root.isRoot, isTrue);
    });
  });

  group('Category intent search', () {
    test('maps Arabic and French shirt searches to matching categories', () {
      expect(CategoryLabels.searchSlugs('قمصان'),
          contains('clothes-men-shirts'));
      expect(CategoryLabels.searchSlugs('chemise'),
          contains('clothes-men-shirts'));
    });
  });
}
