import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import 'marketplace_product_service.dart';

/// Compatibility facade for the app's existing providers.
/// All product reads/writes use the current schema-aware service.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  late final supabase.SupabaseClient _client;
  late final MarketplaceProductService _products;

  factory SupabaseService() => _instance;

  SupabaseService._internal() {
    _client = supabase.Supabase.instance.client;
    _products = MarketplaceProductService(client: _client);
  }

  static supabase.SupabaseClient get client => _instance._client;

  bool get isAuthenticated => _client.auth.currentUser != null;
  supabase.User? get currentUser => _client.auth.currentUser;
  String? get userId => _client.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------

  Future<String> addProduct(Product product) async {
    throw UnsupportedError(
      'Use MarketplaceProductService.createProduct so seller membership and all lookup IDs are validated.',
    );
  }

  Future<String> createProduct(Product product) => addProduct(product);

  Future<void> addProductImages(
    String productId,
    List<String> imageUrls,
  ) async {
    throw UnsupportedError(
      'Product images are created atomically with the schema-aware listing flow.',
    );
  }

  Future<Product> getProduct(String productId) =>
      _products.fetchProductById(productId);

  Future<List<Product>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
    int offset = 0,
  }) async {
    final all = await _products.fetchActiveProducts(limit: 100);
    final normalized = query.trim().toLowerCase();
    final filtered = all.where((product) {
      final matchesQuery = normalized.isEmpty ||
          product.title.toLowerCase().contains(normalized) ||
          product.description.toLowerCase().contains(normalized);
      final matchesCategory =
          category == null || category.isEmpty || product.category == category;
      final matchesMin = minPrice == null || product.price >= minPrice;
      final matchesMax = maxPrice == null || product.price <= maxPrice;
      return matchesQuery && matchesCategory && matchesMin && matchesMax;
    }).toList(growable: false);
    if (offset >= filtered.length) return const [];
    final requestedEnd = offset + limit;
    final end = requestedEnd < filtered.length ? requestedEnd : filtered.length;
    return filtered.sublist(offset, end);
  }

  Future<List<Product>> getProductsByCategory(
    String category, {
    int limit = 20,
    int offset = 0,
  }) async {
    return searchProducts(
      query: '',
      category: category,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Product>> getUserProducts(
    String userId, {
    int limit = 20,
  }) =>
      _products.fetchSellerProducts(userId, limit: limit);

  Future<void> updateProduct(Product product) =>
      _products.updateProductDetails(product);

  /// Uses the database's soft-delete status; no hard DELETE from the client.
  Future<void> deleteProduct(String productId) =>
      _products.softDeleteProduct(productId);

  Future<List<Product>> getAllProducts({int limit = 100}) =>
      _products.fetchActiveProducts(limit: limit);

  Future<List<Product>> getTrendingProducts({int limit = 10}) async {
    final items = await _products.fetchActiveProducts(limit: 100);
    items.sort((a, b) => b.views.compareTo(a.views));
    return items.take(limit).toList(growable: false);
  }

  Future<Map<String, dynamic>> fetchProductById(String productId) async {
    final product = await _products.fetchProductById(productId);
    return {
      ...product.toJson(),
      'image_urls': product.imageUrls,
      'image_paths': product.imagePaths,
    };
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async =>
      fetchProductsWithImages();

  Future<List<Map<String, dynamic>>> fetchProductsWithImages() async {
    final items = await _products.fetchActiveProducts(limit: 100);
    return items
        .map((product) => {
              ...product.toJson(),
              'image_urls': product.imageUrls,
              'image_paths': product.imagePaths,
            })
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> fetchProductByIdWithImages(
    String productId,
  ) async =>
      fetchProductById(productId);

  /// Product variants are not a table in the approved schema.
  Future<List<Map<String, dynamic>>> fetchProductVariants(
    String productId,
  ) async =>
      const [];

  Future<List<Map<String, dynamic>>> fetchProductImages(
    String productId,
  ) async {
    final rows = await _client
        .from('product_images')
        .select('id,product_id,image_url,display_order,created_at')
        .eq('product_id', productId)
        .order('display_order', ascending: true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------

  Future<User> getUser(String userId) async {
    final row = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return User.fromJson(Map<String, dynamic>.from(row));
  }

  /// public.users is created by the handle_new_user auth trigger.
  Future<void> createUser(User user) async {
    throw UnsupportedError(
      'User profiles are created by the database auth trigger.',
    );
  }

  Future<void> updateUserProfile(
    String userId,
    UserProfile profile,
  ) async {
    await _client
        .from('users')
        .update(profile.toJson())
        .eq('id', userId);
  }

  Future<double> getUserRating(String userId) async {
    final row = await _client
        .from('users')
        .select('rating')
        .eq('id', userId)
        .single();
    return (row['rating'] as num?)?.toDouble() ?? 0;
  }

  Future<void> updateProfile(User user) async {
    await _client.from('users').update(user.toJson()).eq('id', user.id);
  }

  Future<User?> getCurrentUser(String userId) async {
    try {
      return await getUser(userId);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Orders — read-only until the approved agreement/OTP flow is implemented.
  // ---------------------------------------------------------------------------

  Future<String> createOrder(Order order) async {
    throw UnsupportedError(
      'Order creation is disabled. order-create currently returns 503 until both parties confirm the agreement.',
    );
  }

  Future<Order> getOrder(String orderId) async {
    final row = await fetchOrderById(orderId);
    return Order.fromJson(row);
  }

  Future<List<Order>> getUserOrders(
    String userId, {
    bool asBuyer = true,
    int limit = 20,
  }) async {
    var request = _client
        .from('orders')
        .select(
          '*,products(title_ar,title_en,product_images(image_url,display_order)),order_status_history(new_status,reason,action,created_at,metadata)',
        );

    if (asBuyer) {
      request = request.eq('buyer_id', userId);
    } else {
      final memberships = await _client
          .from('seller_profile_members')
          .select('seller_profile_id')
          .eq('user_id', userId)
          .isFilter('revoked_at', null);
      final profileIds = (memberships as List)
          .map((row) => (row as Map)['seller_profile_id'] as String)
          .toList();
      if (profileIds.isEmpty) return const [];
      request = request.inFilter('seller_profile_id', profileIds);
    }

    final rows = await request
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => Order.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    throw UnsupportedError(
      'Order status transitions are controlled by the server.',
    );
  }

  Future<void> addOrderReview(
    String orderId,
    double rating,
    String review,
  ) async {
    throw UnsupportedError(
      'Reviews must use the dedicated reviews workflow, not orders columns.',
    );
  }

  Future<Map<String, dynamic>> fetchOrderById(String orderId) async {
    final row = await _client
        .from('orders')
        .select(
          '*,products(title_ar,title_en,product_images(image_url,display_order)),order_status_history(new_status,reason,action,created_at,metadata)',
        )
        .eq('id', orderId)
        .single();
    return Map<String, dynamic>.from(row);
  }

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  Future<void> addToFavorites(String userId, String productId) async {
    await _client.from('favorites').insert({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<void> removeFromFavorites(String userId, String productId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<List<String>> getUserFavorites(String userId) async {
    final rows = await _client
        .from('favorites')
        .select('product_id')
        .eq('user_id', userId);
    return (rows as List)
        .map((row) => (row as Map)['product_id'] as String)
        .toList(growable: false);
  }

  Future<void> toggleFavorite(String productId, String userId) async {
    final existing = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      await removeFromFavorites(userId, productId);
    } else {
      await addToFavorites(userId, productId);
    }
  }

  // ---------------------------------------------------------------------------
  // Search / analytics
  // ---------------------------------------------------------------------------

  /// Visual search is intentionally unavailable until a real image-embedding
  /// service and its secured endpoint are configured. Never report an empty
  /// result list as if image matching had actually run.
  Future<List<Product>> searchByImage(String imagePath) async {
    throw UnsupportedError(
      'البحث بالصورة يحتاج إلى تفعيل خدمة المطابقة البصرية على الخادم.',
    );
  }

  Future<void> incrementProductViews(String productId) async {
    try {
      await _client.rpc(
        'increment_product_views',
        params: {'p_product_id': productId},
      );
    } catch (error) {
      // View tracking is non-blocking; the database RPC remains authoritative.
      // ignore: avoid_print
      print('Failed to increment product views: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return {'user': response.user, 'session': response.session};
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
      emailRedirectTo: 'com.kenza.hub://login-callback/',
    );
    return {'user': response.user, 'session': response.session};
  }

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.kenza.hub://reset-password/',
      );

  Future<void> signOut() => _client.auth.signOut();
}
