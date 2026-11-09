import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  FavoritesService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');
    return user.id;
  }

  Future<Set<String>> getFavoriteProductIds() async {
    final rows = await _client
        .from('favorites')
        .select('product_id')
        .eq('user_id', _userId);
    return rows.map((row) => row['product_id'] as String).toSet();
  }

  Future<void> addFavorite(String productId) async {
    await _client.from('favorites').upsert(
      {'user_id': _userId, 'product_id': productId},
      onConflict: 'user_id,product_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> removeFavorite(String productId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', _userId)
        .eq('product_id', productId);
  }
}
