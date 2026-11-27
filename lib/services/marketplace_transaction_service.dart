import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_locale.dart';
import '../l10n/app_strings.dart';

class MarketplaceTransactionService {
  MarketplaceTransactionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> _requireUserId() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      final strings = await AppStrings.delegate.load(AppLocale.notifier.value);
      throw Exception(strings.loginRequired);
    }
    return id;
  }

  Future<void> createOrder({
    required String productId,
    required String sellerId,
    required double price,
    String? variantId,
    int quantity = 1,
  }) async {
    final userId = await _requireUserId();
    final strings = await AppStrings.delegate.load(AppLocale.notifier.value);
    if (userId == sellerId) throw Exception(strings.ownProductCannotBuy);
    final existingPending = await _client
        .from('product_orders')
        .select('id')
        .eq('product_id', productId)
        .eq('buyer_id', userId)
        .inFilter('status', ['pending', 'accepted', 'delivered'])
        .maybeSingle();
    if (existingPending != null) {
      throw Exception(strings.pendingPurchaseRequestExists);
    }
    try {
      // The database trigger derives buyer, seller, price, currency and
      // expiry from the authenticated session and the current published product.
      // Keep the client-supplied price only as an early UI validation.
      if (price <= 0) throw Exception(strings.priceMustBePositive);
      await _client.from('product_orders').insert({
        'product_id': productId,
        if (variantId != null) 'variant_id': variantId,
        'quantity': quantity,
      });
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception(strings.pendingPurchaseRequestExists);
      }
      rethrow;
    }
  }

  Future<void> createOffer({
    required String productId,
    required String sellerId,
    required double offeredPrice,
    String? message,
  }) async {
    final userId = await _requireUserId();
    final strings = await AppStrings.delegate.load(AppLocale.notifier.value);
    if (userId == sellerId) throw Exception(strings.cannotOfferOwnProduct);
    if (offeredPrice <= 0) throw Exception(strings.priceMustBePositive);
    // The database derives buyer, seller, currency and initial status.
    await _client.from('product_offers').insert({
      'product_id': productId,
      'offered_price': offeredPrice,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
    });
  }


  Future<void> requestOrderPostponement({
    required String orderId,
    required DateTime requestedUntil,
  }) async {
    await _requireUserId();
    await _client.rpc('request_order_postponement', params: {
      'p_order_id': orderId,
      'p_requested_until': requestedUntil.toUtc().toIso8601String(),
    });
  }

  Future<void> respondOrderPostponement({
    required String orderId,
    required bool approve,
  }) async {
    await _requireUserId();
    await _client.rpc('respond_order_postponement', params: {
      'p_order_id': orderId,
      'p_approve': approve,
    });
  }

  Future<void> cancelAcceptedOrder({
    required String orderId,
    required String reason,
    String? note,
  }) async {
    await _requireUserId();
    await _client.rpc('cancel_accepted_order', params: {
      'p_order_id': orderId,
      'p_reason': reason,
      'p_note': note,
    });
  }

  Future<String> getOrCreateConversation({
    required String productId,
    required String sellerId,
  }) async {
    final userId = await _requireUserId();
    final strings = await AppStrings.delegate.load(AppLocale.notifier.value);
    if (userId == sellerId) throw Exception(strings.cannotMessageSelf);
    final existing = await _client
        .from('conversations')
        .select('id')
        .eq('product_id', productId)
        .eq('buyer_id', userId)
        .eq('seller_id', sellerId)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final created = await _client
        .from('conversations')
        .insert({
          'product_id': productId,
          'buyer_id': userId,
          'seller_id': sellerId,
        })
        .select('id')
        .single();
    return created['id'] as String;
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false));
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final rows = await _client
        .from('messages')
        .select('id,sender_id,body,created_at')
        .eq('conversation_id', conversationId)
        .order('created_at');
    return rows;
  }

  Future<void> sendMessage(String conversationId, String body) async {
    final text = body.trim();
    if (text.isEmpty) return;
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': await _requireUserId(),
      'body': text,
    });
  }
}
