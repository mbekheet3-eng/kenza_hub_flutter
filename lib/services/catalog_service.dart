import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/database_category.dart';

/// Reads catalogue reference data from the live database schema.
/// This service is read-only: category management remains an admin operation.
class CatalogService {
  CatalogService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<DatabaseCategory>> fetchCategories() async {
    final rows = await _client
        .from('categories')
        .select(
          'id,name_ar,name_en,slug,icon,parent_id,display_order',
        )
        .eq('is_active', true)
        .order('display_order', ascending: true)
        .order('name_ar', ascending: true);

    return (rows as List)
        .map(
          (row) => DatabaseCategory.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }
  Future<List<String>> fetchBrands() async {
    final rows = await _client
        .from('brands')
        .select('name')
        .order('name', ascending: true);

    return (rows as List)
        .map((row) => (row as Map)['name'] as String?)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> fetchSizesForCategory(String categorySlug) async {
    final categoryRows = await _client
        .from('categories')
        .select('id,slug,parent_id')
        .eq('is_active', true);
    final categories = (categoryRows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final byId = {
      for (final category in categories)
        category['id'] as String: category,
    };
    final selected = categories.where(
      (category) => category['slug'] == categorySlug,
    );
    if (selected.isEmpty) return const [];

    var root = selected.first;
    var parentId = root['parent_id'] as String?;
    while (parentId != null && byId.containsKey(parentId)) {
      root = byId[parentId]!;
      parentId = root['parent_id'] as String?;
    }

    final rows = await _client
        .from('product_sizes')
        .select('label_en,label_ar')
        .eq('category_id', root['id'])
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (rows as List)
        .map((row) {
          final data = Map<String, dynamic>.from(row as Map);
          return (data['label_en'] as String?) ??
              (data['label_ar'] as String?) ??
              '';
        })
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
  }

}
