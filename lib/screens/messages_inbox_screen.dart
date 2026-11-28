import 'package:material_ui/material_ui.dart';
import '../widgets/kenza_asset_icon.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
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
        .select('id,product_id,buyer_id,seller_id,offered_price,counter_price,counter_message,countered_at,currency,status,message,created_at,products(title)')
        .or('buyer_id.eq.$_userId,seller_id.eq.$_userId')
        .order('created_at', ascending: false);
    return _attachOtherMemberNames(rows);
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final rows = await _client.from('product_orders')
        .select('id,product_id,buyer_id,seller_id,agreed_price,currency,status,created_at,expires_at,hold_expires_at,postponement_requested_at,postponement_requested_until,postponement_extension_count,quantity,variant_id,variant_color,variant_size,products(title)')
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

  String _dateTime(dynamic value) {
    if (value is! String) return '';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
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
      if (table == 'product_offers' && status == 'accepted') {
        await MarketplaceTransactionService().acceptOffer(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context)!.acceptedToast)),
        );
        await _refresh();
        return;
      }
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
        'withdrawn' => Localizations.localeOf(context).languageCode == 'ar' ? 'تم سحب العرض' : Localizations.localeOf(context).languageCode == 'fr' ? 'Offre retirée' : 'Offer withdrawn',
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
      final language = Localizations.localeOf(context).languageCode;
      final message = error.toString().contains('out_of_stock')
          ? (language == 'ar' ? 'الكمية المطلوبة لم تعد متاحة. حدّث المخزون أو ارفض الطلب.' : language == 'fr' ? 'Stock insuffisant. Actualisez le stock ou refusez la demande.' : 'Requested stock is no longer available. Update stock or reject the request.')
          : AppStrings.of(context)!.statusUpdateFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _counterOffer(Map<String, dynamic> row) async {
    final language = Localizations.localeOf(context).languageCode;
    final priceController = TextEditingController();
    final messageController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(language == 'ar' ? 'إرسال عرض مضاد' : language == 'fr' ? 'Faire une contre-offre' : 'Make a counteroffer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: language == 'ar' ? 'السعر المقترح' : language == 'fr' ? 'Prix proposé' : 'Counter price',
              ),
            ),
            TextField(
              controller: messageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: language == 'ar' ? 'رسالة (اختياري)' : language == 'fr' ? 'Message (facultatif)' : 'Message (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.of(context)!.cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(priceController.text.trim());
              if (price != null && price > 0) {
                Navigator.pop(dialogContext, {
                  'price': price.toString(),
                  'message': messageController.text.trim(),
                });
              }
            },
            child: Text(language == 'ar' ? 'إرسال' : language == 'fr' ? 'Envoyer' : 'Send'),
          ),
        ],
      ),
    );
    priceController.dispose();
    messageController.dispose();
    if (result == null) return;
    try {
      await MarketplaceTransactionService().counterOffer(
        offerId: row['id'] as String,
        counterPrice: double.parse(result['price']!),
        message: result['message'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(language == 'ar' ? 'تم إرسال العرض المضاد' : language == 'fr' ? 'Contre-offre envoyée' : 'Counteroffer sent')),
      );
      await _refresh();
    } catch (_) {
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


  Future<void> _requestPostponement(Map<String, dynamic> row) async {
    final language = Localizations.localeOf(context).languageCode;
    final hold = DateTime.tryParse(row['hold_expires_at']?.toString() ?? '');
    if (hold == null) return;
    final hours = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(language == 'ar' ? 'طلب تأجيل' : language == 'fr' ? 'Demander un délai' : 'Request more time'),
        content: Text(language == 'ar' ? 'اختر مدة التمديد المطلوبة بعد موعد الحجز الحالي.' : language == 'fr' ? 'Choisissez la durée supplémentaire.' : 'Choose the additional time after the current reservation deadline.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, null), child: Text(AppStrings.of(context)!.backLabel)),
          for (final h in [24, 48, 72])
            TextButton(onPressed: () => Navigator.pop(dialogContext, h), child: Text('$h')),
        ],
      ),
    );
    if (hours == null) return;
    try {
      await MarketplaceTransactionService().requestOrderPostponement(orderId: row['id'] as String, requestedUntil: hold.add(Duration(hours: hours)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(language == 'ar' ? 'تم إرسال طلب التأجيل للبائع' : language == 'fr' ? 'Demande envoyée au vendeur' : 'Postponement request sent to seller')));
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.of(context)!.statusUpdateFailed)));
    }
  }

  Future<void> _respondPostponement(String orderId, bool approve) async {
    try {
      await MarketplaceTransactionService().respondOrderPostponement(orderId: orderId, approve: approve);
      if (!mounted) return;
      final language = Localizations.localeOf(context).languageCode;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve
        ? (language == 'ar' ? 'وافقت على التأجيل' : language == 'fr' ? 'Prolongation acceptée' : 'Postponement approved')
        : (language == 'ar' ? 'رفضت التأجيل' : language == 'fr' ? 'Prolongation refusée' : 'Postponement declined'))));
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.of(context)!.statusUpdateFailed)));
    }
  }

  Future<void> _cancelAccepted(Map<String, dynamic> row, {required bool sellerSide}) async {
    final language = Localizations.localeOf(context).languageCode;
    final strings = AppStrings.of(context)!;
    String reason = 'buyer_request';
    String? note;
    if (sellerSide) {
      final selected = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(language == 'ar' ? 'سبب إلغاء الطلب' : language == 'fr' ? 'Motif d’annulation' : 'Cancellation reason'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(title: Text(language == 'ar' ? 'المنتج تالف' : language == 'fr' ? 'Article endommagé' : 'Item damaged'), onTap: () => Navigator.pop(dialogContext, 'item_damaged')),
            ListTile(title: Text(language == 'ar' ? 'المنتج غير موجود' : language == 'fr' ? 'Article introuvable' : 'Item missing'), onTap: () => Navigator.pop(dialogContext, 'item_missing')),
            ListTile(title: Text(language == 'ar' ? 'خطأ في المخزون' : language == 'fr' ? 'Erreur de stock' : 'Stock error'), onTap: () => Navigator.pop(dialogContext, 'stock_error')),
          ]),
        ),
      );
      if (selected == null) return;
      reason = selected;
      final controller = TextEditingController();
      note = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(language == 'ar' ? 'وضح السبب' : language == 'fr' ? 'Précisez le motif' : 'Explain the reason'),
          content: TextField(controller: controller, minLines: 2, maxLines: 4),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(strings.backLabel)),
            TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: Text(strings.confirmAction)),
          ],
        ),
      );
      controller.dispose();
      if (note == null || note.trim().length < 8) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(language == 'ar' ? 'إلغاء الطلب المقبول؟' : language == 'fr' ? 'Annuler la commande acceptée ?' : 'Cancel accepted order?'),
          content: Text(language == 'ar' ? 'سيتم إلغاء الحجز وإعادة إتاحة المنتج.' : language == 'fr' ? 'La réservation sera annulée et l’article remis en disponibilité.' : 'The reservation will be cancelled and the item made available again.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(strings.backLabel)),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(strings.confirmAction)),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await MarketplaceTransactionService().cancelAcceptedOrder(orderId: row['id'] as String, reason: reason, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(language == 'ar' ? 'تم إلغاء الطلب وإعادة المخزون' : language == 'fr' ? 'Commande annulée et stock restauré' : 'Order cancelled and stock restored')));
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.statusUpdateFailed)));
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
        final variantColor = row['variant_color'] as String?;
        final variantSize = row['variant_size'] as String?;
        final quantity = (row['quantity'] as num?)?.toInt() ?? 1;
        final language = Localizations.localeOf(context).languageCode;
        final displayColor = ProductVariant(color: variantColor, size: variantSize, quantity: quantity).colorLabel(language);
        final variantSummary = variantColor == null && variantSize == null ? '' :
          '\n$displayColor${variantColor != null && variantSize != null ? ' / ' : ''}${variantSize ?? ''} • ${language == 'ar' ? 'العدد' : language == 'fr' ? 'Quantité' : 'Qty'}: $quantity';
        final holdDeadline = row['hold_expires_at'];
        final holdSummary = !isOffer && row['status'] == 'accepted' && holdDeadline is String
            ? '\n${language == 'ar' ? 'الحجز حتى' : language == 'fr' ? 'Réservé jusqu’au' : 'Reserved until'}: ${_dateTime(holdDeadline)}'
            : '';
        final postponementSummary = !isOffer && row['postponement_requested_until'] is String
            ? '\n${language == 'ar' ? 'طلب التأجيل حتى' : language == 'fr' ? 'Demande jusqu’au' : 'Requested until'}: ${_dateTime(row['postponement_requested_until'])}'
            : '';
        Widget? trailing;
        if (isSeller && pending) {
          trailing = PopupMenuButton<String>(
            tooltip: AppStrings.of(context)!.actionTooltipLabel,
            onSelected: (value) {
              if (value == 'counter') {
                _counterOffer(row);
              } else {
                _updateStatus(table: table, id: row['id'] as String, status: value);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'accepted',
                child: Text(AppStrings.of(context)!.acceptLabel),
              ),
              PopupMenuItem(
                value: 'rejected',
                child: Text(AppStrings.of(context)!.rejectLabel),
              ),
              if (isOffer)
                PopupMenuItem(
                  value: 'counter',
                  child: Text(language == 'ar' ? 'عرض مضاد' : language == 'fr' ? 'Contre-offre' : 'Counteroffer'),
                ),
            ],
          );
        } else if (isOffer && !isSeller && pending && row['counter_price'] != null) {
          trailing = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _updateStatus(
                  table: 'product_offers',
                  id: row['id'] as String,
                  status: 'accepted',
                ),
                child: Text(language == 'ar' ? 'قبول العرض المضاد' : language == 'fr' ? 'Accepter la contre-offre' : 'Accept counteroffer'),
              ),
              TextButton(
                onPressed: () => _updateStatus(
                  table: 'product_offers',
                  id: row['id'] as String,
                  status: 'withdrawn',
                ),
                child: Text(language == 'ar' ? 'رفض العرض المضاد' : language == 'fr' ? 'Refuser la contre-offre' : 'Decline counteroffer'),
              ),
            ],
          );
        } else if (!isOffer && isSeller && row['status'] == 'accepted') {
          final hasPostponement = row['postponement_requested_at'] != null;
          trailing = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (hasPostponement) ...[
              TextButton(onPressed: () => _respondPostponement(row['id'] as String, true), child: Text(language == 'ar' ? 'موافقة على التأجيل' : language == 'fr' ? 'Accepter' : 'Approve delay')),
              TextButton(onPressed: () => _respondPostponement(row['id'] as String, false), child: Text(language == 'ar' ? 'رفض التأجيل' : language == 'fr' ? 'Refuser' : 'Decline delay')),
            ],
            TextButton(onPressed: () => _confirmOrderStatusChange(id: row['id'] as String, status: 'delivered'), child: Text(AppStrings.of(context)!.markDeliveredLabel)),
            TextButton(onPressed: () => _cancelAccepted(row, sellerSide: true), child: Text(language == 'ar' ? 'إلغاء لسبب حقيقي' : language == 'fr' ? 'Annuler (motif valable)' : 'Cancel for valid reason')),
          ]);
        } else if (!isOffer && !isSeller && pending) {
          trailing = TextButton(
            onPressed: () => _confirmOrderStatusChange(
              id: row['id'] as String,
              status: 'cancelled',
            ),
            child: Text(AppStrings.of(context)!.cancelOrderLabel),
          );
        } else if (!isOffer && !isSeller && row['status'] == 'accepted') {
          final hasPostponement = row['postponement_requested_at'] != null;
          final extended = ((row['postponement_extension_count'] as num?)?.toInt() ?? 0) >= 1;
          trailing = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            TextButton(onPressed: () => _contactSellerForAcceptedOrder(row), child: Text(AppStrings.of(context)!.contactSellerLabel)),
            if (!extended && !hasPostponement)
              TextButton(onPressed: () => _requestPostponement(row), child: Text(language == 'ar' ? 'طلب تأجيل' : language == 'fr' ? 'Demander un délai' : 'Request delay')),
            if (hasPostponement)
              Text(language == 'ar' ? 'طلب التأجيل قيد المراجعة' : language == 'fr' ? 'Demande en attente' : 'Delay request pending'),
            TextButton(onPressed: () => _cancelAccepted(row, sellerSide: false), child: Text(AppStrings.of(context)!.cancelOrderLabel)),
          ]);
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

        final status = row['status']?.toString() ?? '';
        final statusColor = switch (status) {
          'accepted' || 'completed' || 'delivered' => Colors.green,
          'rejected' || 'cancelled' || 'expired' => Theme.of(context).colorScheme.error,
          _ => Theme.of(context).colorScheme.primary,
        };

        return ListTile(
          isThreeLine: true,
          leading: CircleAvatar(
            child: isOffer
                ? KenzaAssetIcon('assets/icons/1795220047615-removebg-preview.png', size: 24, scale: 1.3)
                : KenzaAssetIcon('assets/orders.png', size: 24, scale: 1.3),
          ),
          title: Text(_productTitle(row), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${isOffer ? AppStrings.of(context)!.offerPriceLabel : AppStrings.of(context)!.purchaseOrderLabel}: $price $currency'),
              if (isOffer && row['counter_price'] != null)
                Text('${language == 'ar' ? 'عرض البائع المضاد' : language == 'fr' ? 'Contre-offre du vendeur' : 'Seller counteroffer'}: ${row['counter_price']} $currency'),
              if (isOffer && row['counter_message'] is String && (row['counter_message'] as String).isNotEmpty)
                Text(row['counter_message'] as String),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(_status(status)),
                  side: BorderSide(color: statusColor.withValues(alpha: 0.35)),
                  backgroundColor: statusColor.withValues(alpha: 0.08),
                  labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                  padding: EdgeInsets.zero,
                ),
              ),
              Text('${_otherMemberName(row)} • ${_date(row['created_at'])}$variantSummary$holdSummary$postponementSummary'),
            ],
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
        centerTitle: true,
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
