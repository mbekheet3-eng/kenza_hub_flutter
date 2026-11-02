import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../config/theme.dart';
import '../../../services/catalog_service.dart';

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
  late Future<List<String>> _sizesFuture;
  final CatalogService _catalogService = CatalogService();

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



  @override
  void initState() {
    super.initState();
    _selectedCondition = widget.initialCondition;
    _selectedColor = widget.initialColor;
    _selectedSize = widget.initialSize;
    _sizesFuture = widget.category == null
        ? Future.value(const <String>[])
        : _catalogService.fetchSizesForCategory(widget.category!);
  }

  @override
  void didUpdateWidget(covariant StepDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _selectedSize = null;
      _sizesFuture = widget.category == null
          ? Future.value(const <String>[])
          : _catalogService.fetchSizesForCategory(widget.category!);
      _notifyChanges();
    }
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'condition': _selectedCondition,
      'color': _selectedColor,
      'size': _selectedSize,
    });
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
    final categoryColor =
        categoryColors[widget.category] ?? AppTheme.primaryColor;

    return FutureBuilder<List<String>>(
      future: _sizesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            'تعذر تحميل المقاسات من قاعدة البيانات',
            style: TextStyle(color: AppTheme.textSecondary),
          );
        }

        final availableSizes = snapshot.data ?? const <String>[];
        if (availableSizes.isEmpty) {
          return Text(
            'لا توجد مقاسات مسجلة لهذا القسم',
            style: TextStyle(color: AppTheme.textSecondary),
          );
        }

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
                  color: isSelected
                      ? categoryColor.withOpacity(0.1)
                      : AppTheme.surfaceColor,
                  border: Border.all(
                    color: isSelected
                        ? categoryColor
                        : AppTheme.borderLight,
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
                          color: isSelected
                              ? categoryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: categoryColor,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
