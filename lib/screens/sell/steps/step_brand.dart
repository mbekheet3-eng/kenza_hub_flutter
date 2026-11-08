import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

import '../../../config/theme.dart';
import '../../../services/catalog_service.dart';

class StepBrand extends StatefulWidget {
  final Function(String?) onBrandSelected;
  final String? selectedBrand;
  final String? category;
  final bool skipVariantFields;

  const StepBrand({
    super.key,
    required this.onBrandSelected,
    required this.selectedBrand,
    required this.category,
    required this.skipVariantFields,
  });

  @override
  State<StepBrand> createState() => _StepBrandState();
}

class _StepBrandState extends State<StepBrand> {
  final CatalogService _catalogService = CatalogService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<String>> _brandsFuture;
  String? _selectedBrand;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.selectedBrand;
    _brandsFuture = _catalogService.fetchBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StepBrand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBrand != widget.selectedBrand) {
      _selectedBrand = widget.selectedBrand;
    }
    if (oldWidget.category != widget.category) {
      _selectedBrand = widget.selectedBrand;
    }
  }

  void _selectBrand(String? brand) {
    setState(() => _selectedBrand = brand);
    widget.onBrandSelected(brand);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category == null || widget.skipVariantFields) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context).brandOptionalNote,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return FutureBuilder<List<String>>(
      future: _brandsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              Text(AppLocalizations.of(context).brandLoadError),
              TextButton(
                onPressed: () {
                  setState(() {
                    _brandsFuture = _catalogService.fetchBrands();
                  });
                },
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          );
        }

        final brands = snapshot.data ?? const <String>[];
        final filtered = brands
            .where((brand) =>
                brand.toLowerCase().contains(_query.trim().toLowerCase()))
            .toList(growable: false);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).chooseBrandOptional,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchAvailableBrands,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              FilterChip(
                label: Text(AppLocalizations.of(context).noBrand),
                selected: _selectedBrand == null,
                onSelected: (_) => _selectBrand(null),
                backgroundColor: AppTheme.surfaceColor,
                selectedColor: AppTheme.primaryColor.withOpacity(0.1),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    brands.isEmpty
                        ? 'لا توجد علامات تجارية مسجلة حاليًا'
                        : 'لم يتم العثور على نتائج',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filtered.map((brand) {
                    final selected = _selectedBrand == brand;
                    return FilterChip(
                      label: Text(brand),
                      selected: selected,
                      onSelected: (_) =>
                          _selectBrand(selected ? null : brand),
                      backgroundColor: AppTheme.surfaceColor,
                      selectedColor:
                          AppTheme.primaryColor.withOpacity(0.1),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.primaryColor
                            : AppTheme.borderLight,
                        width: selected ? 2 : 1,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
