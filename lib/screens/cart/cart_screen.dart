import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;
    final totalPrice = cartProvider.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('السلة'),
        elevation: 0,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearCartDialog(context),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                // Cart Items
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(context, item, index);
                    },
                  ),
                ),

                // Summary and Checkout
                _buildCartSummary(context, totalPrice),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'السلة فارغة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('البحث عن منتجات'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, dynamic item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.product?.imageUrls?.isNotEmpty == true
                  ? Image.network(
                      item.product!.imageUrls![0],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.image, color: AppTheme.textTertiary),
                    )
                  : Icon(Icons.image, color: AppTheme.textTertiary),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product?.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.product?.price} ج.م',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: item.quantity > 1
                                  ? () => context
                                      .read<CartProvider>()
                                      .updateQuantity(item.id, item.quantity - 1)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: item.quantity > 1
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            InkWell(
                              onTap: () => context
                                  .read<CartProvider>()
                                  .updateQuantity(item.id, item.quantity + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Remove Button
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            context.read<CartProvider>().removeItem(item.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, double totalPrice) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الفرعي',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '$totalPrice ج.م',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Shipping (placeholder)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الشحن',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'سيتم حسابه',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalPrice ج.م',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/checkout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text(
                'الذهاب إلى الدفع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Continue Shopping
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/search'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.primaryColor),
              ),
              child: const Text(
                'متابعة التسوق',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح السلة'),
        content: const Text('هل أنت متأكد من رغبتك في مسح السلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartProvider>().clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح السلة')),
              );
            },
            child: const Text('مسح', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
