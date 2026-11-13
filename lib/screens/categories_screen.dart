import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/category.dart';
import '../services/marketplace_service.dart';
import 'search_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context)!.homeSections)),
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
                        Text(AppStrings.of(context)!.categoriesLoadScreenError),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadCategories,
                          child: Text(AppStrings.of(context)!.retryAction),
                        ),
                      ],
                    ),
                  ),
                )
              : _childrenOf(null).isEmpty
                  ? Center(child: Text(AppStrings.of(context)!.noCategoriesAvailable))
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.grid_view_rounded),
                          ),
                          title: Text(AppStrings.of(context)!.allProducts),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ..._childrenOf(null).map(
                          (category) => _CategoryTile(
                            category: category,
                            languageCode: languageCode,
                            hasChildren: _childrenOf(category.id).isNotEmpty,
                            onTap: () => _openCategory(category),
                          ),
                        ),
                      ],
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
                builder: (_) => SearchScreen(
                  categoryId: parentId,
                ),
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
