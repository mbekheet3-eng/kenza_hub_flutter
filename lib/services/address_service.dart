import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only address access for the current member.
/// Address writes must use user_addresses.region_id and the approved service area.
class AddressService {
  AddressService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchCurrentUserAddresses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _client
        .from('user_addresses')
        .select(
          'id,user_id,region_id,recipient_name,recipient_phone,address_line_1,address_line_2,landmark,postal_code,is_default,is_deleted,regions(name_ar,city,district)',
        )
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
}
