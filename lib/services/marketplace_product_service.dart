import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

/// Schema-aligned product reads for the current Supabase marketplace schema.
class MarketplaceProductService {
  MarketplaceProductService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _productSelect = '''
    id,seller_id,category_id,title_ar,title_en,description_ar,description_en,
    price,views_count,created_at,updated_at,brand_id,brand,color_id,size_id,
    condition_id,status_id,currency_id,audience,
    category:categories!products_category_id_fkey(id,slug,name_ar,name_en,parent_id),
    condition:product_conditions!products_condition_id_fkey(slug,label_ar,label_en),
    color:product_colors!products_color_id_fkey(slug,label_ar,label_en,hex_code),
    size:product_sizes!products_size_id_fkey(slug,label_ar,label_en),
    status:product_statuses!products_status_id_fkey(slug,label_ar,label_en),
    seller:seller_profiles!products_seller_id_fkey(owner_user_id,display_name,avatar_url),
    images:product_images!product_images_product_id_fkey(image_url,display_order)
  ''';

  Future<List<Product>> fetchActiveProducts({int limit = 40}) async {
    final rows = await _client
        .from('products')
        .select(_productSelect)
        .eq('status.slug', 'active')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<Product> fetchProductById(String productId) async {
    final row = await _client
        .from('products')
        .select(_productSelect)
        .eq('id', productId)
        .single();

    return Product.fromJson(Map<String, dynamic>.from(row));
  }
}
