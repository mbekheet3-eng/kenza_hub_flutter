import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../config/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  String _selectedCategory = 'all';
  String _selectedCondition = 'all';
  double _minPrice = 0;
  double _maxPrice = 10000;
  String _sortBy = 'newest'; // newest, price_low, price_high, most_viewed

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadAllProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProducts() async {
    if (mounted) {
      await context.read<ProductProvider>().loadAllProducts();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'all';
      _selectedCondition = 'all';
      _minPrice = 0;
      _maxPrice = 10000;
      _sortBy = 'newest';
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    var products = productProvider.products;

    // Apply filters
    products = products.where((p) {
      // Search filter
      if (_searchController.text.isNotEmpty) {
        if (!(p.title?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) &&
            !(p.description?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'all' && p.category != _selectedCategory) {
        return false;
      }

      // Condition filter
      if (_selectedCondition != 'all' && p.condition != _selectedCondition) {
        return false;
      }

      // Price filter
      if (p.price != null && (p.price! < _minPrice || p.price! > _maxPrice)) {
        return false;
      }

      // Only show active products
      if (p.isActive != true || p.isSold == true) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'price_low':
        products.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'price_high':
        products.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'most_viewed':
        products.sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));
        break;
      case 'newest':
      default:
        products.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('اكتشف'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            // Category Filter
            _buildCategoryFilter(),

            // Filter Chips
            _buildFilterChips(),

            // More Filters Button
            _buildMoreFiltersButton(context),

            // Sort Options
            _buildSortOptions(),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${products.length} منتج',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty ||
                      _selectedCategory != 'all' ||
                      _selectedCondition != 'all')
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Text(
                        'مسح الفلاتر',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Products Grid
            products.isEmpty
                ? _buildEmptyState()
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['all', 'clothes', 'shoes', 'kids', 'home'];
    final categoryLabels = {
      'all': 'الكل',
      'clothes': 'ملابس',
      'shoes': 'أحذية',
      'kids': 'أطفال',
      'home': 'منزل',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: categories
            .map((category) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(categoryLabels[category] ?? category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() =>
                          _selectedCategory = selected ? category : 'all');
                    },
                    backgroundColor: Colors.transparent,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    side: BorderSide(
                      color: _selectedCategory == category
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFilterChips() {
    final conditions = ['all', 'جديد', 'ممتاز', 'جيد', 'يحتاج إصلاح'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: conditions
            .map((condition) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(condition == 'all' ? 'جميع الحالات' : condition),
                    selected: _selectedCondition == condition,
                    onSelected: (selected) {
                      setState(() =>
                          _selectedCondition = selected ? condition : 'all');
                    },
                    backgroundColor: Colors.transparent,
                    selectedColor:
                        AppTheme.primaryColor.withOpacity(0.2),
                    side: BorderSide(
                      color: _selectedCondition == condition
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMoreFiltersButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.tune),
          label: const Text('فلاتر متقدمة'),
          onPressed: () => _showAdvancedFilters(context),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButton<String>(
        value: _sortBy,
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: 'newest',
            child: const Text('الأحدث'),
          ),
          DropdownMenuItem(
            value: 'price_low',
            child: const Text('السعر: من الأقل للأعلى'),
          ),
          DropdownMenuItem(
            value: 'price_high',
            child: const Text('السعر: من الأعلى للأقل'),
          ),
          DropdownMenuItem(
            value: 'most_viewed',
            child: const Text('الأكثر مشاهدة'),
          ),
        ],
        onChanged: (value) {
          setState(() => _sortBy = value ?? 'newest');
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'لم نعثر على نتائج',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تغيير الفلاتر أو البحث',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.condition ?? 'جديد',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: AppTheme.textTertiary,
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

  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'فلاتر متقدمة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'نطاق السعر: ${_minPrice.toStringAsFixed(0)} - ${_maxPrice.toStringAsFixed(0)} ج.م',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0,
              max: 10000,
              onChanged: (values) {
                setState(() {
                  _minPrice = values.start;
                  _maxPrice = values.end;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('تطبيق الفلاتر'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
