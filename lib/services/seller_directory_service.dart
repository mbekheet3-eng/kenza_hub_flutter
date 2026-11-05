import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import 'marketplace_product_service.dart';

class SellerDirectoryService {
  SellerDirectoryService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        _products = MarketplaceProductService(client: client);

  final SupabaseClient _client;
  final MarketplaceProductService _products;

  Future<List<Map<String, dynamic>>> loadDirectory({
    required bool agency,
  }) async {
    final rows = await _client
        .from(agency ? 'agency_directory' : 'online_store_directory')
        .select()
        .order('display_name');
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> loadStore({
    required String id,
    required bool agency,
  }) async {
    final row = await _client
        .from(agency ? 'agency_directory' : 'online_store_directory')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<String?> loadPublicAgencyAddress(String sellerProfileId) async {
    final result = await _client.rpc(
      'get_public_agency_shop_address',
      params: {'p_seller_profile_id': sellerProfileId},
    );
    return result as String?;
  }

  Future<List<Product>> loadStoreProducts(String sellerProfileId) {
    return _products.fetchProductsForStore(sellerProfileId);
  }
}
