import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/models/product.dart';
import 'package:kenza_hub_flutter/services/supabase_service.dart';

class ProductDetailsProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  // State
  Product? _product;
  List<Map<String, dynamic>> _variants = [];
  bool _isLoading = false;
  String? _error;
  
  // Selection state
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  bool _isAddedToCart = false;

  // Getters
  Product? get product => _product;
  List<Map<String, dynamic>> get variants => _variants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedSize => _selectedSize;
  String? get selectedColor => _selectedColor;
  int get quantity => _quantity;
  bool get isAddedToCart => _isAddedToCart;

  // Get unique sizes and colors from variants
  Set<String> get availableSizes {
    return _variants
        .map((v) => v['size']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  Set<String> get availableColors {
    return _variants
        .map((v) => v['color']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet();
  }

  // Load product details
  Future<void> loadProduct(String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final productData = await _supabaseService.fetchProductById(productId);
      _product = Product.fromJson(productData);

      // Load variants
      await _loadVariants(productId);

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _error = 'خطأ في تحميل المنتج: ${e.toString()}';
      print('❌ Error loading product: $e');
    }
    notifyListeners();
  }

  // Load product variants
  Future<void> _loadVariants(String productId) async {
    try {
      _variants = await _supabaseService.fetchProductVariants(productId);
      print('✅ Loaded ${_variants.length} variants');
    } catch (e) {
      print('⚠️ Error loading variants: $e');
    }
  }

  // Select size
  void selectSize(String size) {
    if (_selectedSize != size) {
      _selectedSize = size;
      notifyListeners();
    }
  }

  // Select color
  void selectColor(String color) {
    if (_selectedColor != color) {
      _selectedColor = color;
      notifyListeners();
    }
  }

  // Update quantity
  void setQuantity(int newQuantity) {
    if (newQuantity > 0 && newQuantity <= 100) {
      _quantity = newQuantity;
      notifyListeners();
    }
  }

  // Increment quantity
  void incrementQuantity() {
    setQuantity(_quantity + 1);
  }

  // Decrement quantity
  void decrementQuantity() {
    setQuantity(_quantity - 1);
  }

  // Check if can add to cart
  bool get canAddToCart {
    return _product != null && _product!.isAvailable;
  }

  // Reset selection
  void resetSelection() {
    _selectedSize = null;
    _selectedColor = null;
    _quantity = 1;
    _isAddedToCart = false;
    notifyListeners();
  }

  // Mark as added to cart
  void markAsAddedToCart() {
    _isAddedToCart = true;
    notifyListeners();
  }

  // Retry loading
  Future<void> retry(String productId) async {
    await loadProduct(productId);
  }
}
