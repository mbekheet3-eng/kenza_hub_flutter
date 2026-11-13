import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_locale.dart';
import '../l10n/app_strings.dart';

class NotificationService {
  NotificationService({SupabaseClient? client})
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

  Stream<List<Map<String, dynamic>>> watchNotifications() {
    return Stream<String>.fromFuture(_requireUserId()).asyncExpand(
      (userId) => _client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false),
    );
  }

  Future<void> markAsRead(String id) async {
    final userId = await _requireUserId();
    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<void> markAllAsRead() async {
    final userId = await _requireUserId();
    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}
