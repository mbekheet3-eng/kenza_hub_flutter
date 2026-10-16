import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/services/supabase_service.dart';

class OrderStatus {
  final String id;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final String timestamp;
  final String? description;
  final String? location;

  OrderStatus({
    required this.id,
    required this.status,
    required this.timestamp,
    this.description,
    this.location,
  });

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد المراجعة';
      case 'confirmed':
        return 'تم التأكيد';
      case 'shipped':
        return 'في الطريق';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏳';
      case 'confirmed':
        return '✓';
      case 'shipped':
        return '📦';
      case 'delivered':
        return '✓✓';
      case 'cancelled':
        return '✗';
      default:
        return '•';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class Order {
  final String id;
  final String buyerId;
  final double totalAmount;
  final String createdAt;
  final String? estimatedDelivery;
  final Map<String, dynamic> shippingAddress;
  final List<OrderStatus> statusHistory;
  final List<Map<String, dynamic>>? items;

  Order({
    required this.id,
    required this.buyerId,
    required this.totalAmount,
    required this.createdAt,
    this.estimatedDelivery,
    required this.shippingAddress,
    required this.statusHistory,
    this.items,
  });

  String get currentStatus => statusHistory.isNotEmpty 
      ? statusHistory.last.status 
      : 'pending';

  OrderStatus? get lastStatus => statusHistory.isNotEmpty 
      ? statusHistory.last 
      : null;

  int get progressPercentage {
    switch (currentStatus.toLowerCase()) {
      case 'pending':
        return 25;
      case 'confirmed':
        return 50;
      case 'shipped':
        return 75;
      case 'delivered':
        return 100;
      case 'cancelled':
        return 0;
      default:
        return 0;
    }
  }

  String get formattedCreatedAt {
    try {
      final dateTime = DateTime.parse(createdAt);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return createdAt;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      estimatedDelivery: json['estimated_delivery'] as String?,
      shippingAddress: json['shipping_address'] as Map<String, dynamic>? ?? {},
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((e) => OrderStatus(
                    id: e['id'] as String? ?? '',
                    status: e['status'] as String? ?? '',
                    timestamp: e['timestamp'] as String? ?? '',
                    description: e['description'] as String?,
                    location: e['location'] as String?,
                  ))
              .toList() ??
          [
            OrderStatus(
              id: '1',
              status: json['status'] as String? ?? 'pending',
              timestamp: json['created_at'] as String,
              description: 'تم استقبال طلبك',
            )
          ],
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

class OrderTrackingProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  Order? _order;
  bool _isLoading = false;
  String? _error;

  Order? get order => _order;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrder(String orderId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch order from Supabase
      final orderData = await _supabaseService.fetchOrderById(orderId);
      _order = Order.fromJson(orderData);

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _error = 'خطأ في تحميل الطلب: ${e.toString()}';
      print('❌ Error loading order: $e');
    }
    notifyListeners();
  }

  // Simulate real-time updates (in real app, use Supabase realtime)
  Future<void> simulateStatusUpdate() async {
    if (_order == null) return;

    try {
      // Simulate delay for status update
      await Future.delayed(const Duration(seconds: 2));

      // Add new status based on current status
      final lastStatus = _order!.statusHistory.last.status.toLowerCase();
      String nextStatus = 'pending';

      switch (lastStatus) {
        case 'pending':
          nextStatus = 'confirmed';
          break;
        case 'confirmed':
          nextStatus = 'shipped';
          break;
        case 'shipped':
          nextStatus = 'delivered';
          break;
        default:
          break;
      }

      if (nextStatus != lastStatus) {
        final newStatus = OrderStatus(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          status: nextStatus,
          timestamp: DateTime.now().toIso8601String(),
          description: _getStatusDescription(nextStatus),
          location: _getStatusLocation(nextStatus),
        );

        _order!.statusHistory.add(newStatus);
        notifyListeners();
        print('✅ Status updated to: $nextStatus');
      }
    } catch (e) {
      print('❌ Error updating status: $e');
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'جاري التحقق من الطلب';
      case 'confirmed':
        return 'تم تأكيد الطلب';
      case 'shipped':
        return 'تم شحن الطلب';
      case 'delivered':
        return 'تم استلام الطلب';
      default:
        return '';
    }
  }

  String _getStatusLocation(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'المستودع الرئيسي - القاهرة';
      case 'confirmed':
        return 'مركز التجميع - القاهرة';
      case 'shipped':
        return 'في الطريق إلى ${_order?.shippingAddress['city'] ?? 'وجهتك'}';
      case 'delivered':
        return '${_order?.shippingAddress['city'] ?? 'وجهتك'}';
      default:
        return '';
    }
  }

  Future<void> retry(String orderId) async {
    await loadOrder(orderId);
  }
}
