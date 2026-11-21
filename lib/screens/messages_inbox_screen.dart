import 'package:material_ui/material_ui.dart';
import '../widgets/kenza_asset_icon.dart';
import '../l10n/app_strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'conversation_screen.dart';

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
    _tabs = TabController(length: 3, vsync: this);
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
          leading: CircleAvatar(child: KenzaAssetIcon('assets/message.png', size: 22, scale: 1.3)),
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
          leading: CircleAvatar(
            child: isOffer
                ? KenzaAssetIcon('assets/icons/1795220047615-removebg-preview.png', size: 24, scale: 1.3)
                : KenzaAssetIcon('assets/orders.png', size: 24, scale: 1.3),
          ),
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
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(
              icon: Image.asset(
                'assets/icons/1795220040859-removebg-preview.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              text: AppStrings.of(context)!.messagesTab,
            ),
            Tab(
              icon: Image.asset(
                'assets/icons/1795220047615-removebg-preview.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              text: AppStrings.of(context)!.offersTab,
            ),
            Tab(
              icon: Image.asset(
                'assets/icons/1795220032715-removebg-preview.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              text: AppStrings.of(context)!.purchaseOrdersTab,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _tab(_conversations, _conversationList),
          _tab(_offers, (rows) => _transactionList(rows, isOffer: true)),
          _tab(_orders, (rows) => _transactionList(rows, isOffer: false)),
        ],
      ),
    );
  }
}
