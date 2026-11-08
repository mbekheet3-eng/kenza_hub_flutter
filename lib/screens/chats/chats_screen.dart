import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

/// Temporary destination for the approved Chats tab.
/// The actual conversation list and messaging workflow are not implemented yet.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).chatsTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 56),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).chatsComingSoon,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).chatsDescription,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
