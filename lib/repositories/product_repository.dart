import 'package:kenza_hub_flutter/core/index.dart';
import 'package:kenza_hub_flutter/models/product.dart';
import 'package:kenza_hub_flutter/services/supabase_service.dart';

/// Repository for product-related operations.
abstract class IProductRepository {
  Future<Result<List<Product>>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int limit,
    int offset,
  });

  Future<Result<List<Product>>> getProductsByCategory(
    String category, {
    int limit,
    int offset,
  });

  Future<Result<List<Product>>> getTrendingProducts({
    int limit,
  });

  Future<Result<Product>> getProductById(String productId);

  Future<Result<List<Product>>> getUserProducts(
    String userId, {
    int limit,
  });

  Future<Result<String>> addProduct(Product product);

  Future<Result<void>> updateProduct(Product product);

  Future<Result<void>> deleteProduct(String productId);

  Future<Result<void>> addProductImages(
    String productId,
    List<String> imageUrls,
  );

  Future<Result<void>> incrementProductViews(String productId);

  Future<Result<void>> addToFavorites(
    String userId,
    String productId,
  );

  Future<Result<void>> removeFromFavorites(
    String userId,
    String productId,
  );

  Future<Result<List<String>>> getUserFavorites(String userId);
}

/// Product repository implementation.
class ProductRepository implements IProductRepository {
  final SupabaseService _supabaseService;

  ProductRepository({
    SupabaseService? supabaseService,
  }) : _supabaseService = supabaseService ?? SupabaseService();

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

      return Success<List<Product>>(products);
    } catch (e) {
      return Failure<List<Product>>(
        ServerAppFailure(
          message: 'Failed to search products: $e',
        ),
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

      return Success<List<Product>>(products);
    } catch (e) {
      return Failure<List<Product>>(
        ServerAppFailure(
          message: 'Failed to get products by category: $e',
        ),
      );
    }
  }

  @override
  Future<Result<List<Product>>> getTrendingProducts({
    int limit = 10,
  }) async {
    try {
      final products = await _supabaseService.getTrendingProducts(
        limit: limit,
      );

      return Success<List<Product>>(products);
    } catch (e) {
      return Failure<List<Product>>(
        ServerAppFailure(
          message: 'Failed to get trending products: $e',
        ),
      );
    }
  }

  @override
  Future<Result<Product>> getProductById(String productId) async {
    try {
      final product = await _supabaseService.getProduct(productId);

      return Success<Product>(product);
    } catch (e) {
      return Failure<Product>(
        ServerAppFailure(
          message: 'Failed to get product: $e',
        ),
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

      return Success<List<Product>>(products);
    } catch (e) {
      return Failure<List<Product>>(
        ServerAppFailure(
          message: 'Failed to get user products: $e',
        ),
      );
    }
  }

  @override
  Future<Result<String>> addProduct(Product product) async {
    try {
      final productId = await _supabaseService.addProduct(product);

      return Success<String>(productId);
    } catch (e) {
      return Failure<String>(
        ServerAppFailure(
          message: 'Failed to add product: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateProduct(Product product) async {
    try {
      await _supabaseService.updateProduct(product);

      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        ServerAppFailure(
          message: 'Failed to update product: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteProduct(String productId) async {
    try {
      await _supabaseService.deleteProduct(productId);

      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        ServerAppFailure(
          message: 'Failed to delete product: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> addProductImages(
    String productId,
    List<String> imageUrls,
  ) async {
    try {
      await _supabaseService.addProductImages(
        productId,
        imageUrls,
      );

      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        ServerAppFailure(
          message: 'Failed to add product images: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> incrementProductViews(
    String productId,
  ) async {
    try {
      await _supabaseService.incrementProductViews(productId);

      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        ServerAppFailure(
          message: 'Failed to increment product views: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> addToFavorites(
    String userId,
    String productId,
  ) async {
    try {
      await _supabaseService.addToFavorites(
        userId,
        productId,
      );

      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        ServerAppFailure(
          message: 'Failed to add product to favorites: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> removeFromFavorites(
    String userId,
    String productId,
  ) async {
    try {
      await _supabaseService.removeFromFavorites(
        userId,
        productId,
      );

      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        ServerAppFailure(
          message: 'Failed to remove product from favorites: $e',
        ),
      );
    }
  }

  @override
  Future<Result<List<String>>> getUserFavorites(
    String userId,
  ) async {
    try {
      final favorites = await _supabaseService.getUserFavorites(
        userId,
      );

      return Success<List<String>>(favorites);
    } catch (e) {
      return Failure<List<String>>(
        ServerAppFailure(
          message: 'Failed to get user favorites: $e',
        ),
      );
    }
  }
}
