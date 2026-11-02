enum OrderStatus {
  pending,
  accepted,
  shipped,
  delivered,
  completed,
  cancelled,
  disputed,
  rejected,
  disputeResolved,
  refundApproved,
  refundRejected,
  returnRequested,
  returnApproved,
  returnReceived,
  refunded,
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
  final String? orderNumber;

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
    this.orderNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final productValue = json['product'] ?? json['products'];
    final product = productValue is Map
        ? Map<String, dynamic>.from(productValue)
        : <String, dynamic>{};
    final imageValue = product['product_images'];
    final imageRows = imageValue is List ? imageValue : const [];
    String? firstImage;
    if (imageRows.isNotEmpty && imageRows.first is Map) {
      firstImage =
          (imageRows.first as Map)['image_url'] as String?;
    }

    return Order(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_profile_id'] as String,
      amount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      status: _statusFromString(json['status'] as String? ?? 'pending'),
      shippingAddress: json['shipping_address'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      shippedAt: null,
      deliveredAt: null,
      notes: null,
      rating: null,
      review: null,
      productTitle: product['title_ar'] as String? ??
          product['title_en'] as String?,
      productImage: firstImage,
      orderNumber: json['order_number'] as String?,
    );
  }

  static OrderStatus _statusFromString(String status) {
    switch (status) {
      case 'pending': return OrderStatus.pending;
      case 'accepted': return OrderStatus.accepted;
      case 'shipped': return OrderStatus.shipped;
      case 'delivered': return OrderStatus.delivered;
      case 'completed': return OrderStatus.completed;
      case 'cancelled': return OrderStatus.cancelled;
      case 'disputed': return OrderStatus.disputed;
      case 'rejected': return OrderStatus.rejected;
      case 'dispute_resolved': return OrderStatus.disputeResolved;
      case 'refund_approved': return OrderStatus.refundApproved;
      case 'refund_rejected': return OrderStatus.refundRejected;
      case 'return_requested': return OrderStatus.returnRequested;
      case 'return_approved': return OrderStatus.returnApproved;
      case 'return_received': return OrderStatus.returnReceived;
      case 'refunded': return OrderStatus.refunded;
      default: return OrderStatus.pending;
    }
  }

  static String _statusToString(OrderStatus status) {
    return status.toString().split('.')[1];
  }

  /// Read/display model serialization only. Order creation is server-controlled.
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'product_id': productId,
      'buyer_id': buyerId,
      'seller_profile_id': sellerId,
      'total_amount': amount,
      'status': _statusToString(status),
      'shipping_address': shippingAddress,
      'tracking_number': trackingNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (orderNumber != null) 'order_number': orderNumber,
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
      case OrderStatus.rejected:
        return 'مرفوض';
      case OrderStatus.disputeResolved:
        return 'تم حل النزاع';
      case OrderStatus.refundApproved:
        return 'تمت الموافقة على الاسترداد';
      case OrderStatus.refundRejected:
        return 'رُفض الاسترداد';
      case OrderStatus.returnRequested:
        return 'طلب إرجاع';
      case OrderStatus.returnApproved:
        return 'تمت الموافقة على الإرجاع';
      case OrderStatus.returnReceived:
        return 'تم استلام المرتجع';
      case OrderStatus.refunded:
        return 'تم رد المبلغ';
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
    String? orderNumber,
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
      orderNumber: orderNumber ?? this.orderNumber,
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
    final newStatus = json['new_status'] as String? ?? 'pending';
    final reason = json['reason'] as String?;
    final action = json['action'] as String? ?? newStatus;
    return OrderTimeline(
      orderId: json['order_id'] as String,
      status: Order._statusFromString(newStatus),
      message: reason?.isNotEmpty == true ? reason! : action,
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      metadata: json['metadata']?.toString(),
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
