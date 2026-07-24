import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

enum OrderStatus {
  pending,
  accepted,
  shipped,
  delivered,
  completed,
  cancelled,
  disputed,
}

@JsonSerializable()
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

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

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

@JsonSerializable()
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

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}

@JsonSerializable()
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

  factory OrderTimeline.fromJson(Map<String, dynamic> json) => _$OrderTimelineFromJson(json);
  Map<String, dynamic> toJson() => _$OrderTimelineToJson(this);
}
