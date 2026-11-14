import 'package:supabase_flutter/supabase_flutter.dart';

class AccountAccessService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> loadCurrentAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Authentication required');

    final roleRow = await _client
        .from('account_roles')
        .select('role')
        .eq('user_id', user.id)
        .eq('role', 'pro_seller')
        .eq('is_active', true)
        .maybeSingle();

    final isAdmin = await _client.rpc('is_kenza_admin') as bool;
    final request = await _client
        .from('pro_seller_requests')
        .select('id,requested_store_name,store_type,store_description,status,admin_note,created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final store = await _client
        .from('stores')
        .select('id,store_name,store_type,description,status')
        .eq('owner_id', user.id)
        .maybeSingle();

    return {
      'role': roleRow == null ? 'buyer' : 'pro_seller',
      'isAdmin': isAdmin,
      'request': request,
      'store': store,
    };
  }

  Future<void> submitProSellerRequest({
    required String storeName,
    required String storeType,
    String? description,
  }) async {
    await _client.rpc('submit_pro_seller_request', params: {
      'p_store_name': storeName.trim(),
      'p_store_type': storeType,
      'p_store_description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingProSellerRequests() async {
    final rows = await _client
        .from('pro_seller_requests')
        .select('id,user_id,requested_store_name,store_type,store_description,created_at')
        .eq('status', 'pending')
        .order('created_at');

    if (rows.isEmpty) return [];

    final userIds = rows
        .map((row) => row['user_id'] as String)
        .toSet()
        .toList();
    final profiles = await _client
        .from('member_public_profiles')
        .select('id,first_name,avatar_url')
        .inFilter('id', userIds);

    final profilesById = <String, Map<String, dynamic>>{
      for (final profile in profiles)
        profile['id'] as String: Map<String, dynamic>.from(profile),
    };

    return rows.map((row) {
      final request = Map<String, dynamic>.from(row);
      request['member_profile'] = profilesById[row['user_id']];
      return request;
    }).toList();
  }

  Future<void> reviewProSellerRequest({
    required String requestId,
    required bool approve,
    String? adminNote,
  }) async {
    await _client.rpc('review_pro_seller_request', params: {
      'p_request_id': requestId,
      'p_decision': approve ? 'approved' : 'rejected',
      'p_admin_note': adminNote?.trim().isEmpty == true
          ? null
          : adminNote?.trim(),
    });
  }
}
