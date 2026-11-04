import 'package:supabase_flutter/supabase_flutter.dart';

import 'marketplace_product_service.dart';

class SellerDashboardData {
  final Map<String, dynamic> profile;
  final String memberRole;
  final Map<String, dynamic>? latestUpgradeRequest;
  final int productCount;

  const SellerDashboardData({
    required this.profile,
    required this.memberRole,
    required this.latestUpgradeRequest,
    required this.productCount,
  });
}

/// Read-only dashboard data. Employee and buyer-identifying data are excluded.
class SellerDashboardService {
  SellerDashboardService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        _products = MarketplaceProductService(client: client);

  final SupabaseClient _client;
  final MarketplaceProductService _products;

  Future<SellerDashboardData?> load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('يجب تسجيل الدخول أولاً');

    final membership = await _client
        .from('seller_profile_members')
        .select('seller_profile_id,member_role,revoked_at')
        .eq('user_id', userId)
        .isFilter('revoked_at', null)
        .maybeSingle();

    if (membership == null) return null;

    final sellerProfileId = membership['seller_profile_id'] as String;
    final profile = await _client
        .from('seller_profiles')
        .select(
          'id,display_name,seller_type,business_name,verification_status,is_active',
        )
        .eq('id', sellerProfileId)
        .single();

    final requests = await _client
        .from('pro_seller_upgrade_requests')
        .select('status,requested_business_type,applicant_note,created_at,review_note')
        .eq('seller_profile_id', sellerProfileId)
        .order('created_at', ascending: false)
        .limit(1);

    final products = await _products.fetchSellerProducts(userId, limit: 1000);
    final requestRows = requests as List;

    return SellerDashboardData(
      profile: Map<String, dynamic>.from(profile),
      memberRole: membership['member_role'] as String? ?? 'member',
      latestUpgradeRequest: requestRows.isEmpty
          ? null
          : Map<String, dynamic>.from(requestRows.first as Map),
      productCount: products.length,
    );
  }
}
