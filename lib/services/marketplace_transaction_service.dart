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
  }) async {
    final userId = await _requireUserId();
    final strings = await AppStrings.delegate.load(AppLocale.notifier.value);
    if (userId == sellerId) throw Exception(strings.ownProductCannotBuy);
    await _client.from('product_orders').insert({
      'product_id': productId,
      'buyer_id': userId,
      'seller_id': sellerId,
      'agreed_price': price,
      'currency': 'EGP',
      'status': 'pending',
    });
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
    await _client.from('product_offers').insert({
      'product_id': productId,
      'buyer_id': userId,
      'seller_id': sellerId,
      'offered_price': offeredPrice,
      'currency': 'EGP',
      'status': 'pending',
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
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
