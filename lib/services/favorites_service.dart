import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_locale.dart';
import '../l10n/app_strings.dart';

class FavoritesService {
  FavoritesService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> _requireUserId() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      final strings = await AppStrings.delegate.load(AppLocale.notifier.value);
      throw Exception(strings.loginRequired);
    }
    return id;
  }

  Future<Set<String>> getFavoriteProductIds() async {
    final userId = await _requireUserId();
    final rows = await _client
        .from('favorites')
        .select('product_id')
        .eq('user_id', userId);
    return rows.map((row) => row['product_id'] as String).toSet();
  }

  Future<void> addFavorite(String productId) async {
    final userId = await _requireUserId();
    await _client.from('favorites').upsert(
      {'user_id': userId, 'product_id': productId},
      onConflict: 'user_id,product_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> removeFavorite(String productId) async {
    final userId = await _requireUserId();
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', _userId)
        .eq('product_id', productId);
  }
}
