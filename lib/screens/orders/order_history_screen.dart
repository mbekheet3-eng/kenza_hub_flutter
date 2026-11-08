import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kenza_hub_flutter/providers/auth_provider.dart';
import 'package:kenza_hub_flutter/services/supabase_service.dart';
import 'package:kenza_hub_flutter/models/order.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Future<List<Order>>? _ordersFuture;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders({bool force = false}) {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      _loadedUserId = null;
      _ordersFuture = null;
      return;
    }
    if (!force && _loadedUserId == userId && _ordersFuture != null) return;

    _loadedUserId = userId;
    _ordersFuture = Future.wait([
      _supabaseService.getUserOrders(userId, asBuyer: true),
      _supabaseService.getUserOrders(userId, asBuyer: false),
    ]).then((groups) {
      final byId = <String, Order>{};
      for (final order in groups.expand((group) => group)) {
        byId[order.id] = order;
      }
      final combined = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return combined;
    });
  }

  Future<void> _refreshOrders() async {
    _loadOrders(force: true);
    final future = _ordersFuture;
    if (future != null) {
      try {
        await future;
      } catch (_) {
        // The FutureBuilder below presents the error state.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).ordersHistory),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).loginToViewOrders),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: Text(AppLocalizations.of(context).login),
              ),
            ],
          ),
        ),
      );
    }

    _loadOrders();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).ordersHistory),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture!,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${AppLocalizations.of(context).error}: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _loadOrders(force: true));
                    },
                    child: Text(AppLocalizations.of(context).retry),
                  ),
                  ],
                  ),
                ),
              ],
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Center(child: Text(AppLocalizations.of(context).noOrders)),
                ),
              ],
            );
          }

          final orders = snapshot.data!;

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: orders.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header: ID + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context).orderPrefix} #${order.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context).dateLabel}: ${order.createdAt.toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusArabic,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // Product title
            if (order.productTitle != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.productTitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
              ),

            // Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).amountLabel,
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  '${order.amount.toStringAsFixed(2)} ${AppLocalizations.of(context).currency}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/order-tracking/${order.id}');
                },
                child: Text(AppLocalizations.of(context).orderDetails),
              ),
            ),
            if (order.status == OrderStatus.disputed) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/dispute-evidence/${order.id}'),
                  icon: const Icon(Icons.attach_file),
                  label: Text(AppLocalizations.of(context).disputeEvidenceLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.lightGreen;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.disputed:
      case OrderStatus.returnRequested:
        return Colors.redAccent;
      case OrderStatus.rejected:
      case OrderStatus.refundRejected:
        return Colors.red;
      case OrderStatus.disputeResolved:
      case OrderStatus.refundApproved:
      case OrderStatus.returnApproved:
      case OrderStatus.returnReceived:
      case OrderStatus.refunded:
        return Colors.green;
    }
  }
}
