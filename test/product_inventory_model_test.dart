import 'package:flutter_test/flutter_test.dart';
import 'package:kenza_hub_marketplace/models/product.dart';

void main() {
  group('Product inventory fields', () {
    test('reads condition, coarse location, and available quantity', () {
      final product = Product.fromMap(
        {
          'id': 'product-1',
          'owner_id': 'seller-1',
          'category_id': 'category-1',
          'title': 'Jacket',
          'description': 'A warm jacket in good condition.',
          'price': 500,
          'currency': 'EGP',
          'audience': 'all',
          'condition': 'used',
          'location': 'Maadi, Cairo',
          'quantity': 4,
          'status': 'published',
          'created_at': '2026-11-28T10:00:00Z',
          'has_variants': false,
        },
        signedImageUrls: const [],
        paths: const [],
      );

      expect(product.condition, 'used');
      expect(product.location, 'Maadi, Cairo');
      expect(product.quantity, 4);
      expect(product.availableQuantity, 4);
    });

    test('keeps legacy products readable with default stock', () {
      final product = Product.fromMap(
        {
          'id': 'product-2',
          'owner_id': 'seller-1',
          'category_id': 'category-1',
          'title': 'Legacy item',
          'description': '',
          'price': 100,
          'currency': 'EGP',
          'audience': 'all',
          'status': 'published',
          'created_at': '2026-11-28T10:00:00Z',
          'has_variants': false,
        },
        signedImageUrls: const [],
        paths: const [],
      );

      expect(product.condition, isNull);
      expect(product.location, isNull);
      expect(product.quantity, 1);
      expect(product.availableQuantity, 1);
    });
  });
}
