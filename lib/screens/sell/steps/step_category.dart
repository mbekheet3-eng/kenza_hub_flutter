import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class StepCategory extends StatefulWidget {
  final Function(String?) onCategorySelected;
  final String? selectedCategory;

  const StepCategory({
    required this.onCategorySelected,
    required this.selectedCategory,
  });

  @override
  State<StepCategory> createState() => _StepCategoryState();
}

class _StepCategoryState extends State<StepCategory> {
  late String? _selectedCategory;

  final categories = [
    ('clothes', 'ملابس', Icons.checkroom),
    ('shoes', 'أحذية', Icons.shopping_bag_outlined),
    ('kids', 'ملابس أطفال', Icons.child_care),
    ('home', 'منزل وأثاث', Icons.home),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر فئة المنتج',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
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
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final (key, label, icon) = categories[index];
              final isSelected = _selectedCategory == key;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = key);
                  widget.onCategorySelected(key);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.surfaceColor,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 40,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (_selectedCategory != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: AppTheme.infoColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getCategoryInfo(_selectedCategory!),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getCategoryInfo(String category) {
    switch (category) {
      case 'clothes':
        return 'ملابس مستعملة بجميع الأنواع والمقاسات';
      case 'shoes':
        return 'أحذية مستعملة بحالات جيدة';
      case 'kids':
        return 'ملابس أطفال مستعملة بأحجام مختلفة';
      case 'home':
        return 'أثاث ومستلزمات منزلية';
      default:
        return '';
    }
  }
}
