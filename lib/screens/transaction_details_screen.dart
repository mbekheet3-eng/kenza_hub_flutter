import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
    required this.isOffer,
    required this.currentUserId,
  });

  final Map<String, dynamic> transaction;
  final bool isOffer;
  final String currentUserId;

  String _status(BuildContext context, String value) {
    final strings = AppStrings.of(context)!;
    switch (value) {
      case 'pending':
        return strings.statusPending;
      case 'accepted':
        return strings.statusAccepted;
      case 'rejected':
        return strings.statusRejected;
      case 'cancelled':
        return strings.statusCancelled;
      case 'delivered':
        return strings.statusDelivered;
      case 'completed':
        return strings.statusCompleted;
      case 'expired':
        return strings.statusExpired;
      default:
        return value;
    }
  }

  String _date(dynamic value) {
    if (value is! String) return '—';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isBuyer = transaction['buyer_id'] == currentUserId;
    final product = transaction['products'];
    final productTitle = product is Map && product['title'] is String
        ? product['title'] as String
        : (isArabic ? 'منتج' : 'Product');
    final price = transaction[isOffer ? 'offered_price' : 'agreed_price'];
    final currency = transaction['currency'] ?? 'EGP';
    final status = transaction['status']?.toString() ?? '';
    final title = isOffer
        ? (isArabic ? 'تفاصيل العرض' : 'Offer details')
        : (isArabic ? 'تفاصيل الطلب' : 'Order details');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 30,
              child: Icon(isOffer ? Icons.local_offer_outlined : Icons.shopping_bag_outlined, size: 30),
            ),
          ),
          const SizedBox(height: 18),
          Text(productTitle, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _detailRow(context, isArabic ? 'السعر' : 'Price', '$price $currency'),
          _detailRow(context, isArabic ? 'الحالة' : 'Status', _status(context, status)),
          _detailRow(context, isArabic ? 'دورك' : 'Your role', isBuyer
              ? (isArabic ? 'المشتري' : 'Buyer')
              : (isArabic ? 'البائع' : 'Seller')),
          _detailRow(context, isArabic ? 'تاريخ الإنشاء' : 'Created', _date(transaction['created_at'])),
          if (transaction['updated_at'] != null)
            _detailRow(context, isArabic ? 'آخر تحديث' : 'Last updated', _date(transaction['updated_at'])),
          if (isOffer && (transaction['message']?.toString().trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 18),
            Text(isArabic ? 'رسالة العرض' : 'Offer message',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(transaction['message'].toString()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
