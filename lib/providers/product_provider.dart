import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/marketplace_product_service.dart';
import '../services/supabase_service.dart';

class ProductProvider extends ChangeNotifier {
  final MarketplaceProductService _productService =
      MarketplaceProductService();
  final SupabaseService _supabaseService = SupabaseService();

  List<Product> _products = [];
  Product? _currentProduct;
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  Product? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllProducts() async {
    await _run(() async {
      _products = await _productService.fetchActiveProducts();
    }, 'فشل تحميل المنتجات');
  }

  int _productRequestId = 0;

  Future<void> getProduct(String productId) async {
    final requestId = ++_productRequestId;
    _currentProduct = null;
    _setLoading(true);
    try {
      final product = await _productService.fetchProductById(productId);
      if (requestId != _productRequestId) return;
      _currentProduct = product;
      _error = null;
    } catch (e) {
      if (requestId == _productRequestId) {
        _error = 'فشل تحميل المنتج: $e';
      }
    } finally {
      if (requestId == _productRequestId) _setLoading(false);
    }
  }

  Future<void> loadUserProducts(String userId) async {
    await _run(() async {
      _products = await _productService.fetchSellerProducts(userId);
    }, 'فشل تحميل منتجاتك');
  }

  Future<void> searchProducts(String query) async {
    await _run(() async {
      final all = await _productService.fetchActiveProducts(limit: 100);
      final normalized = query.trim().toLowerCase();
      _products = normalized.isEmpty
          ? all
          : all
              .where((product) =>
                  product.title.toLowerCase().contains(normalized) ||
                  product.description.toLowerCase().contains(normalized))
              .toList(growable: false);
    }, 'فشلت عملية البحث');
  }

  /// Publishing must go through SellWizardScreen so the service can resolve
  /// seller membership, lookup IDs and image rows. Do not insert Product.toJson.
  Future<String?> createProduct(Product product) async {
    _error = 'استخدم شاشة نشر المنتج لإتمام التحقق من بيانات البائع والقسم';
    notifyListeners();
    return null;
  }

  Future<bool> updateProduct(Product product) async {
    _setLoading(true);
    try {
      await _productService.updateProductDetails(product);
      final index = _products.indexWhere((item) => item.id == product.id);
      if (index != -1) _products[index] = product;
      if (_currentProduct?.id == product.id) _currentProduct = product;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل تحديث المنتج: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    try {
      await _productService.softDeleteProduct(productId);
      _products.removeWhere((item) => item.id == productId);
      if (_currentProduct?.id == productId) _currentProduct = null;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل إخفاء المنتج: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getProductsByCategory(String category) async {
    await _run(() async {
      final all = await _productService.fetchActiveProducts(limit: 100);
      _products = all
          .where((product) => product.category == category)
          .toList(growable: false);
    }, 'فشل تحميل المنتجات');
  }

  Future<bool> isFavorite(String productId, String userId) async {
    try {
      final favoriteIds = await _supabaseService.getUserFavorites(userId);
      return favoriteIds.contains(productId);
    } catch (_) {
      // A favorite lookup failure must not replace the product-list error state.
      return false;
    }
  }

  Future<bool> toggleFavorite(String productId, String userId) async {
    try {
      await _supabaseService.toggleFavorite(productId, userId);
      _error = null;
      return true;
    } catch (e) {
      _error = 'فشل تحديث المفضلات: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> incrementViewCount(String productId) async {
    await _supabaseService.incrementProductViews(productId);
  }

  Future<void> _run(Future<void> Function() action, String errorPrefix) async {
    _setLoading(true);
    try {
      await action();
      _error = null;
    } catch (e) {
      _error = '$errorPrefix: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearProducts() {
    _productRequestId++;
    _products = [];
    _currentProduct = null;
    _error = null;
    notifyListeners();
  }
}
