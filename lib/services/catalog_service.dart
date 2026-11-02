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
          'id,name_ar,name_en,slug,icon_url,parent_id,display_order',
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
}
