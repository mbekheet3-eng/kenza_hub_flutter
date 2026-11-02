import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;
  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _isFavorite = false;
      _isFavoriteLoading = false;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    if (!mounted) return;
    final requestId = ++_loadRequestId;
    final productProvider = context.read<ProductProvider>();
    await productProvider.getProduct(widget.productId);

    if (!mounted || requestId != _loadRequestId) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final isFavorite =
        await productProvider.isFavorite(widget.productId, userId);
    if (mounted && requestId == _loadRequestId) {
      setState(() => _isFavorite = isFavorite);
    }
  }

  Future<void> _toggleFavorite() async {
    final productId = widget.productId;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول لإضافة المنتجات إلى المفضلة')),
      );
      context.push('/login');
      return;
    }
    if (_isFavoriteLoading) return;

    setState(() => _isFavoriteLoading = true);
    final succeeded = await context
        .read<ProductProvider>()
        .toggleFavorite(productId, userId);
    if (!mounted || productId != widget.productId) return;

    setState(() {
      if (succeeded) _isFavorite = !_isFavorite;
      _isFavoriteLoading = false;
    });

    if (!succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث المفضلة. حاول مرة أخرى.')),
      );
    }
  }

  bool _canPurchase(Product product) {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجّل الدخول أولاً للشراء وإضافة المنتجات إلى السلة'),
        ),
      );
      context.push('/login');
      return false;
    }

    if (!product.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا المنتج غير متاح حالياً')),
      );
      return false;
    }

    if (product.userId == authProvider.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكنك شراء منتج قمت بعرضه بنفسك')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final product = productProvider.currentProduct;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المنتج')),
        body: Center(
          child: productProvider.isLoading
              ? CircularProgressIndicator(color: AppTheme.primaryColor)
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        productProvider.error ?? 'تعذر تحميل بيانات المنتج',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadProduct,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_outline,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _isFavoriteLoading ? null : _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            _buildImageGallery(product),
            const SizedBox(height: 16),

            // Product Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price
                  _buildTitleAndPrice(context, product),
                  const SizedBox(height: 12),

                  // Condition & Category
                  _buildConditionAndCategory(context, product),
                  const SizedBox(height: 16),

                  // Description
                  if (product.description?.isNotEmpty == true)
                    _buildDescriptionSection(context, product),

                  const SizedBox(height: 16),

                  // Product Details
                  _buildProductDetailsSection(context, product),
                  const SizedBox(height: 16),

                  // Seller Info
                  _buildSellerSection(context, product),
                  const SizedBox(height: 24),

                  // Quantity Selector
                  const SizedBox(height: 16),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: product.isAvailable
                          ? () => _addToCart(context, product)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text(
                        'إضافة إلى السلة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Buy Now Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: product.isAvailable
                          ? () => _buyNow(context, product)
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                      child: const Text(
                        'اشتري الآن',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(Product product) {
    final images = product.imageUrls ?? [];
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          color: AppTheme.surfaceColor,
          child: images.isEmpty
              ? Center(
                  child: Icon(Icons.image, size: 64, color: AppTheme.textTertiary),
                )
              : PageView.builder(
                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.image, size: 64, color: AppTheme.textTertiary),
                    );
                  },
                ),
        ),
        // Image Indicators
        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? AppTheme.primaryColor
                        : AppTheme.textTertiary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleAndPrice(BuildContext context, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title ?? '',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${product.price} ج.م',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (product.rating != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(product.rating!.toStringAsFixed(1)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildConditionAndCategory(BuildContext context, Product product) {
    return Row(
      children: [
        Chip(
          label: Text(product.condition ?? 'جديد'),
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        ),
        const SizedBox(width: 8),
        Chip(
          label: Text(categoryTranslations[product.category] ?? product.category),
          backgroundColor: Colors.grey.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الوصف',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildProductDetailsSection(BuildContext context, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التفاصيل',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('العلامة التجارية', product.brand ?? 'غير محدد'),
        if (product.color?.isNotEmpty == true)
          _buildDetailRow('اللون', product.color!),
        if (product.size?.isNotEmpty == true)
          _buildDetailRow('المقاس', product.size!),
        _buildDetailRow('الحالة', product.condition ?? 'جديد'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSellerSection(BuildContext context, Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'البائع',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                backgroundImage: product.sellerAvatar != null &&
                        product.sellerAvatar!.isNotEmpty
                    ? NetworkImage(product.sellerAvatar!)
                    : null,
                child: product.sellerAvatar == null ||
                        product.sellerAvatar!.isEmpty
                    ? Icon(Icons.person, color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.sellerName?.trim().isNotEmpty == true
                          ? product.sellerName!
                          : 'بائع على كنزة هب',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(product.rating!.toStringAsFixed(1)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, Product product) {
    if (!_canPurchase(product)) return;

    final added = context.read<CartProvider>().addItem(
      productId: product.id,
      title: product.title,
      price: product.price,
      imageUrl: product.imageUrl,
      quantity: 1,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'تمت إضافة المنتج إلى السلة' : 'هذا المنتج موجود بالفعل في السلة',
        ),
        backgroundColor: added ? Colors.green : Colors.blueGrey,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _buyNow(BuildContext context, Product product) {
    if (!_canPurchase(product)) return;

    context.read<CartProvider>().addItem(
      productId: product.id,
      title: product.title,
      price: product.price,
      imageUrl: product.imageUrl,
      quantity: 1,
    );
    context.push('/cart');
  }

}
