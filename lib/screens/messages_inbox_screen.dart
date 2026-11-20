import 'package:material_ui/material_ui.dart';
import '../l10n/app_strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'conversation_screen.dart';
import '../services/notification_service.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _conversations;
  late Future<List<Map<String, dynamic>>> _offers;
  late Future<List<Map<String, dynamic>>> _orders;
  final _notificationService = NotificationService();
  late Stream<List<Map<String, dynamic>>> _notifications;

  String get _userId => _client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _notifications = _notificationService.watchNotifications();
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reload() {
    _conversations = _client.from('conversations')
        .select('id,product_id,buyer_id,seller_id,created_at,products(title),messages(body,created_at)')
        .or('buyer_id.eq.$_userId,seller_id.eq.$_userId')
        .order('created_at', ascending: false);
    _offers = _client.from('product_offers')
        .select('id,product_id,buyer_id,seller_id,offered_price,currency,status,message,created_at,products(title)')
        .or('buyer_id.eq.$_userId,seller_id.eq.$_userId')
        .order('created_at', ascending: false);
    _orders = _client.from('product_orders')
        .select('id,product_id,buyer_id,seller_id,agreed_price,currency,status,created_at,products(title)')
        .or('buyer_id.eq.$_userId,seller_id.eq.$_userId')
        .order('created_at', ascending: false);
  }

  Future<void> _refresh() async {
    setState(() {
      _reload();
      _notifications = _notificationService.watchNotifications();
    });
    await Future.wait([_conversations, _offers, _orders]);
  }

  String _notificationTitle(Map<String, dynamic> row) {
    final strings = AppStrings.of(context)!;
    switch (row['type']?.toString()) {
      case 'new_message':
        return strings.notificationNewMessageTitle;
      case 'new_offer':
        return strings.notificationNewOfferTitle;
      case 'offer_accepted':
        return strings.notificationOfferAcceptedTitle;
      case 'offer_rejected':
        return strings.notificationOfferRejectedTitle;
      case 'new_order':
        return strings.notificationNewOrderTitle;
      case 'order_accepted':
        return strings.notificationOrderAcceptedTitle;
      case 'order_rejected':
        return strings.notificationOrderRejectedTitle;
      case 'order_updated':
        return strings.notificationOrderUpdatedTitle;
      default:
        return row['title']?.toString() ?? strings.newNotification;
    }
  }

  Future<void> _markAllNotificationsRead() async {
    try {
      await _notificationService.markAllAsRead();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.notificationsUpdateError)),
      );
    }
  }

  Future<void> _openNotification(Map<String, dynamic> row) async {
    try {
      if (row['is_read'] != true) {
        await _notificationService.markAsRead(row['id'] as String);
      }
      if (!mounted) return;
      final rawData = row['data'];
      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};
      final conversationId = data['conversation_id']?.toString();
      if (conversationId != null && conversationId.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationScreen(conversationId: conversationId),
          ),
        );
        await _refresh();
      } else {
        final type = row['type']?.toString() ?? '';
        _tabs.animateTo(type.contains('offer') ? 1 : type.contains('order') ? 2 : 0);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.notificationOpenError)),
      );
    }
  }

  Widget _notificationList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notifications,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(AppStrings.of(context)!.notificationsLoadError));
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) return _empty(AppStrings.of(context)!.emptyNotifications);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              final unread = row['is_read'] != true;
              return ListTile(
                onTap: () => _openNotification(row),
                leading: CircleAvatar(
                  child: Icon(row['type'] == 'new_message'
                      ? Icons.chat_bubble_outline
                      : row['type'].toString().contains('offer')
                          ? Icons.local_offer_outlined
                          : row['type'].toString().contains('order')
                              ? Icons.shopping_bag_outlined
                              : Icons.notifications_none_rounded),
                ),
                title: Text(
                  _notificationTitle(row),
                  style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w500),
                ),
                subtitle: Text(
                  '${row['body'] ?? ''}\n${_date(row['created_at'])}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: unread
                    ? Icon(Icons.circle, size: 9, color: Theme.of(context).colorScheme.error)
                    : const Icon(Icons.chevron_right),
              );
            },
          ),
        );
      },
    );
  }

  String _productTitle(Map<String, dynamic> row) {
    final product = row['products'];
    if (product is Map && product['title'] is String) return product['title'] as String;
    return AppStrings.of(context)!.productFallback;
  }

  String _date(dynamic value) {
    if (value is! String) return '';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _status(dynamic value) {
    switch (value) {
      case 'pending': return AppStrings.of(context)!.statusPending;
      case 'accepted': return AppStrings.of(context)!.statusAccepted;
      case 'rejected': return AppStrings.of(context)!.statusRejected;
      case 'cancelled': return AppStrings.of(context)!.statusCancelled;
      case 'completed': return AppStrings.of(context)!.statusCompleted;
      default: return value?.toString() ?? '';
    }
  }

  Future<void> _updateStatus({
    required String table,
    required String id,
    required String status,
  }) async {
    try {
      await _client.from(table).update({'status': status}).eq('id', id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'accepted' ? AppStrings.of(context)!.acceptedToast : AppStrings.of(context)!.rejectedToast)),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.statusUpdateFailed)),
      );
    }
  }

  Widget _empty(String message) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 110),
          Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Center(child: Text(message)),
        ],
      );

  Widget _loadList(
    Future<List<Map<String, dynamic>>> future,
    Widget Function(List<Map<String, dynamic>>) content,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              Center(child: Text(AppStrings.of(context)!.inboxLoadError)),
              Center(child: TextButton(onPressed: _refresh, child: Text(AppStrings.of(context)!.retryAction))),
            ],
          );
        }
        return content(snapshot.data ?? []);
      },
    );
  }

  Widget _conversationList(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return _empty(AppStrings.of(context)!.noConversations);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        final messages = (row['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        messages.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
        final preview = messages.isEmpty ? AppStrings.of(context)!.startConversationShort : (messages.first['body']?.toString() ?? AppStrings.of(context)!.messagePreviewFallback);
        final isBuyer = row['buyer_id'] == _userId;
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
          title: Text(_productTitle(row), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${isBuyer ? AppStrings.of(context)!.sellerRole : AppStrings.of(context)!.buyerRole} • $preview', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(_date(row['created_at']), style: Theme.of(context).textTheme.bodySmall),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ConversationScreen(conversationId: row['id'] as String)),
          ).then((_) => _refresh()),
        );
      },
    );
  }

  Widget _transactionList(List<Map<String, dynamic>> rows, {required bool isOffer}) {
    if (rows.isEmpty) return _empty(isOffer ? AppStrings.of(context)!.noOffers : AppStrings.of(context)!.noPurchaseOrders);
    final table = isOffer ? 'product_offers' : 'product_orders';
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        final isSeller = row['seller_id'] == _userId;
        final pending = row['status'] == 'pending';
        final price = row[isOffer ? 'offered_price' : 'agreed_price'];
        final currency = row['currency'] ?? 'EGP';
        return ListTile(
          isThreeLine: true,
          leading: CircleAvatar(child: Icon(isOffer ? Icons.local_offer_outlined : Icons.shopping_bag_outlined)),
          title: Text(_productTitle(row), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${isOffer ? AppStrings.of(context)!.offerPriceLabel : AppStrings.of(context)!.purchaseOrderLabel}: $price $currency\n'
            '${isSeller ? AppStrings.of(context)!.fromBuyerLabel : AppStrings.of(context)!.submittedToSellerLabel} • ${_status(row['status'])} • ${_date(row['created_at'])}',
          ),
          trailing: isSeller && pending
              ? PopupMenuButton<String>(
                  tooltip: AppStrings.of(context)!.actionTooltipLabel,
                  onSelected: (value) => _updateStatus(table: table, id: row['id'] as String, status: value),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'accepted', child: Text(AppStrings.of(context)!.acceptLabel)),
                    PopupMenuItem(value: 'rejected', child: Text(AppStrings.of(context)!.rejectLabel)),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _tab(Future<List<Map<String, dynamic>>> future, Widget Function(List<Map<String, dynamic>>) content) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _loadList(future, content),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context)!.messagesOrdersTitle),
        actions: [
          TextButton(
            onPressed: _markAllNotificationsRead,
            child: Text(AppStrings.of(context)!.readAll),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: AppStrings.of(context)!.messagesTab),
            Tab(text: AppStrings.of(context)!.offersTab),
            Tab(text: AppStrings.of(context)!.purchaseOrdersTab),
            Tab(text: AppStrings.of(context)!.notificationsTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _tab(_conversations, _conversationList),
          _tab(_offers, (rows) => _transactionList(rows, isOffer: true)),
          _tab(_orders, (rows) => _transactionList(rows, isOffer: false)),
          _notificationList(),
        ],
      ),
    );
  }
}
