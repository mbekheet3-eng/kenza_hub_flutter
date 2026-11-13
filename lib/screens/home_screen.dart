import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';
import '../services/favorites_service.dart';
import '../widgets/product_card.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'special_markets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _SpecialMarketEntry extends StatelessWidget {
  const _SpecialMarketEntry({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colors.primary, size: 21),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = MarketplaceService();
  final _search = TextEditingController();
  List<Category> _categories = [];
  List<Product> _products = [];
  Set<String> _favoriteIds = {};
  String? _categoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await _service.getCategories();
      final products = await _service.getPublishedProducts(
        categoryId: _categoryId,
        query: _search.text,
      );
      var favoriteIds = <String>{};
      if (Supabase.instance.client.auth.currentUser != null) {
        try {
          favoriteIds = await FavoritesService().getFavoriteProductIds();
        } catch (_) {
          // Product discovery should remain available if favorites cannot load.
        }
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _products = products;
        _favoriteIds = favoriteIds;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    var user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted) return;
      user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
    }

    final wasFavorite = _favoriteIds.contains(product.id);
    try {
      final favorites = FavoritesService();
      if (wasFavorite) {
        await favorites.removeFavorite(product.id);
      } else {
        await favorites.addFavorite(product.id);
      }
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoriteIds.remove(product.id);
        } else {
          _favoriteIds.add(product.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasFavorite
              ? 'تمت إزالة المنتج من المفضلة'
              : 'تمت إضافة المنتج للمفضلة'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث المفضلة: $error')),
      );
    }
  }


  List<Category> get _rootCategories =>
      _categories.where((category) => category.parentId == null).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Future<void> _openSpecialMarkets() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SpecialMarketsScreen()),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context)!.featureComingSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(
                          query: _search.text.trim(),
                          categoryId: _categoryId,
                        ),
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.of(context)!.searchProductHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: AppStrings.of(context)!.imageSearch,
                        onPressed: () => _showComingSoon('البحث بالصور'),
                        icon: const Icon(Icons.camera_alt_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(AppStrings.of(context)!.allLabel),
                          selected: _categoryId == null,
                          onSelected: (_) {
                            setState(() => _categoryId = null);
                            _load();
                          },
                        ),
                      ),
                      ..._rootCategories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(category.nameFor(languageCode)),
                            selected: _categoryId == category.id,
                            onSelected: (_) {
                              setState(() => _categoryId = category.id);
                              _load();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SpecialMarketEntry(
                          icon: Icons.storefront_outlined,
                          title: AppStrings.of(context)!.agencyCornerTitle,
                          onTap: _openSpecialMarkets,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SpecialMarketEntry(
                          icon: Icons.shopping_bag_outlined,
                          title: AppStrings.of(context)!.onlineStoresTitle,
                          onTap: _openSpecialMarkets,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 42),
                          const SizedBox(height: 12),
                          const Text('تعذر تحميل المنتجات'),
                          const SizedBox(height: 8),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('لا توجد منتجات منشورة حتى الآن')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _products[index];
                        return ProductCard(
                          product: product,
                          isFavorite: _favoriteIds.contains(product.id),
                          onFavoriteTap: () => _toggleFavorite(product),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(productId: product.id),
                              ),
                            );
                            if (mounted) _load();
                          },
                        );
                      },
                      childCount: _products.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }
}
