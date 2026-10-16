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
      productId: json['productId'] as String,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: _statusFromString(json['status'] as String),
      shippingAddress: json['shippingAddress'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      shippedAt: json['shippedAt'] == null
          ? null
          : DateTime.parse(json['shippedAt'] as String),
      deliveredAt: json['deliveredAt'] == null
          ? null
          : DateTime.parse(json['deliveredAt'] as String),
      notes: json['notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'] as String?,
      productTitle: json['productTitle'] as String?,
      productImage: json['productImage'] as String?,
      buyerName: json['buyerName'] as String?,
      sellerName: json['sellerName'] as String?,
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
      'productId': productId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'amount': amount,
      'status': _statusToString(status),
      'shippingAddress': shippingAddress,
      'trackingNumber': trackingNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'shippedAt': shippedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'notes': notes,
      'rating': rating,
      'review': review,
      'productTitle': productTitle,
      'productImage': productImage,
      'buyerName': buyerName,
      'sellerName': sellerName,
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
      orderId: json['orderId'] as String,
      productId: json['productId'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'productId': productId,
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
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
      orderId: json['orderId'] as String,
      status: Order._statusFromString(json['status'] as String),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'status': Order._statusToString(status),
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
