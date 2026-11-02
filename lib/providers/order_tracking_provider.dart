import 'package:flutter/material.dart';

import 'package:kenza_hub_flutter/models/order.dart' as order_model;
import 'package:kenza_hub_flutter/services/supabase_service.dart';

class OrderTimelineEvent {
  final String id;
  final String status;
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
      case 'pending': return 'قيد الانتظار';
      case 'accepted': return 'تم القبول';
      case 'shipped': return 'تم الشحن';
      case 'delivered': return 'تم التسليم';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      case 'rejected': return 'مرفوض';
      case 'disputed': return 'قيد النزاع';
      case 'dispute_resolved': return 'تم حل النزاع';
      case 'refund_approved': return 'تمت الموافقة على الاسترداد';
      case 'refund_rejected': return 'رُفض الاسترداد';
      case 'return_requested': return 'طلب إرجاع';
      case 'return_approved': return 'تمت الموافقة على الإرجاع';
      case 'return_received': return 'تم استلام المرتجع';
      case 'refunded': return 'تم رد المبلغ';
      default: return status;
    }
  }

  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'pending': return '⏳';
      case 'accepted': return '✓';
      case 'shipped': return '📦';
      case 'delivered':
      case 'completed':
      case 'refunded': return '✓✓';
      case 'cancelled':
      case 'rejected': return '✗';
      case 'disputed':
      case 'return_requested': return '⚠️';
      default: return '•';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'shipped': return Colors.indigo;
      case 'delivered':
      case 'completed':
      case 'refunded': return Colors.green;
      case 'cancelled':
      case 'rejected':
      case 'refund_rejected': return Colors.red;
      case 'disputed':
      case 'return_requested': return Colors.deepOrange;
      default: return Colors.grey;
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
      case order_model.OrderStatus.pending: return 10;
      case order_model.OrderStatus.accepted: return 35;
      case order_model.OrderStatus.shipped: return 65;
      case order_model.OrderStatus.delivered: return 85;
      case order_model.OrderStatus.completed:
      case order_model.OrderStatus.refunded: return 100;
      case order_model.OrderStatus.cancelled:
      case order_model.OrderStatus.rejected:
      case order_model.OrderStatus.refundRejected: return 0;
      case order_model.OrderStatus.disputed:
      case order_model.OrderStatus.disputeResolved:
      case order_model.OrderStatus.refundApproved:
      case order_model.OrderStatus.returnRequested:
      case order_model.OrderStatus.returnApproved:
      case order_model.OrderStatus.returnReceived: return 50;
    }
  }

  Future<void> loadOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    _timelineEvents = [];
    notifyListeners();

    try {
      final orderData = await _supabaseService.fetchOrderById(orderId);
      _order = order_model.Order.fromJson(orderData);
      _buildTimeline(orderData['order_status_history']);
    } catch (e) {
      _error = 'خطأ في تحميل الطلب: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _buildTimeline(dynamic rawHistory) {
    _timelineEvents = [];
    if (rawHistory is List) {
      final history = rawHistory
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList()
        ..sort((a, b) =>
            (a['created_at']?.toString() ?? '')
                .compareTo(b['created_at']?.toString() ?? ''));

      for (final row in history) {
        final status = row['new_status'] as String? ?? '';
        if (status.isEmpty) continue;
        _timelineEvents.add(
          OrderTimelineEvent(
            id: row['id']?.toString() ??
                '${status}_${row['created_at']?.toString() ?? ''}',
            status: status,
            timestamp: row['created_at']?.toString() ?? '',
            description: (row['reason'] as String?) ??
                (row['action'] as String?),
          ),
        );
      }
    }

    // If older orders have no history rows, show only the known order state.
    if (_timelineEvents.isEmpty && _order != null) {
      _timelineEvents.add(
        OrderTimelineEvent(
          id: _order!.id,
          status: _statusCode(_order!.status),
          timestamp: _order!.createdAt.toIso8601String(),
          description: 'تم تسجيل الطلب',
        ),
      );
    }
  }

  String _statusCode(order_model.OrderStatus status) {
    switch (status) {
      case order_model.OrderStatus.pending: return 'pending';
      case order_model.OrderStatus.accepted: return 'accepted';
      case order_model.OrderStatus.shipped: return 'shipped';
      case order_model.OrderStatus.delivered: return 'delivered';
      case order_model.OrderStatus.completed: return 'completed';
      case order_model.OrderStatus.cancelled: return 'cancelled';
      case order_model.OrderStatus.disputed: return 'disputed';
      case order_model.OrderStatus.rejected: return 'rejected';
      case order_model.OrderStatus.disputeResolved: return 'dispute_resolved';
      case order_model.OrderStatus.refundApproved: return 'refund_approved';
      case order_model.OrderStatus.refundRejected: return 'refund_rejected';
      case order_model.OrderStatus.returnRequested: return 'return_requested';
      case order_model.OrderStatus.returnApproved: return 'return_approved';
      case order_model.OrderStatus.returnReceived: return 'return_received';
      case order_model.OrderStatus.refunded: return 'refunded';
    }
  }

  Future<void> retry(String orderId) => loadOrder(orderId);
}
