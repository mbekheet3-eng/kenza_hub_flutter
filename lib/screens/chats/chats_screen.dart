import 'package:flutter/material.dart';

/// Temporary destination for the approved Chats tab.
/// The actual conversation list and messaging workflow are not implemented yet.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرسائل')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.chat_bubble_outline_rounded, size: 56),
              SizedBox(height: 16),
              Text(
                'المحادثات قيد التجهيز',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'قريبًا ستتمكن من التواصل مع البائعين والمشترين من هنا.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
