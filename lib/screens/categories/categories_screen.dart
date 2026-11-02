import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/database_category.dart';
import '../../services/catalog_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CatalogService _catalogService = CatalogService();
  late Future<List<DatabaseCategory>> _categoriesFuture;
  final List<DatabaseCategory> _path = [];

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _catalogService.fetchCategories();
  }

  void _retry() {
    setState(() {
      _path.clear();
      _categoriesFuture = _catalogService.fetchCategories();
    });
  }

  void _openCategory(
    DatabaseCategory category,
    List<DatabaseCategory> categories,
  ) {
    final hasChildren = categories.any((item) => item.parentId == category.id);
    if (hasChildren) {
      setState(() => _path.add(category));
      return;
    }

    context.push('/search?categoryId=${Uri.encodeComponent(category.id)}');
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقسام'),
      ),
      body: FutureBuilder<List<DatabaseCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 42),
                    const SizedBox(height: 12),
                    const Text('تعذر تحميل الأقسام'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final categories = snapshot.data ?? const <DatabaseCategory>[];
          final currentParent = _path.isEmpty ? null : _path.last;
          final visibleCategories = categories
              .where((item) => item.parentId == currentParent?.id)
              .toList()
            ..sort((a, b) {
              final order = a.displayOrder.compareTo(b.displayOrder);
              return order != 0 ? order : a.nameAr.compareTo(b.nameAr);
            });

          if (categories.isEmpty) {
            return const Center(child: Text('لا توجد أقسام متاحة حاليًا'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_path.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'رجوع للقسم السابق',
                        onPressed: () => setState(() => _path.removeLast()),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          _path.map((item) => item.labelFor(languageCode)).join(' / '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  currentParent == null
                      ? 'اختر القسم الرئيسي'
                      : 'اختر القسم الفرعي',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: visibleCategories.length,
                  itemBuilder: (context, index) {
                    final category = visibleCategories[index];
                    final hasChildren =
                        categories.any((item) => item.parentId == category.id);
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openCategory(category, categories),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasChildren
                                    ? Icons.folder_outlined
                                    : Icons.category_outlined,
                                size: 34,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                category.labelFor(languageCode),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                hasChildren
                                    ? Icons.chevron_right
                                    : Icons.arrow_forward,
                                size: 18,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
