import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/models/product.dart';
import 'package:kenza_hub_flutter/services/marketplace_product_service.dart';

class HomeProvider with ChangeNotifier {
  final MarketplaceProductService _productService = MarketplaceProductService();

  // State
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  // ✅ FIXED D5: Use categories that match DATABASE SCHEMA
  // Database supports: clothes, shoes, kids, home
  // UI shows: All, Clothes, Shoes, Kids, Home (5 total)
  final List<String> categories = [
    'الكل',      // 0. All (special - shows all items)
    'ملابس',    // 1. clothes
    'أحذية',    // 2. shoes
    'مستلزمات أطفال',  // 3. kids
    'مستلزمات المنزل',  // 4. home
  ];

  // Mapping between UI labels and database category values
  final Map<String, String> categoryMapping = {
    'الكل': '',           // Empty = show all
    'ملابس': 'clothes',
    'أحذية': 'shoes',
    'مستلزمات أطفال': 'kids',
    'مستلزمات المنزل': 'home',
  };

  // Getters
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  int get productCount => _filteredProducts.length;

  // Initialize
  Future<void> initialize() async {
    await loadProducts();
  }

  // Load products from Supabase
  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _allProducts = await _productService.fetchActiveProducts();

      _applyFilters();
      _isLoading = false;
      _error = null;
    } catch (e) {
      _isLoading = false;
      _error = 'خطأ في تحميل المنتجات: ${e.toString()}';
      print('❌ Error loading products: $e');
    }
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _applyFilters();
      notifyListeners();
    }
  }

  // Search products
  void search(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    }
  }

  // Apply filters and search
  void _applyFilters() {
    _filteredProducts = _allProducts.where((product) {
      // Category filter - use database value from mapping
      final dbCategory = categoryMapping[_selectedCategory] ?? '';
      final categoryMatch = dbCategory.isEmpty ||
          product.category.toLowerCase() == dbCategory.toLowerCase();

      // Search filter
      final searchMatch = _searchQuery.isEmpty ||
          product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory = 'الكل';
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // Retry loading
  Future<void> retry() async {
    await loadProducts();
  }
}
