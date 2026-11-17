import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../services/marketplace_transaction_service.dart';
import '../widgets/member_avatar.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _service = MarketplaceTransactionService();
  final _messageController = TextEditingController();
  bool _sending = false;
  late Future<List<Map<String, dynamic>>> _messages;
  late Future<Map<String, dynamic>?> _otherMember;

  @override
  void initState() {
    super.initState();
    _messages = _service.getMessages(widget.conversationId);
    _otherMember = _loadOtherMemberProfile();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadOtherMemberProfile() async {
    final client = Supabase.instance.client;
    final myId = client.auth.currentUser?.id;
    if (myId == null) return null;

    final conversation = await client
        .from('conversations')
        .select('buyer_id,seller_id')
        .eq('id', widget.conversationId)
        .maybeSingle();
    if (conversation == null) return null;

    final otherMemberId = conversation['buyer_id'] == myId
        ? conversation['seller_id'] as String
        : conversation['buyer_id'] as String;
    return client
        .from('member_public_profiles')
        .select('first_name,avatar_url')
        .eq('id', otherMemberId)
        .maybeSingle();
  }

  Future<void> _refresh() async {
    final future = _service.getMessages(widget.conversationId);
    setState(() => _messages = future);
    await future;
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      // Only this operation determines whether the message was sent.
      await _service.sendMessage(widget.conversationId, text);
      _messageController.clear();

      if (!mounted) return;

      // A refresh failure must not be reported as a message-send failure.
      try {
        await _refresh();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppStrings.of(context)!.messageSentConversationRefreshFailed}: $error',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.of(context)!.sendMessageFailed}: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _otherMember,
          builder: (context, snapshot) {
            final member = snapshot.data;
            final firstName = member?['first_name'] as String?;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MemberAvatar(
                  avatarUrl: member?['avatar_url'] as String?,
                  radius: 17,
                ),
                const SizedBox(width: 10),
                Text(
                  firstName?.isNotEmpty == true ? firstName! : AppStrings.of(context)!.conversationFallback,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('${AppStrings.of(context)!.conversationLoadFailed}: ${snapshot.error}'),
                  );
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return Center(
                    child: Text(AppStrings.of(context)!.startConversationHint),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final mine = row['sender_id'] == myId;
                    return Align(
                      alignment: mine
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          // Sent messages are white; received messages are light grey.
                          color: mine ? Colors.white : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          row['body'] as String,
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: AppStrings.of(context)!.messageInputHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
