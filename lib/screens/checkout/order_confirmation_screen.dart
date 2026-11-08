import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).confirmOrder)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_clock_outlined,
                size: 76,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).orderConfirmUnavailable,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).noOrderCreatedNotice,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: Text(AppLocalizations.of(context).backToHome),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
