import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({Key? key}) : super(key: key);

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  late String _filterStatus; // all, active, sold, inactive

  @override
  void initState() {
    super.initState();
    _filterStatus = 'all';
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      await context.read<ProductProvider>().loadUserProducts(
        context.read<AuthProvider>().currentUser?.id ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';

    var products = productProvider.products
        .where((p) => p.userId == userId)
        .toList();

    // Apply filter
    if (_filterStatus != 'all') {
      products = products
          .where((p) {
            if (_filterStatus == 'active') return p.isActive == true && p.isSold != true;
            if (_filterStatus == 'sold') return p.isSold == true;
            if (_filterStatus == 'inactive') return p.isActive != true;
            return true;
          })
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('منتجاتي'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/sell-wizard'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),

          // Products Grid or Empty State
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildProductCard(context, product);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('الكل', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('نشط', 'active'),
          const SizedBox(width: 8),
          _buildFilterChip('مباع', 'sold'),
          const SizedBox(width: 8),
          _buildFilterChip('غير نشط', 'inactive'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
      backgroundColor: Colors.transparent,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outline,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/sell-wizard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('إضافة منتج أول'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      onLongPress: () => _showProductOptions(context, product),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: product.imageUrls?.isNotEmpty == true
                      ? Image.network(
                          product.imageUrls![0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.image, color: AppTheme.textTertiary),
                        )
                      : Icon(Icons.image, color: AppTheme.textTertiary),
                ),
                // Status Badge
                if (product.isSold == true)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'مباع',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (product.isActive != true)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'غير نشط',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // View Count
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.views ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price} ج.م',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              context.push('/edit-product/${product.id}'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          child: const Text('تعديل', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _deleteProduct(product.id),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text(
                            'حذف',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
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

  void _showProductOptions(BuildContext context, dynamic product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(context);
                context.push('/edit-product/${product.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('إيقاف العرض'),
              onTap: () {
                Navigator.pop(context);
                _toggleProductVisibility(product.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteProduct(product.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleProductVisibility(String productId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إيقاف العرض')),
    );
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProductProvider>().deleteProduct(productId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف المنتج')),
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
