import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/services/supabase_service.dart';
import 'package:kenza_hub_flutter/models/order.dart' as order_model;

/// Timeline event for order status tracking
class OrderTimelineEvent {
  final String id;
  final String status; // pending, accepted, shipped, delivered, cancelled
  final String timestamp;
  final String? description;
  final String? location;

  OrderTimelineEvent({
    required this.id,
    required this.status,
    required this.timestamp,
    this.description,
    this.location,
  });

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'تم القبول';
      case 'shipped':
        return 'في الطريق';
      case 'delivered':
        return 'تم التسليم';
      case 'cancelled':
        return 'ملغي';
      case 'completed':
        return 'مكتمل';
      case 'disputed':
        return 'قيد النزاع';
      default:
        return status;
    }
  }

  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'pending':
        return '⏳';
      case 'accepted':
        return '✓';
      case 'shipped':
        return '📦';
      case 'delivered':
        return '✓✓';
      case 'completed':
        return '🎉';
      case 'cancelled':
        return '✗';
      case 'disputed':
        return '⚠️';
      default:
        return '•';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'disputed':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }
}

class OrderTrackingProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  order_model.Order? _order;
  List<OrderTimelineEvent> _timelineEvents = [];
  bool _isLoading = false;
  String? _error;

  order_model.Order? get order => _order;
  List<OrderTimelineEvent> get timelineEvents => _timelineEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get progressPercentage {
    if (_order == null) return 0;
    
    switch (_order!.status) {
      case order_model.OrderStatus.pending:
        return 25;
      case order_model.OrderStatus.accepted:
        return 50;
      case order_model.OrderStatus.shipped:
        return 75;
      case order_model.OrderStatus.delivered:
      case order_model.OrderStatus.completed:
        return 100;
      case order_model.OrderStatus.cancelled:
      case order_model.OrderStatus.disputed:
        return 0;
    }
  }

  Future<void> loadOrder(String orderId) async {
    try {
      _isLoading = true;
      _error = null;
      _timelineEvents.clear();
      notifyListeners();

      // Fetch order from Supabase
      final orderData = await _supabaseService.fetchOrderById(orderId);
      _order = order_model.Order.fromJson(orderData);

      // Build timeline from order
      _buildTimeline();

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _error = 'خطأ في تحميل الطلب: ${e.toString()}';
      print('❌ Error loading order: $e');
    }
    notifyListeners();
  }

  void _buildTimeline() {
    if (_order == null) return;

    _timelineEvents.clear();

    // Add initial event
    _timelineEvents.add(
      OrderTimelineEvent(
        id: '1',
        status: 'pending',
        timestamp: _order!.createdAt.toIso8601String(),
        description: 'تم استقبال طلبك',
        location: 'المستودع الرئيسي - القاهرة',
      ),
    );

    // Add current status event
    if (_order!.status != order_model.OrderStatus.pending) {
      _timelineEvents.add(
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          status: _order!.status.toString().split('.')[1],
          timestamp: _order!.updatedAt.toIso8601String(),
          description: _getStatusDescription(_order!.status),
          location: _getStatusLocation(_order!.status),
        ),
      );
    }
  }

  String _getStatusDescription(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return 'جاري التحقق من الطلب';
      case order_model.OrderStatus.accepted:
        return 'تم قبول الطلب';
      case order_model.OrderStatus.shipped:
        return 'تم شحن الطلب';
      case order_model.OrderStatus.delivered:
        return 'تم استلام الطلب';
      case order_model.OrderStatus.completed:
        return 'اكتمل الطلب';
      case order_model.OrderStatus.cancelled:
        return 'تم إلغاء الطلب';
      case order_model.OrderStatus.disputed:
        return 'الطلب قيد النزاع';
    }
  }

  String _getStatusLocation(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending:
        return 'المستودع الرئيسي - القاهرة';
      case order_model.OrderStatus.accepted:
        return 'مركز التجميع - القاهرة';
      case order_model.OrderStatus.shipped:
        return 'في الطريق';
      case order_model.OrderStatus.delivered:
      case order_model.OrderStatus.completed:
        return _order?.shippingAddress ?? 'وجهتك';
      case order_model.OrderStatus.cancelled:
      case order_model.OrderStatus.disputed:
        return '';
    }
  }

  // Simulate real-time updates (for testing)
  Future<void> simulateStatusUpdate() async {
    if (_order == null) return;

    try {
      await Future.delayed(const Duration(seconds: 2));
      print('✅ Status simulation completed');
    } catch (e) {
      print('❌ Error in simulation: $e');
    }
  }

  Future<void> retry(String orderId) async {
    await loadOrder(orderId);
  }
}
