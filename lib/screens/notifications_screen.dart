import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'conversation_screen.dart';
import 'messages_inbox_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  late Stream<List<Map<String, dynamic>>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _service.watchNotifications();
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllAsRead();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث الإشعارات: $error')),
      );
    }
  }

  Future<void> _openNotification(Map<String, dynamic> row) async {
    try {
      if (row['is_read'] != true) {
        await _service.markAsRead(row['id'] as String);
      }
      if (!mounted) return;
      final rawData = row['data'];
      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};
      final conversationId = data['conversation_id']?.toString();
      if (conversationId != null && conversationId.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationScreen(conversationId: conversationId),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MessagesInboxScreen()),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الإشعار: $error')),
      );
    }
  }

  IconData _icon(String? type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_outline_rounded;
      case 'new_offer':
      case 'offer_accepted':
      case 'offer_rejected':
        return Icons.local_offer_outlined;
      case 'new_order':
      case 'order_accepted':
      case 'order_rejected':
      case 'order_updated':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _date(dynamic value) {
    final date = value is String ? DateTime.tryParse(value)?.toLocal() : null;
    if (date == null) return '';
    return '\${date.day}/\${date.month}/\${date.year} - '
        '\${date.hour.toString().padLeft(2, '0')}:\${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('قراءة الكل'),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notifications,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تعذر تحميل الإشعارات: \${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 56),
                    SizedBox(height: 12),
                    Text('لا توجد إشعارات حتى الآن'),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              final unread = row['is_read'] != true;
              return ListTile(
                onTap: () => _openNotification(row),
                leading: CircleAvatar(
                  backgroundColor: unread
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(_icon(row['type']?.toString())),
                ),
                title: Text(
                  row['title']?.toString() ?? 'إشعار جديد',
                  style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w500),
                ),
                subtitle: Text(
                  '\${row['body'] ?? ''}\\n\${_date(row['created_at'])}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: unread
                    ? Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
