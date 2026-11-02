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

  // Shipping and platform fees are calculated in the confirmed order agreement.
  // The client must not invent fees before that agreement exists.
  double get shippingCost => 0;

  double get tax => 0;

  double get total {
    return subtotal + shippingCost + tax;
  }

  String get cartSummary {
    if (_items.isEmpty) return 'السلة فارغة';
    return 'عدد المنتجات: $itemCount • السعر: ${total.toStringAsFixed(2)} ج.م';
  }

  // Add item to cart
  bool addItem({
    required String productId,
    required String title,
    required double price,
    String? imageUrl,
    int quantity = 1,
    String? size,
    String? color,
  }) {
    if (quantity <= 0) return false;

    // Check if item already exists
    final existingItemIndex = _items.indexWhere(
      (item) => item.productId == productId,
    );

    if (existingItemIndex >= 0) {
      // Each listing represents one unique item; do not increase stock quantity.
      return false;
    } else {
      // Add new item
      final cartItem = CartItem(
        id: productId,
        productId: productId,
        title: title,
        price: price,
        imageUrl: imageUrl,
        quantity: 1,
        size: size,
        color: color,
      );
      _items.add(cartItem);
    }

    notifyListeners();
    return true;
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
        // A listing has one unit because the sell flow does not collect stock.
        _items[itemIndex].quantity = 1;
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
    for (final item in json) {
      final loaded = CartItem.fromJson(item as Map<String, dynamic>);
      if (_items.any((existing) => existing.productId == loaded.productId)) {
        continue;
      }
      _items.add(
        CartItem(
          id: loaded.productId,
          productId: loaded.productId,
          title: loaded.title,
          price: loaded.price,
          imageUrl: loaded.imageUrl,
          quantity: 1,
          size: loaded.size,
          color: loaded.color,
        ),
      );
    }
    notifyListeners();
  }
}
