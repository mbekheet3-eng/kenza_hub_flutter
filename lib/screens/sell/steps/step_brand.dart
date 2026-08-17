import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../config/theme.dart';

class StepBrand extends StatefulWidget {
  final Function(String?) onBrandSelected;
  final String? selectedBrand;
  final String? category;

  const StepBrand({
    required this.onBrandSelected,
    required this.selectedBrand,
    required this.category,
  });

  @override
  State<StepBrand> createState() => _StepBrandState();
}

class _StepBrandState extends State<StepBrand> {
  late String? _selectedBrand;
  late TextEditingController _searchController;
  late List<String> _filteredBrands;

  final Map<String, List<String>> brandsByCategory = {
    'clothes': [
      'Zara', 'H&M', 'Forever 21', 'Shein', 'Gap', 'Calvin Klein',
      'Lacoste', 'Ralph Lauren', 'Tommy Hilfiger', 'Versace',
      'Gucci', 'Prada', 'Louis Vuitton', 'Christian Dior',
    ],
    'shoes': [
      'Nike', 'Adidas', 'Puma', 'Reebok', 'Skechers', 'Converse',
      'Vans', 'New Balance', 'Clarks', 'Crocs',
      'Jordan', 'Asics', 'Salomon', 'Timberland',
    ],
    'kids': [
      'H&M Kids', 'Zara Kids', 'Gap Kids', 'Next', 'Mothercare',
      'Disney', 'Marvel', 'Carter\'s', 'Old Navy',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.selectedBrand;
    _searchController = TextEditingController();
    _filteredBrands = _getBrandsForCategory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getBrandsForCategory() {
    if (widget.category == null || categorySkipFields[widget.category] == true) {
      return [];
    }
    return brandsByCategory[widget.category!] ?? [];
  }

  void _filterBrands(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBrands = _getBrandsForCategory();
      } else {
        _filteredBrands = _getBrandsForCategory()
            .where((brand) => brand.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category == null || categorySkipFields[widget.category] == true) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'هذه الفئة لا تتطلب تحديد علامة تجارية',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر العلامة التجارية (اختياري)',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن العلامة التجارية...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _filterBrands,
          ),
          const SizedBox(height: 16),
          if (_filteredBrands.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _searchController.text.isEmpty
                      ? 'لا توجد علامات تجارية لهذه الفئة'
                      : 'لم يتم العثور على نتائج',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filteredBrands.map((brand) {
                final isSelected = _selectedBrand == brand;
                return FilterChip(
                  label: Text(brand),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedBrand = selected ? brand : null;
                    });
                    widget.onBrandSelected(_selectedBrand);
                  },
                  backgroundColor: AppTheme.surfaceColor,
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
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
                    'إذا لم تجد العلامة التجارية، يمكنك تركها فارغة',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
