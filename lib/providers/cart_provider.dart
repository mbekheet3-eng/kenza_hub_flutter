import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String productId;
  final String title;
  final double price;
  final String? imageUrl;
  int quantity;
  final String? size;
  final String? color;

  CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.price,
    this.imageUrl,
    required this.quantity,
    this.size,
    this.color,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'title': title,
    'price': price,
    'image_url': imageUrl,
    'quantity': quantity,
    'size': size,
    'color': color,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    productId: json['product_id'] as String,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    imageUrl: json['image_url'] as String?,
    quantity: json['quantity'] as int,
    size: json['size'] as String?,
    color: json['color'] as String?,
  );
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get shippingCost {
    // Simple shipping calculation
    return subtotal > 200 ? 0 : 30; // Free shipping above 200 EGP
  }

  double get tax {
    return subtotal * 0.14; // 14% tax
  }

  double get total {
    return subtotal + shippingCost + tax;
  }

  String get cartSummary {
    if (_items.isEmpty) return 'السلة فارغة';
    return 'عدد المنتجات: $itemCount • السعر: ${total.toStringAsFixed(2)} ريال';
  }

  // Add item to cart
  void addItem({
    required String productId,
    required String title,
    required double price,
    String? imageUrl,
    int quantity = 1,
    String? size,
    String? color,
  }) {
    // Check if item already exists
    final existingItemIndex = _items.indexWhere(
      (item) =>
          item.productId == productId &&
          item.size == size &&
          item.color == color,
    );

    if (existingItemIndex >= 0) {
      // Update quantity
      _items[existingItemIndex].quantity += quantity;
    } else {
      // Add new item
      final cartItem = CartItem(
        id: '${productId}_${size}_$color',
        productId: productId,
        title: title,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
        size: size,
        color: color,
      );
      _items.add(cartItem);
    }

    notifyListeners();
  }

  // Remove item from cart
  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  // Update quantity
  void updateQuantity(String itemId, int newQuantity) {
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex >= 0) {
      if (newQuantity <= 0) {
        removeItem(itemId);
      } else {
        _items[itemIndex].quantity = newQuantity;
        notifyListeners();
      }
    }
  }

  // Clear cart
  void clear() {
    _items.clear();
    notifyListeners();
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  // Get cart JSON for order
  List<Map<String, dynamic>> getCartJson() {
    return _items.map((item) => item.toJson()).toList();
  }

  // Load cart from JSON
  void loadFromJson(List<dynamic> json) {
    _items.clear();
    for (var item in json) {
      _items.add(CartItem.fromJson(item as Map<String, dynamic>));
    }
    notifyListeners();
  }
}
