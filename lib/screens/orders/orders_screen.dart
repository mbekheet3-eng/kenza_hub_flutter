import 'package:flutter/material.dart';

import 'order_history_screen.dart';

/// Backward-compatible screen name used by the legacy route configuration.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => const OrderHistoryScreen();
}
