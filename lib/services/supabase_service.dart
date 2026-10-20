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

  // Static getter for client
  static SupabaseClient get client => _instance._client;

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

  /// Fetch a single product by ID WITH IMAGES ✅ FIXED D10
  Future<Map<String, dynamic>> fetchProductById(String productId) async {
    return fetchProductByIdWithImages(productId);
  }

  /// Fetch all products WITH IMAGES assembled ✅ FIXED D10
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    return fetchProductsWithImages();
  }

  /// Fetch product variants (sizes, colors, etc.)
  Future<List<Map<String, dynamic>>> fetchProductVariants(String productId) async {
    try {
      final response = await _client
          .from('product_variants')
          .select()
          .eq('product_id', productId);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching product variants: $e');
      rethrow;
    }
  }

  // ==================== PRODUCT IMAGES ====================

  /// ✅ FIXED D10: Fetch product images from separate product_images table
  Future<List<Map<String, dynamic>>> fetchProductImages(String productId) async {
    try {
      final response = await _client
          .from('product_images')
          .select()
          .eq('product_id', productId)
          .order('order_index', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching product images for $productId: $e');
      return []; // Return empty list if images not found
    }
  }

  /// ✅ FIXED D10: Fetch products with images assembled from product_images table
  Future<List<Map<String, dynamic>>> fetchProductsWithImages() async {
    try {
      // Fetch all products
      final productsResponse = await _client
          .from('products')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final products = List<Map<String, dynamic>>.from(productsResponse as List);

      // For each product, fetch its images
      final enrichedProducts = <Map<String, dynamic>>[];
      
      for (final product in products) {
        final productId = product['id'] as String;
        
        // Fetch images for this product
        final images = await fetchProductImages(productId);
        
        // Extract image URLs and sort by order_index
        final imageUrls = (images as List)
            .map((img) => img['image_url'] as String)
            .toList();

        // Add assembled image data to product
        product['image_urls'] = imageUrls;  // ✅ Add as snake_case
        product['image_paths'] = [];  // Empty local paths initially
        
        enrichedProducts.add(product);
      }

      return enrichedProducts;
    } catch (e) {
      print('❌ Error fetching products with images: $e');
      rethrow;
    }
  }

  /// ✅ FIXED D10: Fetch single product WITH images
  Future<Map<String, dynamic>> fetchProductByIdWithImages(String productId) async {
    try {
      final product = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      final productData = product as Map<String, dynamic>;

      // Fetch images for this product
      final images = await fetchProductImages(productId);
      
      // Extract image URLs
      final imageUrls = (images as List)
          .map((img) => img['image_url'] as String)
          .toList();

      // Add assembled image data
      productData['image_urls'] = imageUrls;
      productData['image_paths'] = [];

      return productData;
    } catch (e) {
      print('❌ Error fetching product with images: $e');
      rethrow;
    }
  }

  // ==================== AUTHENTICATION ====================

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return {
        'user': response.user,
        'session': response.session,
      };
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      return {
        'user': response.user,
        'session': response.session,
      };
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // ==================== ORDERS ====================

  /// Fetch order by ID
  Future<Map<String, dynamic>> fetchOrderById(String orderId) async {
    try {
      final result = await _client
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();
      return result as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error fetching order: $e');
      rethrow;
    }
  }

  // ==================== PRODUCT PROVIDER ALIASES ====================

  /// Get all active products (alias for getTrendingProducts)
  Future<List<Product>> getAllProducts({int limit = 100}) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('is_active', true)
          .neq('is_sold', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all products: $e');
    }
  }

  /// Create a new product (alias for addProduct)
  Future<String> createProduct(Product product) async {
    return addProduct(product);
  }

  /// Toggle favorite (combine add/remove logic)
  Future<void> toggleFavorite(String productId, String userId) async {
    try {
      // Check if already favorited
      final existing = await _client
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId);

      if ((existing as List).isNotEmpty) {
        // Remove if exists
        await removeFromFavorites(userId, productId);
      } else {
        // Add if doesn't exist
        await addToFavorites(userId, productId);
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile(User user) async {
    try {
      await _client
          .from('users')
          .update(user.toJson())
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Load current user by ID
  Future<User?> getCurrentUser(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return User.fromJson(response);
    } catch (e) {
      print('Error loading current user: $e');
      return null;
    }
  }
}
