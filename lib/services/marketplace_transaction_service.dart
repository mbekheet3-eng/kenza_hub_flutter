import 'package:supabase_flutter/supabase_flutter.dart';

class MarketplaceTransactionService {
  MarketplaceTransactionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('يجب تسجيل الدخول أولاً');
    return id;
  }

  Future<void> createOrder({
    required String productId,
    required String sellerId,
    required double price,
  }) async {
    if (_userId == sellerId) throw Exception('لا يمكنك طلب منتجك');
    await _client.from('product_orders').insert({
      'product_id': productId,
      'buyer_id': _userId,
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
    if (_userId == sellerId) throw Exception('لا يمكنك تقديم عرض على منتجك');
    if (offeredPrice <= 0) throw Exception('أدخل سعرًا صحيحًا');
    await _client.from('product_offers').insert({
      'product_id': productId,
      'buyer_id': _userId,
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
    if (_userId == sellerId) throw Exception('لا يمكنك مراسلة نفسك');
    final existing = await _client
        .from('conversations')
        .select('id')
        .eq('product_id', productId)
        .eq('buyer_id', _userId)
        .eq('seller_id', sellerId)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final created = await _client
        .from('conversations')
        .insert({
          'product_id': productId,
          'buyer_id': _userId,
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
      'sender_id': _userId,
      'body': text,
    });
    await _client
        .from('conversations')
        .update({'last_message_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', conversationId);
  }
}
