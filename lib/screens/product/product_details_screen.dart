import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/config/app_colors.dart';
import 'package:kenza_hub_flutter/config/app_radius.dart';
import 'package:kenza_hub_flutter/config/app_spacing.dart';
import 'package:kenza_hub_flutter/models/product_model.dart';
import 'package:kenza_hub_flutter/services/supabase_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  
  late Product _product;
  bool _isLoading = true;
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() => _isLoading = true);
      
      final productData = await _supabaseService.fetchProductById(widget.productId);
      
      setState(() {
        _product = Product.fromJson(productData);
        _isLoading = false;
        
        // Set default selections
        if (_product.sizes != null && _product.sizes!.isNotEmpty) {
          _selectedSize = _product.sizes!.first;
        }
        if (_product.colors != null && _product.colors!.isNotEmpty) {
          _selectedColor = _product.colors!.first;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المنتج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addToCart() {
    // TODO: Implement cart functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إضافة المنتج إلى السلة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _buyNow() {
    // TODO: Implement direct purchase
    Navigator.pushNamed(context, '/checkout');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('تفاصيل المنتج'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: _product.imageUrl != null && _product.imageUrl!.isNotEmpty
                  ? Image.network(
                      _product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 64,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.grey[400],
                        size: 64,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_product.rating != null)
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_product.rating} (${_product.reviewCount ?? 0} تقييم)',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${_product.price.toStringAsFixed(0)} ريال',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Description
                  if (_product.description.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الوصف',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Size Selection
                  if (_product.sizes != null && _product.sizes!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الحجم',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _product.sizes!.map((size) {
                            final isSelected = _selectedSize == size;
                            return ChoiceChip(
                              label: Text(size),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedSize = size);
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Color Selection
                  if (_product.colors != null && _product.colors!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اللون',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _product.colors!.map((color) {
                            final isSelected = _selectedColor == color;
                            return ChoiceChip(
                              label: Text(color),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedColor = color);
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Quantity
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الكمية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _quantity.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _quantity < _product.stock
                                ? () => setState(() => _quantity++)
                                : null,
                            icon: const Icon(Icons.add),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Stock Status
                  if (_product.stock == 0)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Text(
                            'المنتج غير متوفر حالياً',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Action Buttons
                  Row(
                    gap: AppSpacing.md,
                    children: [
                      // Add to Cart
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _product.stock > 0 ? _addToCart : null,
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('أضف للسلة'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                      // Buy Now
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _product.stock > 0 ? _buyNow : null,
                          icon: const Icon(Icons.payment),
                          label: const Text('اشتري الآن'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            backgroundColor: AppColors.primary,
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
}
