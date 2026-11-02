import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kenza_hub_flutter/config/app_colors.dart';
import 'package:kenza_hub_flutter/config/app_radius.dart';
import 'package:kenza_hub_flutter/config/app_spacing.dart';
import 'package:kenza_hub_flutter/providers/home_provider.dart';
import 'package:kenza_hub_flutter/models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load products on first build
    Future.microtask(() {
      context.read<HomeProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كنزة هب'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              child: Consumer<HomeProvider>(
                builder: (_, provider, __) {
                  return Text(
                    '${provider.productCount} منتج',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, _) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => homeProvider.search(value),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن المنتجات...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              homeProvider.search('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),

              // Main category cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    const Text(
                      'تسوق حسب القسم',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => homeProvider.filterByCategory('الكل'),
                      child: const Text('كل المنتجات'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 166,
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.7,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MainCategoryTile(
                      title: 'مستلزمات أطفال',
                      subtitle: 'كل احتياجات الطفل ما عدا الملابس',
                      icon: Icons.child_friendly_outlined,
                      selected: homeProvider.selectedCategory == 'مستلزمات أطفال',
                      onTap: () => homeProvider.filterByCategory('مستلزمات أطفال'),
                    ),
                    _MainCategoryTile(
                      title: 'مستلزمات المنزل',
                      subtitle: 'كل ما تحتاجه داخل المنزل',
                      icon: Icons.chair_outlined,
                      selected: homeProvider.selectedCategory == 'مستلزمات المنزل',
                      onTap: () => homeProvider.filterByCategory('مستلزمات المنزل'),
                    ),
                    _MainCategoryTile(
                      title: 'ملابس',
                      subtitle: 'رجالي • حريمي • أطفال',
                      icon: Icons.checkroom_outlined,
                      selected: homeProvider.selectedCategory == 'ملابس',
                      onTap: () => homeProvider.filterByCategory('ملابس'),
                    ),
                    _MainCategoryTile(
                      title: 'أحذية',
                      subtitle: 'رجالي • حريمي • أطفال',
                      icon: Icons.hiking_outlined,
                      selected: homeProvider.selectedCategory == 'أحذية',
                      onTap: () => homeProvider.filterByCategory('أحذية'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Products Grid or Empty/Loading State
              Expanded(
                child: homeProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : homeProvider.error != null
                        ? ErrorState(
                            error: homeProvider.error!,
                            onRetry: () => homeProvider.retry(),
                          )
                        : homeProvider.filteredProducts.isEmpty
                            ? EmptyState(
                                onClearFilters: () => homeProvider.clearFilters(),
                              )
                            : ProductsGrid(
                                products: homeProvider.filteredProducts,
                              ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MainCategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MainCategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withOpacity(0.10) : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 27),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Products Grid Widget
class ProductsGrid extends StatelessWidget {
  final List<Product> products;

  const ProductsGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          onTap: () {
            // Navigate to product details
            context.push('/product/${products[index].id}');
          },
        );
      },
    );
  }
}

// Product Card Widget
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.lg),
                    topRight: Radius.circular(AppSpacing.lg),
                  ),
                  color: Colors.grey[200],
                ),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.priceDisplay,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.isAvailable ? 'متوفر' : 'نفد',
                          style: TextStyle(
                            fontSize: 10,
                            color: product.isAvailable
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.bold,
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

// Empty State Widget
class EmptyState extends StatelessWidget {
  final VoidCallback onClearFilters;

  const EmptyState({super.key, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'لا توجد منتجات',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'حاول تغيير المرشحات أو البحث',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: onClearFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text(
              'إزالة المرشحات',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Error State Widget
class ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'حدث خطأ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text(
              'حاول مجدداً',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
