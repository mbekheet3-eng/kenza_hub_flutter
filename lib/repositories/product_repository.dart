import 'package:kenza_hub/core/index.dart';
import 'package:kenza_hub/models/product.dart';
import 'package:kenza_hub/services/supabase_service.dart';

/// Abstract Product Repository Interface
abstract class IProductRepository {
  /// البحث عن المنتجات
  Future<Result<List<Product>>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int limit,
    int offset,
  });

  /// الحصول على منتجات الفئة
  Future<Result<List<Product>>> getProductsByCategory(
    String category, {
    int limit,
    int offset,
  });

  /// الحصول على المنتجات الرائجة
  Future<Result<List<Product>>> getTrendingProducts({int limit});

  /// الحصول على منتج بـ ID
  Future<Result<Product>> getProductById(String productId);

  /// الحصول على منتجات المستخدم
  Future<Result<List<Product>>> getUserProducts(
    String userId, {
    int limit,
  });

  /// إضافة منتج جديد
  Future<Result<String>> addProduct(Product product);

  /// تحديث منتج
  Future<Result<void>> updateProduct(Product product);

  /// حذف منتج
  Future<Result<void>> deleteProduct(String productId);

  /// إضافة صور للمنتج
  Future<Result<void>> addProductImages(
    String productId,
    List<String> imageUrls,
  );

  /// زيادة عدد المشاهدات
  Future<Result<void>> incrementProductViews(String productId);

  /// إضافة المنتج للمفضلة
  Future<Result<void>> addToFavorites(
    String userId,
    String productId,
  );

  /// إزالة من المفضلة
  Future<Result<void>> removeFromFavorites(
    String userId,
    String productId,
  );

  /// الحصول على المفضلات
  Future<Result<List<String>>> getUserFavorites(String userId);
}

/// Product Repository Implementation
class ProductRepository implements IProductRepository {
  final SupabaseService _supabaseService;

  ProductRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  @override
  Future<Result<List<Product>>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int limit = AppConstants.defaultPageSize,
    int offset = AppConstants.defaultOffset,
  }) async {
    try {
      final products = await _supabaseService.searchProducts(
        query: query,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        limit: limit,
        offset: offset,
      );
      return Success(products);
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } on NetworkException catch (e) {
      return Failure(
        NetworkAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to search products: $e'),
      );
    }
  }

  @override
  Future<Result<List<Product>>> getProductsByCategory(
    String category, {
    int limit = AppConstants.defaultPageSize,
    int offset = AppConstants.defaultOffset,
  }) async {
    try {
      final products = await _supabaseService.getProductsByCategory(
        category,
        limit: limit,
        offset: offset,
      );
      return Success(products);
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } on NetworkException catch (e) {
      return Failure(
        NetworkAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to get products by category: $e'),
      );
    }
  }

  @override
  Future<Result<List<Product>>> getTrendingProducts({int limit = 10}) async {
    try {
      final products = await _supabaseService.getTrendingProducts(limit: limit);
      return Success(products);
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } on NetworkException catch (e) {
      return Failure(
        NetworkAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to get trending products: $e'),
      );
    }
  }

  @override
  Future<Result<Product>> getProductById(String productId) async {
    try {
      final product = await _supabaseService.getProduct(productId);
      return Success(product);
    } on NotFoundException catch (e) {
      return Failure(
        NotFoundAppFailure(message: e.message, code: e.code),
      );
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to get product: $e'),
      );
    }
  }

  @override
  Future<Result<List<Product>>> getUserProducts(
    String userId, {
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      final products = await _supabaseService.getUserProducts(
        userId,
        limit: limit,
      );
      return Success(products);
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to get user products: $e'),
      );
    }
  }

  @override
  Future<Result<String>> addProduct(Product product) async {
    try {
      final productId = await _supabaseService.addProduct(product);
      return Success(productId);
    } on ValidationException catch (e) {
      return Failure(
        ValidationAppFailure(message: e.message, code: e.code),
      );
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to add product: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateProduct(Product product) async {
    try {
      await _supabaseService.updateProduct(product);
      return Success(null);
    } on ValidationException catch (e) {
      return Failure(
        ValidationAppFailure(message: e.message, code: e.code),
      );
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to update product: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteProduct(String productId) async {
    try {
      await _supabaseService.deleteProduct(productId);
      return Success(null);
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to delete product: $e'),
      );
    }
  }

  @override
  Future<Result<void>> addProductImages(
    String productId,
    List<String> imageUrls,
  ) async {
    try {
      await _supabaseService.addProductImages(productId, imageUrls);
      return Success(null);
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to add product images: $e'),
      );
    }
  }

  @override
  Future<Result<void>> incrementProductViews(String productId) async {
    try {
      await _supabaseService.incrementProductViews(productId);
      return Success(null);
    } catch (e) {
      // Silent failure - not critical
      return Success(null);
    }
  }

  @override
  Future<Result<void>> addToFavorites(
    String userId,
    String productId,
  ) async {
    try {
      await _supabaseService.addToFavorites(userId, productId);
      return Success(null);
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to add to favorites: $e'),
      );
    }
  }

  @override
  Future<Result<void>> removeFromFavorites(
    String userId,
    String productId,
  ) async {
    try {
      await _supabaseService.removeFromFavorites(userId, productId);
      return Success(null);
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to remove from favorites: $e'),
      );
    }
  }

  @override
  Future<Result<List<String>>> getUserFavorites(String userId) async {
    try {
      final favorites = await _supabaseService.getUserFavorites(userId);
      return Success(favorites);
    } on ServerException catch (e) {
      return Failure(
        ServerAppFailure(message: e.message, code: e.code),
      );
    } catch (e) {
      return Failure(
        UnknownAppFailure(message: 'Failed to get favorites: $e'),
      );
    }
  }
}
