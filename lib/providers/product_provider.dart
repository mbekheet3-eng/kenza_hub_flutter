import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

class ProductProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Product> _products = [];
  Product? _currentProduct;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Product> get products => _products;
  Product? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all products
  Future<void> loadAllProducts() async {
    _setLoading(true);
    try {
      _products = await _supabaseService.getAllProducts();
      _error = null;
    } catch (e) {
      _error = 'فشل تحميل المنتجات: $e';
      print('Error loading products: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get single product by ID
  Future<void> getProduct(String productId) async {
    _setLoading(true);
    try {
      _currentProduct = await _supabaseService.getProduct(productId);
      _error = null;
    } catch (e) {
      _error = 'فشل تحميل المنتج: $e';
      print('Error getting product: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user products
  Future<void> loadUserProducts(String userId) async {
    _setLoading(true);
    try {
      _products = await _supabaseService.getUserProducts(userId);
      _error = null;
    } catch (e) {
      _error = 'فشل تحميل منتجاتك: $e';
      print('Error loading user products: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _setLoading(true);
    try {
      _products = await _supabaseService.searchProducts(query: query);
      _error = null;
    } catch (e) {
      _error = 'فشلت عملية البحث: $e';
      print('Error searching products: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create product
  Future<String?> createProduct(Product product) async {
    _setLoading(true);
    try {
      final productId = await _supabaseService.createProduct(product);
      if (productId != null) {
        await loadUserProducts(product.userId!);
      }
      _error = null;
      return productId;
    } catch (e) {
      _error = 'فشل إنشاء المنتج: $e';
      print('Error creating product: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update product
  Future<bool> updateProduct(Product product) async {
    _setLoading(true);
    try {
      await _supabaseService.updateProduct(product);
      // Update in local list
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
      if (_currentProduct?.id == product.id) {
        _currentProduct = product;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل تحديث المنتج: $e';
      print('Error updating product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    try {
      await _supabaseService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      if (_currentProduct?.id == productId) {
        _currentProduct = null;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل حذف المنتج: $e';
      print('Error deleting product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get products by category
  Future<void> getProductsByCategory(String category) async {
    _setLoading(true);
    try {
      _products = await _supabaseService.getProductsByCategory(category);
      _error = null;
    } catch (e) {
      _error = 'فشل تحميل المنتجات: $e';
      print('Error getting products by category: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String productId, String userId) async {
    try {
      await _supabaseService.toggleFavorite(productId, userId);
      _error = null;
      return true;
    } catch (e) {
      _error = 'فشل تحديث المفضلات: $e';
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Update view count
  Future<void> incrementViewCount(String productId) async {
    try {
      await _supabaseService.incrementProductViews(productId);
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // Private helper
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clear products
  void clearProducts() {
    _products = [];
    _currentProduct = null;
    _error = null;
    notifyListeners();
  }
}
