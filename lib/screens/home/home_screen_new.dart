import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenza_hub_flutter/config/app_colors.dart';
import 'package:kenza_hub_flutter/config/app_radius.dart';
import 'package:kenza_hub_flutter/config/app_spacing.dart';
import 'package:kenza_hub_flutter/providers/home_provider.dart';
import 'package:kenza_hub_flutter/models/product.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _openVisualSearchPicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار صورة من المعرض'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final image = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (image == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اختيار الصورة. البحث بالصورة يحتاج ربط خدمة البحث البصري قبل تفعيله.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الصورة. تحقق من صلاحية الكاميرا أو المعرض.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Load products on first build
    Future.microtask(() {
      if (mounted) context.read<HomeProvider>().initialize();
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
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('كنزة هب', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.white,
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
          final strings = AppLocalizations.of(context);
          return Column(
            children: [
              // Search bar with visual-search camera action
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => homeProvider.search(value),
                        decoration: InputDecoration(
                          hintText: strings.searchProduct,
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    homeProvider.search('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: Color(0xFFE8EAF0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      child: IconButton(
                        tooltip: 'البحث بالصورة',
                        onPressed: _openVisualSearchPicker,
                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                        iconSize: 25,
                        constraints: const BoxConstraints.tightFor(width: 54, height: 54),
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontally scrollable main categories
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 10),
                child: Row(
                  children: [
                    Text(
                      strings.categories,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/categories'),
                      child: Text(strings.viewAll),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    _HomeCategoryChip(
                      title: strings.kids,
                      icon: Icons.child_friendly_outlined,
                      selected: homeProvider.selectedCategory == 'kids',
                      onTap: () => homeProvider.filterByCategory('kids'),
                    ),
                    _HomeCategoryChip(
                      title: strings.home,
                      icon: Icons.chair_outlined,
                      selected: homeProvider.selectedCategory == 'home',
                      onTap: () => homeProvider.filterByCategory('home'),
                    ),
                    _HomeCategoryChip(
                      title: strings.clothes,
                      icon: Icons.checkroom_outlined,
                      selected: homeProvider.selectedCategory == 'clothes',
                      onTap: () => homeProvider.filterByCategory('clothes'),
                    ),
                    _HomeCategoryChip(
                      title: strings.shoes,
                      icon: Icons.hiking_outlined,
                      selected: homeProvider.selectedCategory == 'shoes',
                      onTap: () => homeProvider.filterByCategory('shoes'),
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
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFEDF0F4),
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

class _HomeCategoryChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _HomeCategoryChip({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 104,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : const Color(0xFFE8EAF0),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 25, color: selected ? Colors.white : AppColors.primary),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
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
                          product.isAvailable
                              ? AppLocalizations.of(context).available
                              : AppLocalizations.of(context).soldOut,
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
            AppLocalizations.of(context).noProducts,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).tryChangeFilters,
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
            child: Text(
              AppLocalizations.of(context).clearFilters,
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
            child: Text(
              AppLocalizations.of(context).tryAgain,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
