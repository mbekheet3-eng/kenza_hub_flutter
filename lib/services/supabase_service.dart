import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/product.dart';
import '../models/user.dart';
import '../models/order.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    _client = Supabase.instance.client;
  }

  // ==================== PRODUCTS ====================

  /// Add a new product
  Future<String> addProduct(Product product) async {
    try {
      final response = await _client
          .from('products')
          .insert(product.toJson())
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  /// Add product images
  Future<void> addProductImages(String productId, List<String> imageUrls) async {
    try {
      final images = <Map<String, dynamic>>[];
      for (int i = 0; i < imageUrls.length; i++) {
        images.add({
          'product_id': productId,
          'image_url': imageUrls[i],
          'order': i,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await _client.from('product_images').insert(images);
    } catch (e) {
      throw Exception('Failed to add product images: $e');
    }
  }

  /// Get product by ID
  Future<Product> getProduct(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  /// Search products
  Future<List<Product>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var request = _client
          .from('products')
          .select()
          .eq('is_active', true)
          .neq('is_sold', true)
          .ilike('title', '%$query%');

      if (category != null && category.isNotEmpty) {
        request = request.eq('category', category);
      }

      if (minPrice != null) {
        request = request.gte('price', minPrice);
      }

      if (maxPrice != null) {
        request = request.lte('price', maxPrice);
      }

      final response = await request
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(
    String category, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .neq('is_sold', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  /// Get user's products
  Future<List<Product>> getUserProducts(String userId, {int limit = 20}) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user products: $e');
    }
  }

  /// Update product
  Future<void> updateProduct(Product product) async {
    try {
      await _client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _client.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // ==================== USERS ====================

  /// Get user by ID
  Future<User> getUser(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return User.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Create user
  Future<void> createUser(User user) async {
    try {
      await _client.from('users').insert(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, UserProfile profile) async {
    try {
      await _client
          .from('users')
          .update(profile.toJson())
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Get user rating
  Future<double> getUserRating(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('rating')
          .eq('id', userId)
          .single();

      return (response['rating'] as num).toDouble();
    } catch (e) {
      throw Exception('Failed to get user rating: $e');
    }
  }

  // ==================== ORDERS ====================

  /// Create order
  Future<String> createOrder(Order order) async {
    try {
      final response = await _client
          .from('orders')
          .insert(order.toJson())
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get order by ID
  Future<Order> getOrder(String orderId) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  /// Get user's orders
  Future<List<Order>> getUserOrders(
    String userId, {
    bool asBuyer = true,
    int limit = 20,
  }) async {
    try {
      final column = asBuyer ? 'buyer_id' : 'seller_id';
      final response = await _client
          .from('orders')
          .select()
          .eq(column, userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _client
          .from('orders')
          .update({'status': status.toString().split('.').last})
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Add order review
  Future<void> addOrderReview(
    String orderId,
    double rating,
    String review,
  ) async {
    try {
      await _client
          .from('orders')
          .update({
            'rating': rating,
            'review': review,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to add order review: $e');
    }
  }

  // ==================== FAVORITES ====================

  /// Add to favorites
  Future<void> addToFavorites(String userId, String productId) async {
    try {
      await _client.from('favorites').insert({
        'user_id': userId,
        'product_id': productId,
      });
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Remove from favorites
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Get user favorites
  Future<List<String>> getUserFavorites(String userId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('product_id')
          .eq('user_id', userId);

      return (response as List)
          .map((json) => json['product_id'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to get user favorites: $e');
    }
  }

  // ==================== SEARCH ====================

  /// Search products by image
  Future<List<Product>> searchByImage(String imagePath) async {
    // This is a placeholder - actual implementation would use
    // a vision API or ML service
    try {
      // TODO: Implement image search using ML or vision API
      return [];
    } catch (e) {
      throw Exception('Failed to search by image: $e');
    }
  }

  // ==================== ANALYTICS ====================

  /// Increment product views
  Future<void> incrementProductViews(String productId) async {
    try {
      await _client.rpc('increment_product_views', params: {
        'product_id': productId,
      });
    } catch (e) {
      // Silent failure - not critical
      print('Failed to increment views: $e');
    }
  }

  /// Get trending products
  Future<List<Product>> getTrendingProducts({int limit = 10}) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('is_active', true)
          .neq('is_sold', true)
          .order('views', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get trending products: $e');
    }
  }
}
