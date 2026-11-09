import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('يجب تسجيل الدخول أولاً');
    return id;
  }

  Stream<List<Map<String, dynamic>>> watchNotifications() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
  }

  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', _userId)
        .eq('is_read', false);
  }
}
