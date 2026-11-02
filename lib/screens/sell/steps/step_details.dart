import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../config/theme.dart';

class StepDetails extends StatefulWidget {
  final Function(Map<String, String?>) onDataChanged;
  final String? category;
  final String? initialCondition;
  final String? initialColor;
  final String? initialSize;

  const StepDetails({
    required this.onDataChanged,
    required this.category,
    required this.initialCondition,
    required this.initialColor,
    required this.initialSize,
  });

  @override
  State<StepDetails> createState() => _StepDetailsState();
}

class _StepDetailsState extends State<StepDetails> {
  late String? _selectedCondition;
  late String? _selectedColor;
  late String? _selectedSize;

  final List<String> conditions = conditionOptions;

  final List<String> colors = [
    'أسود',
    'أبيض',
    'رمادي',
    'أحمر',
    'أزرق',
    'أخضر',
    'أصفر',
    'برتقالي',
    'بنفسجي',
    'وردي',
    'بني',
    'كحلي',
    'بيج',
    'ذهبي',
    'فضي',
    'متعدد الألوان',
    'أخرى',
  ];

  final Map<String, List<String>> sizes = {
    'clothes': ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'One Size'],
    'shoes': ['35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45'],
    'kids': ['0-3 Months', '3-6 Months', '6-12 Months', '1-2 Years', '2-3 Years', '4-5 Years', '6-7 Years', '8-9 Years', '10-11 Years', '12-13 Years', '14-15 Years'],
  };

  @override
  void initState() {
    super.initState();
    _selectedCondition = widget.initialCondition;
    _selectedColor = widget.initialColor;
    _selectedSize = widget.initialSize;
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'condition': _selectedCondition,
      'color': _selectedColor,
      'size': _selectedSize,
    });
  }

  List<String> _getSizesForCategory() {
    if (widget.category == null) return [];
    return sizes[widget.category] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isHomeCategory = widget.category != null &&
        categorySkipFields[widget.category] == true;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Condition
          Text(
            'حالة المنتج',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildConditionOptions(),
          const SizedBox(height: 16),

          // Color (if not home category)
          if (!isHomeCategory) ...[
            Text(
              'اللون',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildColorOptions(),
            const SizedBox(height: 16),
          ],

          // Size (if not home category)
          if (!isHomeCategory) ...[
            Text(
              'المقاس',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSizeOptions(),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: conditions.map((condition) {
        final isSelected = _selectedCondition == condition;
        return FilterChip(
          label: Text(condition),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCondition = selected ? condition : null;
            });
            _notifyChanges();
          },
          backgroundColor: AppTheme.surfaceColor,
          selectedColor: AppTheme.primaryColor.withOpacity(0.1),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = _selectedColor == color;
        return FilterChip(
          label: Text(color),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedColor = selected ? color : null;
            });
            _notifyChanges();
          },
          backgroundColor: AppTheme.surfaceColor,
          selectedColor: AppTheme.primaryColor.withOpacity(0.1),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeOptions() {
    final categoryColors = {
      'clothes': AppTheme.primaryColor,
      'shoes': AppTheme.secondaryColor,
      'kids': AppTheme.accentColor,
    };

    final availableSizes = _getSizesForCategory();
    if (availableSizes.isEmpty) {
      return Center(
        child: Text(
          'اختر فئة أولاً',
          style: TextStyle(color: AppTheme.textTertiary),
        ),
      );
    }

    final categoryColor = categoryColors[widget.category] ?? AppTheme.primaryColor;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: availableSizes.length,
      itemBuilder: (context, index) {
        final size = availableSizes[index];
        final isSelected = _selectedSize == size;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSize = isSelected ? null : size;
            });
            _notifyChanges();
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? categoryColor.withOpacity(0.1) : AppTheme.surfaceColor,
              border: Border.all(
                color: isSelected ? categoryColor : AppTheme.borderLight,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    size,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? categoryColor : AppTheme.textPrimary,
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, size: 14, color: categoryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
