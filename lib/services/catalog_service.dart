import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/database_category.dart';

/// Read-only reference-data access aligned with Supabase V2.
class CatalogService {
  CatalogService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<DatabaseCategory>> fetchCategories() async {
    final rows = await _client
        .from('categories')
        .select('id,name_ar,name_en,slug,icon_url,parent_id,display_order')
        .eq('is_active', true)
        .order('display_order', ascending: true)
        .order('name_ar', ascending: true);

    return (rows as List)
        .map((row) => DatabaseCategory.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList(growable: false);
  }

  Future<String?> fetchRootCategorySlug(String categorySlug) async {
    final rows = await _client
        .from('categories')
        .select('id,slug,parent_id')
        .eq('is_active', true);
    final categories = (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final byId = {
      for (final category in categories) category['id'] as String: category,
    };
    final matches = categories.where((category) => category['slug'] == categorySlug);
    if (matches.isEmpty) return null;

    var current = matches.first;
    var parentId = current['parent_id'] as String?;
    while (parentId != null && byId.containsKey(parentId)) {
      current = byId[parentId]!;
      parentId = current['parent_id'] as String?;
    }
    return current['slug'] as String?;
  }

  Future<List<String>> fetchConditions() async {
    final rows = await _client
        .from('product_conditions')
        .select('name_ar')
        .eq('is_active', true)
        .order('display_order', ascending: true);
    return (rows as List)
        .map((row) => (row as Map)['name_ar'] as String?)
        .whereType<String>()
        .where((label) => label.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> fetchColors() async {
    final rows = await _client
        .from('product_colors')
        .select('name_ar')
        .eq('is_active', true)
        .order('display_order', ascending: true);
    return (rows as List)
        .map((row) => (row as Map)['name_ar'] as String?)
        .whereType<String>()
        .where((label) => label.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> fetchBrands() async {
    final rows = await _client
        .from('brands')
        .select('name_ar')
        .eq('is_active', true)
        .order('name_ar', ascending: true);
    return (rows as List)
        .map((row) => (row as Map)['name_ar'] as String?)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// V2 sizes are global reference values grouped by size_group; they are not
  /// linked to categories through category_id.
  Future<List<String>> fetchSizesForCategory(String categorySlug) async {
    final rows = await _client
        .from('product_sizes')
        .select('name_ar,name_en,size_group')
        .eq('is_active', true)
        .order('display_order', ascending: true);
    return (rows as List)
        .map((row) {
          final data = Map<String, dynamic>.from(row as Map);
          return (data['name_ar'] as String?) ??
              (data['name_en'] as String?) ??
              '';
        })
        .where((label) => label.trim().isNotEmpty)
        .toList(growable: false);
  }
}
