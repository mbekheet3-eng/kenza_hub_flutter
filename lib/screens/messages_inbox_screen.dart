import 'package:material_ui/material_ui.dart';
import '../widgets/kenza_asset_icon.dart';
import '../l10n/app_strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'conversation_screen.dart';
import '../services/marketplace_transaction_service.dart';

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

  String get _userId => _client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reload() {
    _conversations = _loadConversations();
    _offers = _loadOffers();
    _orders = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _attachOtherMemberNames(
    List<dynamic> rawRows,
  ) async {
    final rows = rawRows.cast<Map<String, dynamic>>();
    final otherMemberIds = rows.map((row) {
      return row['buyer_id'] == _userId
          ? row['seller_id'] as String
          : row['buyer_id'] as String;
    }).toSet().toList();

    if (otherMemberIds.isEmpty) return [];

    final profiles = await _client
        .from('member_public_profiles')
        .select('id,first_name')
        .inFilter('id', otherMemberIds);
    final names = {
      for (final profile in profiles)
        profile['id'] as String: profile['first_name'] as String?,
    };

    return rows.map((row) {
      final otherId = row['buyer_id'] == _userId
          ? row['seller_id'] as String
          : row['buyer_id'] as String;
      return {
        ...row,
        '_other_member_name': names[otherId],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _loadConversations() async {
    final rows = await _client.from('conversations')
        .select('id,product_id,buyer_id,seller_id,created_at,products(title),messages(body,created_at)')
        .or('buyer_id.eq.$_userId,seller_id.eq.$_userId')
        .order('created_at', ascending: false);
    return _attachOtherMemberNames(rows);
  }

  Future<List<Map<String, dynamic>>> _loadOffers() async {
    final rows = await _client.from('product_offers')
        .select('id,product_id,buyer_id,seller_id,offered_price,currency,status,message,created_at,products(title)')
        .or('buyer_id.eq.$_userId,seller_id.eq.$_userId')
        .order('created_at', ascending: false);
    return _attachOtherMemberNames(rows);
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final rows = await _client.from('product_orders')
        .select('id,product_id,buyer_id,seller_id,agreed_price,currency,status,created_at,expires_at,quantity,variant_id,product_variants(color,size),products(title)')
        .or('buyer_id.eq.$_userId,seller_id.eq.$_userId')
        .order('created_at', ascending: false);
    return _attachOtherMemberNames(rows);
  }

  String _otherMemberName(Map<String, dynamic> row) {
    final name = row['_other_member_name'] as String?;
    return name?.trim().isNotEmpty == true
        ? name!.trim()
        : AppStrings.of(context)!.memberFallback;
  }

  Future<void> _refresh() async {
    setState(() {
      _reload();
    });
    await Future.wait([_conversations, _offers, _orders]);
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
      case 'delivered': return AppStrings.of(context)!.statusDelivered;
      case 'expired': return AppStrings.of(context)!.statusExpired;
      default: return value?.toString() ?? '';
    }
  }

  Future<void> _updateStatus({
    required String table,
    required String id,
    required String status,
  }) async {
    try {
      final updated = await _client
          .from(table)
          .update({'status': status})
          .eq('id', id)
          .select('id')
          .maybeSingle();
      if (updated == null) throw StateError('The status was not changed');
      if (!mounted) return;
      final strings = AppStrings.of(context)!;
      final message = switch (status) {
        'accepted' => strings.acceptedToast,
        'rejected' => strings.rejectedToast,
        'delivered' => strings.orderDeliveredToast,
        'cancelled' => strings.orderCancelledToast,
        'completed' => strings.orderCompletedToast,
        _ => strings.statusUpdateFailed,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.statusUpdateFailed)),
      );
    }
  }

  Future<void> _confirmOrderStatusChange({
    required String id,
    required String status,
  }) async {
    final strings = AppStrings.of(context)!;
    final completing = status == 'completed';
    final delivering = status == 'delivered';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(completing
            ? strings.confirmCompleteOrderTitle
            : delivering
                ? strings.confirmMarkDeliveredTitle
                : strings.confirmCancelOrderTitle),
        content: Text(completing
            ? strings.confirmCompleteOrderBody
            : delivering
                ? strings.confirmMarkDeliveredBody
                : strings.confirmCancelOrderBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.backLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.confirmAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateStatus(
        table: 'product_orders',
        id: id,
        status: status,
      );
    }
  }

  Future<void> _contactSellerForAcceptedOrder(Map<String, dynamic> row) async {
    try {
      final service = MarketplaceTransactionService();
      final conversationId = await service.getOrCreateConversation(
        productId: row['product_id'] as String,
        sellerId: row['seller_id'] as String,
      );
      final title = _productTitle(row);
      final price = row['agreed_price'];
      final currency = row['currency'] ?? 'EGP';
      final language = Localizations.localeOf(context).languageCode;
      final message = switch (language) {
        'fr' => 'Bonjour, je souhaite finaliser l’achat de « $title » au prix de $price $currency.',
        'en' => 'Hello, I would like to complete the purchase of "$title" at $price $currency.',
        _ => 'مرحبًا، أرغب في استكمال طلب شراء "$title" بسعر $price $currency.',
      };

      final existingMessages = await service.getMessages(conversationId);
      final alreadySent = existingMessages.any((item) => item['body'] == message);
      if (!alreadySent) {
        await service.sendMessage(conversationId, message);
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(conversationId: conversationId),
        ),
      );
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.conversationOpenFailed)),
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
        return ListTile(
          leading: CircleAvatar(child: KenzaAssetIcon('assets/message.png', size: 24, scale: 1.3)),
          title: Text(_productTitle(row), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${_otherMemberName(row)} • $preview', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(_date(row['created_at']), style: Theme.of(context).textTheme.bodySmall),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ConversationScreen(conversationId: row['id'] as String)),
          ).then((_) => _refresh()),
        );
      },
    );
  }

  Widget _transactionList(
    List<Map<String, dynamic>> rows, {
    required bool isOffer,
    bool? sellerSide,
  }) {
    final visibleRows = sellerSide == null
        ? rows
        : rows.where((row) => (row['seller_id'] == _userId) == sellerSide).toList();
    if (visibleRows.isEmpty) return _empty(isOffer ? AppStrings.of(context)!.noOffers : AppStrings.of(context)!.noPurchaseOrders);
    final table = isOffer ? 'product_offers' : 'product_orders';
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: visibleRows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = visibleRows[index];
        final isSeller = row['seller_id'] == _userId;
        final pending = row['status'] == 'pending';
        final price = row[isOffer ? 'offered_price' : 'agreed_price'];
        final currency = row['currency'] ?? 'EGP';
        final variant = row['product_variants'] as Map<String, dynamic>?;
        final quantity = (row['quantity'] as num?)?.toInt() ?? 1;
        final variantSummary = variant == null ? '' :
          '\n${variant['color'] ?? ''}${variant['color'] != null && variant['size'] != null ? ' / ' : ''}${variant['size'] ?? ''} • العدد: $quantity';
        Widget? trailing;
        if (isSeller && pending) {
          trailing = PopupMenuButton<String>(
            tooltip: AppStrings.of(context)!.actionTooltipLabel,
            onSelected: (value) => _updateStatus(
              table: table,
              id: row['id'] as String,
              status: value,
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'accepted',
                child: Text(AppStrings.of(context)!.acceptLabel),
              ),
              PopupMenuItem(
                value: 'rejected',
                child: Text(AppStrings.of(context)!.rejectLabel),
              ),
            ],
          );
        } else if (!isOffer && isSeller && row['status'] == 'accepted') {
          trailing = TextButton(
            onPressed: () => _confirmOrderStatusChange(
              id: row['id'] as String,
              status: 'delivered',
            ),
            child: Text(AppStrings.of(context)!.markDeliveredLabel),
          );
        } else if (!isOffer && !isSeller && pending) {
          trailing = TextButton(
            onPressed: () => _confirmOrderStatusChange(
              id: row['id'] as String,
              status: 'cancelled',
            ),
            child: Text(AppStrings.of(context)!.cancelOrderLabel),
          );
        } else if (!isOffer && !isSeller && row['status'] == 'accepted') {
          trailing = TextButton(
            onPressed: () => _contactSellerForAcceptedOrder(row),
            child: Text(AppStrings.of(context)!.contactSellerLabel),
          );
        } else if (!isOffer && !isSeller && row['status'] == 'delivered') {
          trailing = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _contactSellerForAcceptedOrder(row),
                child: Text(AppStrings.of(context)!.contactSellerLabel),
              ),
              TextButton(
                onPressed: () => _confirmOrderStatusChange(
                  id: row['id'] as String,
                  status: 'completed',
                ),
                child: Text(AppStrings.of(context)!.completeOrderLabel),
              ),
            ],
          );
        }

        return ListTile(
          isThreeLine: true,
          leading: CircleAvatar(
            child: isOffer
                ? KenzaAssetIcon('assets/icons/1795220047615-removebg-preview.png', size: 24, scale: 1.3)
                : KenzaAssetIcon('assets/orders.png', size: 24, scale: 1.3),
          ),
          title: Text(_productTitle(row), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${isOffer ? AppStrings.of(context)!.offerPriceLabel : AppStrings.of(context)!.purchaseOrderLabel}: $price $currency\n'
            '${_otherMemberName(row)} • ${_status(row['status'])} • ${_date(row['created_at'])}$variantSummary',
          ),
          trailing: trailing,
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
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(
              icon: KenzaAssetIcon('assets/icons/1795220040859-removebg-preview.png', size: 28, scale: 1.3),
              text: AppStrings.of(context)!.messagesTab,
            ),
            Tab(
              icon: KenzaAssetIcon('assets/icons/1795220047615-removebg-preview.png', size: 28, scale: 1.3),
              text: AppStrings.of(context)!.offersTab,
            ),
            Tab(
              icon: KenzaAssetIcon('assets/icons/1795220032715-removebg-preview.png', size: 28, scale: 1.3),
              text: AppStrings.of(context)!.sentPurchaseOrdersTab,
            ),
            Tab(
              icon: KenzaAssetIcon('assets/icons/1795220032715-removebg-preview.png', size: 28, scale: 1.3),
              text: AppStrings.of(context)!.receivedPurchaseOrdersTab,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _tab(_conversations, _conversationList),
          _tab(_offers, (rows) => _transactionList(rows, isOffer: true)),
          _tab(_orders, (rows) => _transactionList(rows, isOffer: false, sellerSide: false)),
          _tab(_orders, (rows) => _transactionList(rows, isOffer: false, sellerSide: true)),
        ],
      ),
    );
  }
}
