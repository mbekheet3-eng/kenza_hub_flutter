import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../services/catalog_service.dart';

class StepDetails extends StatefulWidget {
  final Function(Map<String, String?>) onDataChanged;
  final String? category;
  final String? initialCondition;
  final String? initialColor;
  final String? initialSize;
  final bool skipVariantFields;

  const StepDetails({
    required this.onDataChanged,
    required this.category,
    required this.initialCondition,
    required this.initialColor,
    required this.initialSize,
    required this.skipVariantFields,
  });

  @override
  State<StepDetails> createState() => _StepDetailsState();
}

class _StepDetailsState extends State<StepDetails> {
  late String? _selectedCondition;
  late String? _selectedColor;
  late String? _selectedSize;
  late Future<List<String>> _sizesFuture;
  late Future<List<String>> _conditionsFuture;
  late Future<List<String>> _colorsFuture;
  final CatalogService _catalogService = CatalogService();



  @override
  void initState() {
    super.initState();
    _selectedCondition = widget.initialCondition;
    _selectedColor = widget.initialColor;
    _selectedSize = widget.initialSize;
    _sizesFuture = widget.category == null
        ? Future.value(const <String>[])
        : _catalogService.fetchSizesForCategory(widget.category!);
    _conditionsFuture = _catalogService.fetchConditions();
    _colorsFuture = _catalogService.fetchColors();
  }

  @override
  void didUpdateWidget(covariant StepDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _selectedColor = null;
      _selectedSize = null;
      _sizesFuture = widget.category == null
          ? Future.value(const <String>[])
          : _catalogService.fetchSizesForCategory(widget.category!);
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
    final isHomeCategory = widget.skipVariantFields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).productCondition,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildConditionOptions(),
        if (!isHomeCategory)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context).optionalColorSize),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).colorLabel),
                    const SizedBox(height: 8),
                    _buildColorOptions(),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context).sizeLabel),
                    const SizedBox(height: 8),
                    _buildSizeOptions(),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildConditionOptions() {
    return FutureBuilder<List<String>>(
      future: _conditionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).productConditionsLoadError),
              TextButton(
                onPressed: () => setState(
                  () => _conditionsFuture = _catalogService.fetchConditions(),
                ),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          );
        }

        final conditions = snapshot.data ?? const <String>[];
        if (conditions.isEmpty) {
          return Text(AppLocalizations.of(context).noActiveProductConditions);
        }

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
      },
    );
  }

  Widget _buildColorOptions() {
    return FutureBuilder<List<String>>(
      future: _colorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).colorsLoadError),
              TextButton(
                onPressed: () => setState(
                  () => _colorsFuture = _catalogService.fetchColors(),
                ),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          );
        }

        final availableColors = snapshot.data ?? const <String>[];
        if (availableColors.isEmpty) {
          return Text(AppLocalizations.of(context).noColorsForCategory);
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableColors.map((color) {
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
      },
    );
  }

  Widget _buildSizeOptions() {
    final categoryColors = {
      'clothes': AppTheme.primaryColor,
      'shoes': AppTheme.secondaryColor,
      'kids-supplies': AppTheme.accentColor,
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).sizesLoadError,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              TextButton(
                onPressed: widget.category == null
                    ? null
                    : () => setState(
                          () => _sizesFuture =
                              _catalogService.fetchSizesForCategory(widget.category!),
                        ),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          );
        }

        final availableSizes = snapshot.data ?? const <String>[];
        if (availableSizes.isEmpty) {
          return Text(
            AppLocalizations.of(context).noSizesForCategory,
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
