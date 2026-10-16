import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kenza_hub_flutter/config/app_colors.dart';
import 'package:kenza_hub_flutter/config/app_radius.dart';
import 'package:kenza_hub_flutter/config/app_spacing.dart';
import 'package:kenza_hub_flutter/providers/checkout_provider.dart';
import 'package:kenza_hub_flutter/providers/cart_provider.dart';
import 'package:kenza_hub_flutter/providers/auth_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CheckoutProvider>().loadAddresses();
    });
  }

  void _handleCheckout(BuildContext context) async {
    final checkoutProvider = context.read<CheckoutProvider>();
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    if (!checkoutProvider.canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع البيانات المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await checkoutProvider.processPayment(
      buyerId: authProvider.userId!,
      cartItems: cartProvider.getCartJson(),
      totalAmount: cartProvider.total,
    );

    if (success && mounted) {
      // Clear cart
      cartProvider.clear();

      // Navigate to order confirmation
      Navigator.pushReplacementNamed(
        context,
        '/order-confirmation',
        arguments: checkoutProvider.orderId,
      );
    } else if (checkoutProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkoutProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الطلب'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer2<CheckoutProvider, CartProvider>(
        builder: (context, checkoutProvider, cartProvider, _) {
          if (checkoutProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary
                _buildOrderSummary(cartProvider),

                const Divider(height: 1),

                // Shipping Address
                _buildShippingAddress(checkoutProvider),

                const Divider(height: 1),

                // Payment Method
                _buildPaymentMethod(checkoutProvider),

                const Divider(height: 1),

                // Terms and Conditions
                _buildTermsSection(checkoutProvider),

                // Checkout Button
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: checkoutProvider.isProcessing
                            ? null
                            : () => _handleCheckout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                        ),
                        child: checkoutProvider.isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'تأكيد الطلب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: checkoutProvider.isProcessing
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: const Text(
                          'العودة للسلة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الطلب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('السعر الفرعي'),
              Text('${cartProvider.subtotal.toStringAsFixed(2)} ريال'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الشحن'),
              Text(
                cartProvider.shippingCost == 0
                    ? 'مجاني'
                    : '${cartProvider.shippingCost.toStringAsFixed(2)} ريال',
                style: TextStyle(
                  color: cartProvider.shippingCost == 0 ? Colors.green : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الضريبة (14%)'),
              Text('${cartProvider.tax.toStringAsFixed(2)} ريال'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المجموع',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${cartProvider.total.toStringAsFixed(2)} ريال',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress(CheckoutProvider checkoutProvider) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'عنوان التوصيل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (checkoutProvider.addresses.isEmpty)
            Center(
              child: Text(
                'لا توجد عناوين مسجلة',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            Column(
              children: checkoutProvider.addresses.map((address) {
                final isSelected =
                    checkoutProvider.selectedAddress?.id == address.id;
                return GestureDetector(
                  onTap: () => checkoutProvider.selectAddress(address),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.05)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              address.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (address.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'افتراضي',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${address.street}, ${address.city}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.phone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(CheckoutProvider checkoutProvider) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'طريقة الدفع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RadioListTile<String>(
            title: const Text('بطاقة ائتمان/خصم'),
            subtitle: const Text('Visa, Mastercard'),
            value: 'card',
            groupValue: checkoutProvider.paymentMethod,
            onChanged: (value) {
              if (value != null) {
                checkoutProvider.setPaymentMethod(value);
              }
            },
            dense: true,
          ),
          RadioListTile<String>(
            title: const Text('الدفع عند الاستلام'),
            value: 'cash',
            groupValue: checkoutProvider.paymentMethod,
            onChanged: (value) {
              if (value != null) {
                checkoutProvider.setPaymentMethod(value);
              }
            },
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(CheckoutProvider checkoutProvider) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: checkoutProvider.agreedToTerms,
                onChanged: (_) {
                  checkoutProvider.toggleTermsAgreement();
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    checkoutProvider.toggleTermsAgreement();
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'أوافق على ',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'الشروط والأحكام',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' و ',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        TextSpan(
                          text: 'سياسة الخصوصية',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
