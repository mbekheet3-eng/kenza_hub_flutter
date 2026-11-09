import 'dart:io';

import 'package:flutter/material.dart';
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
  String? _categoryId;
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
      _categoryId = product.categoryId;
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
      setState(() {
        _categories = categories;
        _categoryId ??= categories.isNotEmpty ? categories.first.id : null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        const SnackBar(content: Text('الحد الأقصى 8 صور')),
      );
      return;
    }
    setState(() => _images.add(File(picked.path)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = 'لا توجد فئات متاحة. حاول لاحقًا.');
      return;
    }
    if (!_isEditing && _images.isEmpty) {
      setState(() => _error = 'أضف صورة واحدة على الأقل');
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
          categoryId: _categoryId!,
        );
      } else {
        await _service.publishProduct(
          categoryId: _categoryId!,
          title: _title.text,
          description: _description.text,
          price: price,
          images: _images,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'تعديل المنتج' : 'إضافة منتج')),
      body: _loading && _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'الفئة'),
                    items: _categories
                        .map((category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.nameAr),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) => value == null ? 'اختر الفئة' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _title,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'عنوان المنتج'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'اكتب عنوان المنتج'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: const InputDecoration(labelText: 'وصف المنتج (اختياري)'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'السعر بالجنيه المصري',
                      suffixText: 'ج.م',
                    ),
                    validator: (value) {
                      final price = double.tryParse(value ?? '');
                      return price == null || price <= 0 ? 'أدخل سعرًا أكبر من صفر' : null;
                    },
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 20),
                    Text('صور المنتج (حتى 8 صور)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('المعرض'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickCamera,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('الكاميرا'),
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
                        : Text(_isEditing ? 'حفظ التعديلات' : 'نشر المنتج'),
                  ),
                ],
              ),
            ),
    );
  }
}
