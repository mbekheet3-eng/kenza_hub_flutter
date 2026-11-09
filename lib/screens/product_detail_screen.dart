import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../services/marketplace_service.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _service = MarketplaceService();
  late Future<Product> _product;

  @override
  void initState() {
    super.initState();
    _product = _service.getProduct(widget.productId);
  }

  void _reload() => setState(() => _product = _service.getProduct(widget.productId));

  Future<void> _edit(Product product) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من حذف المنتج وصوره؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteProduct(widget.productId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حذف المنتج: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المنتج')),
      body: FutureBuilder<Product>(
        future: _product,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تعذر تحميل المنتج: ${snapshot.error ?? ''}'),
              ),
            );
          }

          final product = snapshot.data!;
          final isOwner = userId != null && userId == product.ownerId;

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (product.imageUrls.isNotEmpty)
                SizedBox(
                  height: 320,
                  child: PageView(
                    children: product.imageUrls
                        .map(
                          (url) => Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined, size: 48),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
              else
                const SizedBox(
                  height: 220,
                  child: Center(child: Icon(Icons.image_outlined, size: 60)),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Text(
                      '${product.price.toStringAsFixed(2)} ج.م',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF5558C9),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text('الوصف', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(product.description.isEmpty ? 'لا يوجد وصف' : product.description),
                    const SizedBox(height: 18),
                    Text(
                      'تاريخ النشر: ${MaterialLocalizations.of(context).formatMediumDate(product.createdAt.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _edit(product),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('تعديل'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _delete,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('حذف'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
