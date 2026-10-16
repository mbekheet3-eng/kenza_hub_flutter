import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/config/app_colors.dart';
import 'package:kenza_hub_flutter/config/app_radius.dart';
import 'package:kenza_hub_flutter/config/app_spacing.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green[700],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Success Message
                  const Text(
                    'تم استقبال طلبك بنجاح',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'شكراً لاختيارك كنزة هب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Order ID Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رقم الطلب',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          orderId,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Order Details
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('الحالة', 'قيد المعالجة'),
                        const SizedBox(height: AppSpacing.md),
                        _buildDetailRow('الشحن', 'سيتم التوصيل قريباً'),
                        const SizedBox(height: AppSpacing.md),
                        _buildDetailRow('التتبع', 'متاح من لوحة التحكم'),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'تحقق من بريدك الإلكتروني للحصول على تفاصيل الطلب وتتبع الشحن',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text(
                        'العودة للمتجر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/order-tracking',
                          arguments: orderId,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      child: const Text(
                        'تتبع الطلب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
