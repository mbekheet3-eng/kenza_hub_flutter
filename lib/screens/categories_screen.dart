import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/category.dart';
import '../services/marketplace_service.dart';
import 'search_screen.dart';
import 'store_directory_screen.dart';

Color _categoryBackgroundForSlug(String slug) {
  switch (slug) {
    case 'clothes':
      return const Color(0xFFFCE8E8);
    case 'shoes':
      return const Color(0xFFE7F0FF);
    case 'children-supplies':
      return const Color(0xFFE8F5E9);
    case 'home-supplies':
      return const Color(0xFFFFF1D6);
    default:
      return const Color(0xFFF1EAFE);
  }
}

String _categoryImageForSlug(String slug) {
  switch (slug) {
    case 'clothes':
      return 'assets/icons/clothing.png';
    case 'shoes':
      return 'assets/icons/shoes.png';
    case 'children-supplies':
      return 'assets/icons/children_supplies.png';
    case 'home-supplies':
      return 'assets/icons/home_supplies.png';
    default:
      return 'assets/icons/clothing.png';
  }
}

IconData _categoryIconForSlug(String slug) {
  if (slug.startsWith('clothes')) return Icons.checkroom_outlined;
  if (slug.startsWith('shoes')) return Icons.directions_walk_outlined;
  if (slug.startsWith('children-supplies') || slug.startsWith('kids-')) {
    return Icons.child_friendly;
  }
  if (slug.startsWith('home-supplies') || slug.startsWith('home-')) {
    return Icons.chair_outlined;
  }
  if (slug == 'bags-accessories' || slug.contains('bag')) {
    return Icons.shopping_bag_outlined;
  }
  return Icons.category_outlined;
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const _discoverCategoryOrder = [
    'clothes',
    'shoes',
    'children-supplies',
    'home-supplies',
  ];

  final _service = MarketplaceService();
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await _service.getCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Category> _childrenOf(String? parentId) => _categories
      .where((category) => category.parentId == parentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Future<void> _openCategory(Category category) async {
    final children = _childrenOf(category.id);
    if (children.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _CategoryLevelScreen(
            title: category.nameFor(Localizations.localeOf(context).languageCode),
            categories: _categories,
            parentId: category.id,
          ),
        ),
      );
      return;
    }
    _showProducts(category);
  }

  void _showProducts(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearchScreen(categoryId: category.id)),
    );
  }

  Future<void> _openAllProducts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  Future<void> _openStoreDirectory({
    required String storeType,
    required String title,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoreDirectoryScreen(storeType: storeType, title: title),
      ),
    );
  }

  String _storeName(String key, String languageCode) {
    switch (key) {
      case 'wekala':
        return 'Wekala Markets';
      case 'social':
        return 'Social Stores';
      case 'stock':
        return 'Kenza Stock';
      default:
        return 'Local Brands';
    }
  }

  String _storeSubtitle(String key, String languageCode) {
    if (languageCode == 'ar') {
      switch (key) {
        case 'wekala':
          return 'سوق الوكالة';
        case 'social':
          return 'متاجر وصفحات البيع أونلاين';
        case 'stock':
          return 'كنزا ستوك';
        default:
          return 'العلامات التجارية المحلية';
      }
    }
    if (languageCode == 'fr') {
      switch (key) {
        case 'wekala':
          return 'Marché Wekala';
        case 'social':
          return 'Boutiques et pages en ligne';
        case 'stock':
          return 'Stock Kenza';
        default:
          return 'Marques locales';
      }
    }
    switch (key) {
      case 'wekala':
        return 'Wekala market';
      case 'social':
        return 'Online stores and social pages';
      case 'stock':
        return 'Kenza stock';
      default:
        return 'Local brands';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final rootCategories = _childrenOf(null);
    final categoriesBySlug = {
      for (final category in rootCategories) category.slug: category,
    };
    final discoverCategories = _discoverCategoryOrder
        .map((slug) => categoriesBySlug[slug])
        .whereType<Category>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.discoverTitle),
        actions: [
          IconButton(
            tooltip: strings.searchProductHint,
            onPressed: _openAllProducts,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 40),
                        const SizedBox(height: 12),
                        Text(strings.categoriesLoadScreenError),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadCategories,
                          child: Text(strings.retryAction),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Text(
                            strings.discoverCategoriesTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final category = discoverCategories[index];
                              return _DiscoverCategoryCard(
                                category: category,
                                languageCode: languageCode,
                                imageAsset: _categoryImageForSlug(category.slug),
                                onTap: () => _openCategory(category),
                              );
                            },
                            childCount: discoverCategories.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                          child: Text(
                            strings.discoverStoresTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverGrid(
                          delegate: SliverChildListDelegate([
                            _DiscoverStoreCard(
                              imageAsset: 'assets/icons/wekala_markets.png',
                              title: _storeName('wekala', languageCode),
                              subtitle: _storeSubtitle('wekala', languageCode),
                              onTap: () => _openStoreDirectory(
                                storeType: 'wekala_markets',
                                title: _storeName('wekala', languageCode),
                              ),
                            ),
                            _DiscoverStoreCard(
                              imageAsset: 'assets/icons/social_stores.png',
                              title: _storeName('social', languageCode),
                              subtitle: _storeSubtitle('social', languageCode),
                              onTap: () => _openStoreDirectory(
                                storeType: 'social_stores',
                                title: _storeName('social', languageCode),
                              ),
                            ),
                            _DiscoverStoreCard(
                              imageAsset: 'assets/icons/kenza_stock.png',
                              title: _storeName('stock', languageCode),
                              subtitle: _storeSubtitle('stock', languageCode),
                              onTap: () => _openStoreDirectory(
                                storeType: 'kenza_stock',
                                title: _storeName('stock', languageCode),
                              ),
                            ),
                            _DiscoverStoreCard(
                              imageAsset: 'assets/icons/local_brands.png',
                              title: _storeName('local', languageCode),
                              subtitle: _storeSubtitle('local', languageCode),
                              onTap: () => _openStoreDirectory(
                                storeType: 'local_brands',
                                title: _storeName('local', languageCode),
                              ),
                            ),
                          ]),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _DiscoverCategoryCard extends StatelessWidget {
  const _DiscoverCategoryCard({
    required this.category,
    required this.languageCode,
    required this.imageAsset,
    required this.onTap,
  });

  final Category category;
  final String languageCode;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: _categoryBackgroundForSlug(category.slug),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  imageAsset,
                  width: 82,
                  height: 82,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                category.nameFor(languageCode),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverStoreCard extends StatelessWidget {
  const _DiscoverStoreCard({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.5,
                  child: Image.asset(imageAsset, width: 76, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryLevelScreen extends StatelessWidget {
  const _CategoryLevelScreen({
    required this.title,
    required this.categories,
    required this.parentId,
  });

  final String title;
  final List<Category> categories;
  final String parentId;

  List<Category> _childrenOf(String id) => categories
      .where((category) => category.parentId == id)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final children = _childrenOf(parentId);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.grid_view_rounded)),
            title: Text('$title — ${AppStrings.of(context)!.allProducts}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SearchScreen(categoryId: parentId),
              ),
            ),
          ),
          const Divider(height: 1),
          ...children.map((category) {
            final hasChildren = _childrenOf(category.id).isNotEmpty;
            return _CategoryTile(
              category: category,
              languageCode: languageCode,
              hasChildren: hasChildren,
              onTap: () {
                if (hasChildren) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _CategoryLevelScreen(
                        title: category.nameFor(languageCode),
                        categories: categories,
                        parentId: category.id,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SearchScreen(categoryId: category.id),
                    ),
                  );
                }
              },
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.languageCode,
    required this.hasChildren,
    required this.onTap,
  });

  final Category category;
  final String languageCode;
  final bool hasChildren;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(
          _categoryIconForSlug(category.slug),
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(category.nameFor(languageCode)),
      trailing: Icon(
        hasChildren
            ? Icons.chevron_right_rounded
            : Icons.arrow_forward_ios_rounded,
        size: hasChildren ? 24 : 16,
      ),
      onTap: onTap,
    );
  }
}
