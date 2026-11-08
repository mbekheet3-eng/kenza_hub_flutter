import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

import '../../../config/theme.dart';
import '../../../models/database_category.dart';
import '../../../services/catalog_service.dart';

class StepCategory extends StatefulWidget {
  final Function(String?) onCategorySelected;
  final String? selectedCategory;

  const StepCategory({
    super.key,
    required this.onCategorySelected,
    required this.selectedCategory,
  });

  @override
  State<StepCategory> createState() => _StepCategoryState();
}

class _StepCategoryState extends State<StepCategory> {
  final CatalogService _catalogService = CatalogService();
  late Future<List<DatabaseCategory>> _categoriesFuture;
  final List<DatabaseCategory> _path = [];
  String? _selectedCategory;
  bool _preservePathOnNextNullUpdate = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _categoriesFuture = _catalogService.fetchCategories();
  }

  @override
  void didUpdateWidget(covariant StepCategory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _selectedCategory = widget.selectedCategory;
      if (_preservePathOnNextNullUpdate && widget.selectedCategory == null) {
        _preservePathOnNextNullUpdate = false;
      } else {
        _path.clear();
      }
    }
  }

  void _openCategory(
    DatabaseCategory category,
    List<DatabaseCategory> allCategories,
  ) {
    final children = allCategories
        .where((item) => item.parentId == category.id)
        .toList();

    if (children.isNotEmpty) {
      setState(() {
        _path.add(category);
        _selectedCategory = null;
      });
      // Clear a previous leaf selection without losing the newly opened path.
      if (widget.selectedCategory != null) {
        _preservePathOnNextNullUpdate = true;
        widget.onCategorySelected(null);
      }
      return;
    }

    setState(() => _selectedCategory = category.slug);
    widget.onCategorySelected(category.slug);
  }

  void _retry() {
    setState(() {
      _path.clear();
      _selectedCategory = null;
      _categoriesFuture = _catalogService.fetchCategories();
    });
    widget.onCategorySelected(null);
  }

  IconData _iconFor(String slug) {
    switch (slug) {
      case 'clothes':
        return Icons.checkroom_outlined;
      case 'shoes':
        return Icons.shopping_bag_outlined;
      case 'kids-supplies':
        return Icons.child_care_outlined;
      case 'home-supplies':
        return Icons.home_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return FutureBuilder<List<DatabaseCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final categories = snapshot.data ?? const <DatabaseCategory>[];
        if (categories.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(AppLocalizations.of(context).noActiveCategories),
            ),
          );
        }

        final currentParent = _path.isEmpty ? null : _path.last;
        final visibleCategories = categories
            .where((category) => category.parentId == currentParent?.id)
            .toList()
          ..sort((a, b) {
            final order = a.displayOrder.compareTo(b.displayOrder);
            return order != 0 ? order : a.nameAr.compareTo(b.nameAr);
          });

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentParent == null
                    ? 'اختر القسم الرئيسي'
                    : 'اختر القسم الفرعي',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (currentParent != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'رجوع',
                      onPressed: () => setState(() => _path.removeLast()),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        currentParent.labelFor(languageCode),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: visibleCategories.length,
                itemBuilder: (context, index) {
                  final category = visibleCategories[index];
                  final hasChildren = categories.any(
                    (item) => item.parentId == category.id,
                  );
                  final isSelected = _selectedCategory == category.slug;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openCategory(category, categories),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : AppTheme.surfaceColor,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.borderLight,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _iconFor(category.slug),
                            size: 36,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              category.labelFor(languageCode),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            hasChildren
                                ? Icons.chevron_right
                                : isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                            size: 18,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_selectedCategory != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: AppTheme.infoColor, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).categorySelected,
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).categoryLoadDatabaseError),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }
}
