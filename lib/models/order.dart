enum OrderStatus {
  pending,
  accepted,
  shipped,
  delivered,
  completed,
  cancelled,
  disputed,
}

class Order {
  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final double amount;
  final OrderStatus status;
  final String? shippingAddress;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final String? notes;
  final double? rating;
  final String? review;
  final String? productTitle;
  final String? productImage;
  final String? buyerName;
  final String? sellerName;

  Order({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    required this.status,
    this.shippingAddress,
    this.trackingNumber,
    required this.createdAt,
    required this.updatedAt,
    this.shippedAt,
    this.deliveredAt,
    this.notes,
    this.rating,
    this.review,
    this.productTitle,
    this.productImage,
    this.buyerName,
    this.sellerName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      productId: json['product_id'] as String, // ✅ FIXED: snake_case
      buyerId: json['buyer_id'] as String, // ✅ FIXED: snake_case
      sellerId: json['seller_id'] as String, // ✅ FIXED: snake_case
      amount: (json['amount'] as num).toDouble(),
      status: _statusFromString(json['status'] as String),
      shippingAddress: json['shipping_address'] as String?, // ✅ FIXED: snake_case
      trackingNumber: json['tracking_number'] as String?, // ✅ FIXED: snake_case
      createdAt: DateTime.parse(json['created_at'] as String), // ✅ FIXED: snake_case
      updatedAt: DateTime.parse(json['updated_at'] as String), // ✅ FIXED: snake_case
      shippedAt: json['shipped_at'] == null
          ? null
          : DateTime.parse(json['shipped_at'] as String), // ✅ FIXED: snake_case
      deliveredAt: json['delivered_at'] == null
          ? null
          : DateTime.parse(json['delivered_at'] as String), // ✅ FIXED: snake_case
      notes: json['notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'] as String?,
      productTitle: json['product_title'] as String?, // ✅ FIXED: snake_case
      productImage: json['product_image'] as String?, // ✅ FIXED: snake_case
      buyerName: json['buyer_name'] as String?, // ✅ FIXED: snake_case
      sellerName: json['seller_name'] as String?, // ✅ FIXED: snake_case
    );
  }

  static OrderStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'disputed':
        return OrderStatus.disputed;
      default:
        return OrderStatus.pending;
    }
  }

  static String _statusToString(OrderStatus status) {
    return status.toString().split('.')[1];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId, // ✅ FIXED: snake_case
      'buyer_id': buyerId, // ✅ FIXED: snake_case
      'seller_id': sellerId, // ✅ FIXED: snake_case
      'amount': amount,
      'status': _statusToString(status),
      'shipping_address': shippingAddress, // ✅ FIXED: snake_case
      'tracking_number': trackingNumber, // ✅ FIXED: snake_case
      'created_at': createdAt.toIso8601String(), // ✅ FIXED: snake_case
      'updated_at': updatedAt.toIso8601String(), // ✅ FIXED: snake_case
      'shipped_at': shippedAt?.toIso8601String(), // ✅ FIXED: snake_case
      'delivered_at': deliveredAt?.toIso8601String(), // ✅ FIXED: snake_case
      'notes': notes,
      'rating': rating,
      'review': review,
      'product_title': productTitle, // ✅ FIXED: snake_case
      'product_image': productImage, // ✅ FIXED: snake_case
      'buyer_name': buyerName, // ✅ FIXED: snake_case
      'seller_name': sellerName, // ✅ FIXED: snake_case
    };
  }

  String get statusArabic {
    switch (status) {
      case OrderStatus.pending:
        return 'قيد الانتظار';
      case OrderStatus.accepted:
        return 'مقبول';
      case OrderStatus.shipped:
        return 'تم الشحن';
      case OrderStatus.delivered:
        return 'تم التسليم';
      case OrderStatus.completed:
        return 'مكتمل';
      case OrderStatus.cancelled:
        return 'ملغى';
      case OrderStatus.disputed:
        return 'قيد النزاع';
    }
  }

  Order copyWith({
    String? id,
    String? productId,
    String? buyerId,
    String? sellerId,
    double? amount,
    OrderStatus? status,
    String? shippingAddress,
    String? trackingNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? notes,
    double? rating,
    String? review,
    String? productTitle,
    String? productImage,
    String? buyerName,
    String? sellerName,
  }) {
    return Order(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      buyerName: buyerName ?? this.buyerName,
      sellerName: sellerName ?? this.sellerName,
    );
  }
}

class OrderItem {
  final String orderId;
  final String productId;
  final String title;
  final double price;
  final String imageUrl;
  final int quantity;

  OrderItem({
    required this.orderId,
    required this.productId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderId: json['order_id'] as String, // ✅ FIXED: snake_case
      productId: json['product_id'] as String, // ✅ FIXED: snake_case
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String, // ✅ FIXED: snake_case
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId, // ✅ FIXED: snake_case
      'product_id': productId, // ✅ FIXED: snake_case
      'title': title,
      'price': price,
      'image_url': imageUrl, // ✅ FIXED: snake_case
      'quantity': quantity,
    };
  }
}

class OrderTimeline {
  final String orderId;
  final OrderStatus status;
  final String message;
  final DateTime timestamp;
  final String? metadata;

  OrderTimeline({
    required this.orderId,
    required this.status,
    required this.message,
    required this.timestamp,
    this.metadata,
  });

  factory OrderTimeline.fromJson(Map<String, dynamic> json) {
    return OrderTimeline(
      orderId: json['order_id'] as String, // ✅ FIXED: snake_case
      status: Order._statusFromString(json['status'] as String),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['created_at'] as String), // ✅ FIXED: use created_at
      metadata: json['metadata'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId, // ✅ FIXED: snake_case
      'status': Order._statusToString(status),
      'message': message,
      'created_at': timestamp.toIso8601String(), // ✅ FIXED: use created_at
      'metadata': metadata,
    };
  }
}
