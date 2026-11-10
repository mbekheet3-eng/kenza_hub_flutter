import 'dart:io';

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _service = MarketplaceService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  List<Category> _categories = [];
  final List<Category> _selectionPath = [];
  final List<File> _images = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _title.text = product.title;
      _description.text = product.description;
      _price.text = product.price.toStringAsFixed(0);
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final categories = await _service.getCategories();
      if (!mounted) return;
      final byId = {for (final category in categories) category.id: category};
      final path = <Category>[];
      var current = byId[widget.product?.categoryId];
      while (current != null) {
        path.add(current);
        current = current.parentId == null ? null : byId[current.parentId];
      }
      setState(() {
        _categories = categories;
        _selectionPath
          ..clear()
          ..addAll(path.reversed);
      });
    } catch (error) {
      if (mounted) setState(() => _error = AppStrings.of(context)!.categoryLoadDatabaseError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Category> _childrenOf(String? parentId) => _categories
      .where((category) => category.parentId == parentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  String? get _selectedLeafCategoryId {
    if (_selectionPath.isEmpty) return null;
    final selected = _selectionPath.last;
    return _childrenOf(selected.id).isEmpty ? selected.id : null;
  }

  void _selectCategory(int depth, String? categoryId) {
    setState(() {
      final nextPath = _selectionPath.take(depth).toList();
      if (categoryId != null) {
        nextPath.add(_categories.firstWhere((category) => category.id == categoryId));
      }
      _selectionPath
        ..clear()
        ..addAll(nextPath);
    });
  }

  List<Widget> _buildCategoryFields(BuildContext context) {
    final fields = <Widget>[];
    final languageCode = Localizations.localeOf(context).languageCode;
    for (var depth = 0; depth <= _selectionPath.length; depth++) {
      final parentId = depth == 0 ? null : _selectionPath[depth - 1].id;
      final options = _childrenOf(parentId);
      if (options.isEmpty) continue;
      final selectedId = depth < _selectionPath.length
          ? _selectionPath[depth].id
          : null;
      fields.add(
        DropdownButtonFormField<String>(
          initialValue: selectedId,
          decoration: InputDecoration(
            labelText: AppStrings.of(context)!.categoryFieldLabel,
          ),
          items: options
              .map((category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.nameFor(languageCode)),
                  ))
              .toList(),
          onChanged: _saving ? null : (value) => _selectCategory(depth, value),
        ),
      );
      fields.add(const SizedBox(height: 12));
    }
    return fields;
  }

  Future<void> _pickGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1800);
    if (!mounted || picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.map((file) => File(file.path)));
      if (_images.length > MarketplaceService.maxImages) {
        _images.removeRange(MarketplaceService.maxImages, _images.length);
      }
    });
  }

  Future<void> _pickCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (!mounted || picked == null) return;
    if (_images.length >= MarketplaceService.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.maxProductImagesReached)),
      );
      return;
    }
    setState(() => _images.add(File(picked.path)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _selectedLeafCategoryId;
    if (categoryId == null) {
      setState(() => _error = AppStrings.of(context)!.chooseCategoryValidation);
      return;
    }
    if (!_isEditing && _images.isEmpty) {
      setState(() => _error = AppStrings.of(context)!.addAtLeastOnePhoto);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final price = double.parse(_price.text.trim());
      if (_isEditing) {
        await _service.updateProduct(
          productId: widget.product!.id,
          title: _title.text,
          description: _description.text,
          price: price,
          categoryId: categoryId,
        );
      } else {
        await _service.publishProduct(
          categoryId: categoryId,
          title: _title.text,
          description: _description.text,
          price: price,
          images: _images,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = AppStrings.of(context)!.productSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? AppStrings.of(context)!.editProduct : AppStrings.of(context)!.sellProduct)),
      body: _loading && _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ..._buildCategoryFields(context),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _title,
                    maxLength: 100,
                    decoration: InputDecoration(labelText: AppStrings.of(context)!.productTitleField),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? AppStrings.of(context)!.productTitleRequired
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: InputDecoration(labelText: AppStrings.of(context)!.productDescriptionOptional),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppStrings.of(context)!.priceEgpLabel,
                      suffixText: AppStrings.of(context)!.currency,
                    ),
                    validator: (value) {
                      final price = double.tryParse(value ?? '');
                      return price == null || price <= 0 ? AppStrings.of(context)!.priceMustBePositive : null;
                    },
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 20),
                    Text(AppStrings.of(context)!.productPhotos, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(AppStrings.of(context)!.gallery),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickCamera,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(AppStrings.of(context)!.camera),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _images.length; i++)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _images[i],
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton.filled(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setState(() => _images.removeAt(i)),
                                  icon: const Icon(Icons.close, size: 16),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving || _loading ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? AppStrings.of(context)!.saveChanges : AppStrings.of(context)!.publishProduct),
                  ),
                ],
              ),
            ),
    );
  }
}
