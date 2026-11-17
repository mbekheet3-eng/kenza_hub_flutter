import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/category.dart';
import '../services/marketplace_service.dart';
import 'search_screen.dart';
import 'store_directory_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
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

  IconData _iconForCategory(Category category) {
    switch (category.slug) {
      case 'clothes':
        return Icons.checkroom_outlined;
      case 'shoes':
        return Icons.hiking_outlined;
      case 'children-supplies':
        return Icons.child_care_outlined;
      case 'home-supplies':
        return Icons.chair_alt_outlined;
      case 'bags-accessories':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.category_outlined;
    }
  }

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
      MaterialPageRoute(
        builder: (_) => SearchScreen(categoryId: category.id),
      ),
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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final rootCategories = _childrenOf(null);

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
              : rootCategories.isEmpty
                  ? Center(child: Text(strings.noCategoriesAvailable))
                  : RefreshIndicator(
                      onRefresh: _loadCategories,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    child: Icon(
                                      Icons.grid_view_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                                  ),
                                  title: Text(
                                    strings.allProducts,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: _openAllProducts,
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
                                  final category = rootCategories[index];
                                  return _DiscoverCategoryCard(
                                    category: category,
                                    languageCode: languageCode,
                                    icon: _iconForCategory(category),
                                    hasChildren:
                                        _childrenOf(category.id).isNotEmpty,
                                    onTap: () => _openCategory(category),
                                  );
                                },
                                childCount: rootCategories.length,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.85,
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
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _DiscoverStoreTile(
                                  icon: Icons.storefront_outlined,
                                  title: strings.agencyCornerTitle,
                                  onTap: () => _openStoreDirectory(
                                    storeType: 'wekala_corner',
                                    title: strings.agencyCornerTitle,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _DiscoverStoreTile(
                                  icon: Icons.language_rounded,
                                  title: strings.onlineStoresTitle,
                                  onTap: () => _openStoreDirectory(
                                    storeType: 'online_store',
                                    title: strings.onlineStoresTitle,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _DiscoverStoreTile(
                                  icon: Icons.store_mall_directory_outlined,
                                  title: strings.localShopsTitle,
                                  onTap: () => _openStoreDirectory(
                                    storeType: 'physical_shop',
                                    title: strings.localShopsTitle,
                                  ),
                                ),
                              ]),
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
    required this.icon,
    required this.hasChildren,
    required this.onTap,
  });

  final Category category;
  final String languageCode;
  final IconData icon;
  final bool hasChildren;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: colors.onSecondaryContainer,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.nameFor(languageCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                hasChildren
                    ? Icons.chevron_right_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: hasChildren ? 20 : 14,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverStoreTile extends StatelessWidget {
  const _DiscoverStoreTile({
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
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.secondaryContainer,
          child: Icon(icon, color: colors.onSecondaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
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
          hasChildren ? Icons.folder_outlined : Icons.category_outlined,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(category.nameFor(languageCode)),
      trailing: Icon(
        hasChildren ? Icons.chevron_right_rounded : Icons.arrow_forward_ios_rounded,
        size: hasChildren ? 24 : 16,
      ),
      onTap: onTap,
    );
  }
}
