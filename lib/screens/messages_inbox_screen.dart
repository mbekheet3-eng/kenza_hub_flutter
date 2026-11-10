import 'package:flutter/material.dart';
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
    setState(_reload);
    await Future.wait([_conversations, _offers, _orders]);
  }

  String _productTitle(Map<String, dynamic> row) {
    final product = row['products'];
    if (product is Map && product['title'] is String) return product['title'] as String;
    return 'منتج من كنزة هب';
  }

  String _date(dynamic value) {
    if (value is! String) return '';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _status(dynamic value) {
    switch (value) {
      case 'pending': return 'في انتظار الرد';
      case 'accepted': return 'مقبول';
      case 'rejected': return 'مرفوض';
      case 'cancelled': return 'ملغي';
      case 'completed': return 'مكتمل';
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
        SnackBar(content: Text(status == 'accepted' ? 'تم القبول' : 'تم الرفض')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث الحالة: $error')),
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
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              Center(child: Text('تعذر تحميل البيانات: ${snapshot.error}')),
              Center(child: TextButton(onPressed: _refresh, child: Text(AppStrings.of(context)!.retryAction))),
            ],
          );
        }
        return content(snapshot.data ?? []);
      },
    );
  }

  Widget _conversationList(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return _empty('لا توجد محادثات حتى الآن');
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        final messages = (row['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        messages.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
        final preview = messages.isEmpty ? 'ابدأ المحادثة' : (messages.first['body']?.toString() ?? 'رسالة');
        final isBuyer = row['buyer_id'] == _userId;
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
          title: Text(_productTitle(row), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${isBuyer ? 'البائع' : 'المشتري'} • $preview', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(_date(row['created_at']), style: Theme.of(context).textTheme.bodySmall),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ConversationScreen(conversationId: row['id'] as String)),
          ).then((_) => _refresh()),
        );
      },
    );
  }

  Widget _transactionList(List<Map<String, dynamic>> rows, {required bool isOffer}) {
    if (rows.isEmpty) return _empty(isOffer ? 'لا توجد عروض حتى الآن' : 'لا توجد طلبات شراء حتى الآن');
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
            '${isOffer ? 'عرض سعر' : 'طلب شراء'}: $price $currency\n'
            '${isSeller ? 'من مشتري' : 'مقدم للبائع'} • ${_status(row['status'])} • ${_date(row['created_at'])}',
          ),
          trailing: isSeller && pending
              ? PopupMenuButton<String>(
                  tooltip: 'إجراء',
                  onSelected: (value) => _updateStatus(table: table, id: row['id'] as String, status: value),
                  itemBuilder: (_) => const [
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
          tabs: const [Tab(text: 'الرسائل'), Tab(text: 'العروض'), Tab(text: 'طلبات الشراء')],
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
