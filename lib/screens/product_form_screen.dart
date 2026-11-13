import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../l10n/app_strings.dart';

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
  final _customCategoryName = TextEditingController();
  List<Category> _categories = [];
  final List<Category> _selectionPath = [];
  String? _gender;
  String _audience = 'all';
  final List<File> _images = [];
  final List<String> _existingImagePaths = [];
  final List<String> _existingImageUrls = [];
  final List<String> _removedImagePaths = [];
  int _primaryImageIndex = 0;
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
      _audience = product.audience;
      _customCategoryName.text = product.customCategoryName ?? '';
      _existingImagePaths.addAll(product.imagePaths);
      _existingImageUrls.addAll(product.imageUrls);
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _customCategoryName.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getMyGender(),
      ]);
      final categories = results[0] as List<Category>;
      final gender = results[1] as String?;
      final byId = {for (final category in categories) category.id: category};
      final path = <Category>[];
      var current = byId[widget.product?.categoryId];
      while (current != null) {
        path.add(current);
        current = current.parentId == null ? null : byId[current.parentId];
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectionPath
          ..clear()
          ..addAll(path.reversed);
        _gender = gender;
        if (gender == null) _error = AppStrings.of(context)!.genderRequiredToPublish;
        if ((gender == 'female' && _audience == 'men_only') ||
            (gender == 'male' && _audience == 'women_only')) {
          _audience = 'all';
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Category> _childrenOf(String? parentId) => _categories
      .where((category) => category.parentId == parentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  bool get _isOtherCategory =>
      _selectionPath.isNotEmpty && _selectionPath.last.slug.endsWith('-other');

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
      final selectedId = depth < _selectionPath.length ? _selectionPath[depth].id : null;
      fields.add(
        DropdownButtonFormField<String>(
          key: ValueKey('category-level-$depth-${parentId ?? 'root'}'),
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
    if (_isOtherCategory) {
      fields.add(
        TextFormField(
          controller: _customCategoryName,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: AppStrings.of(context)!.customProductType,
            hintText: AppStrings.of(context)!.customProductTypeHint,
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? AppStrings.of(context)!.customProductTypeRequired
              : null,
        ),
      );
      fields.add(const SizedBox(height: 12));
    }
    return fields;
  }

  int get _currentImageCount => _existingImagePaths.length + _images.length;

  Future<File?> _cropFile(File source) async {
    final strings = AppStrings.of(context)!;
    final cropped = await ImageCropper().cropImage(
      sourcePath: source.path,
      maxWidth: 2000,
      maxHeight: 2000,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: strings.cropImageTitle,
          toolbarColor: Theme.of(context).colorScheme.surface,
          toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: strings.cropImageTitle,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );
    return cropped == null ? null : File(cropped.path);
  }

  void _showCropError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context)!.cropImageFailed)),
    );
  }

  Future<void> _pickGallery() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 95,
      maxWidth: 2400,
    );
    if (!mounted || picked.isEmpty) return;

    final available = MarketplaceService.maxImages - _currentImageCount;
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.maxEightPhotos)),
      );
      return;
    }

    final croppedFiles = <File>[];
    try {
      for (final image in picked.take(available)) {
        final cropped = await _cropFile(File(image.path));
        if (cropped != null) croppedFiles.add(cropped);
        if (!mounted) return;
      }
      if (mounted && croppedFiles.isNotEmpty) {
        setState(() => _images.addAll(croppedFiles));
      }
    } catch (_) {
      _showCropError();
    }
  }

  Future<void> _pickCamera() async {
    if (_currentImageCount >= MarketplaceService.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.maxEightPhotos)),
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
      maxWidth: 2400,
    );
    if (!mounted || picked == null) return;

    try {
      final cropped = await _cropFile(File(picked.path));
      if (mounted && cropped != null) {
        setState(() => _images.add(cropped));
      }
    } catch (_) {
      _showCropError();
    }
  }

  Future<void> _cropExistingImage(int index) async {
    final storagePath = _existingImagePaths[index];
    File? temporarySource;
    try {
      temporarySource = await _service.downloadImageForEditing(storagePath);
      final cropped = await _cropFile(temporarySource);
      if (!mounted || cropped == null) return;
      setState(() {
        final wasPrimary = _primaryImageIndex == index;
        _removedImagePaths.add(storagePath);
        _existingImagePaths.removeAt(index);
        _existingImageUrls.removeAt(index);
        if (wasPrimary) {
          _primaryImageIndex = _existingImagePaths.length + _images.length;
        } else if (_primaryImageIndex > index) {
          _primaryImageIndex--;
        }
        _images.add(cropped);
      });
    } catch (_) {
      _showCropError();
    } finally {
      if (temporarySource != null) {
        try {
          await temporarySource.parent.delete(recursive: true);
        } catch (_) {
          // Temporary crop source cleanup is best-effort.
        }
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _removedImagePaths.add(_existingImagePaths.removeAt(index));
      _existingImageUrls.removeAt(index);
      if (_primaryImageIndex == index) {
        _primaryImageIndex = 0;
      } else if (_primaryImageIndex > index) {
        _primaryImageIndex--;
      }
    });
  }

  void _setPrimaryImage(int index) {
    setState(() => _primaryImageIndex = index);
  }

  Widget _primaryImageMarker({required bool selected, required VoidCallback onTap}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Positioned(
      bottom: 0,
      right: 0,
      child: Material(
        color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: selected
              ? (isArabic ? 'الصورة الرئيسية' : 'Main photo')
              : (isArabic ? 'تعيين كصورة رئيسية' : 'Set as main photo'),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          style: IconButton.styleFrom(
            backgroundColor: selected ? Theme.of(context).colorScheme.primary : Colors.white,
            foregroundColor: selected ? Colors.white : Theme.of(context).colorScheme.primary,
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          onPressed: _saving ? null : onTap,
          icon: Icon(
            selected ? Icons.star : Icons.star_border,
            size: 18,
            color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _selectedLeafCategoryId;
    if (categoryId == null) {
      setState(() => _error = AppStrings.of(context)!.noCategoriesTryLater);
      return;
    }
    if (_currentImageCount == 0) {
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
          audience: _audience,
          customCategoryName: _isOtherCategory ? _customCategoryName.text.trim() : null,
          images: _images,
          removedImagePaths: _removedImagePaths,
          primaryImageIndex: _primaryImageIndex,
        );
      } else {
        await _service.publishProduct(
          categoryId: categoryId,
          title: _title.text,
          description: _description.text,
          price: price,
          images: _images,
          audience: _audience,
          customCategoryName: _isOtherCategory ? _customCategoryName.text.trim() : null,
          primaryImageIndex: _primaryImageIndex,
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
      appBar: AppBar(title: Text(_isEditing ? AppStrings.of(context)!.editProductTitle : AppStrings.of(context)!.addProductTitle)),
      body: _loading && _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ..._buildCategoryFields(context),
                  const SizedBox(height: 14),
                  if (_gender != null) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _audience,
                      decoration: InputDecoration(labelText: AppStrings.of(context)!.allowedAudience),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(AppStrings.of(context)!.audienceEveryone)),
                        if (_gender == 'female')
                          DropdownMenuItem(value: 'women_only', child: Text(AppStrings.of(context)!.audienceWomenOnly)),
                        if (_gender == 'male')
                          DropdownMenuItem(value: 'men_only', child: Text(AppStrings.of(context)!.audienceMenOnly)),
                      ],
                      onChanged: (value) => setState(() => _audience = value ?? 'all'),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _title,
                    maxLength: 100,
                    decoration: InputDecoration(labelText: AppStrings.of(context)!.productTitleLabel),
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
                  ...[
                    const SizedBox(height: 20),
                    Text(AppStrings.of(context)!.productPhotosLimit, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving || _currentImageCount >= MarketplaceService.maxImages ? null : _pickGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(AppStrings.of(context)!.gallery),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving || _currentImageCount >= MarketplaceService.maxImages ? null : _pickCamera,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(AppStrings.of(context)!.camera),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_existingImageUrls.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _existingImageUrls.length; i++)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _existingImageUrls[i],
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 88,
                                      height: 88,
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton.filled(
                                    tooltip: AppStrings.of(context)!.removeImage,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _saving ? null : () => _removeExistingImage(i),
                                    icon: const Icon(Icons.close, size: 16),
                                  ),
                                ),
                                _primaryImageMarker(
                                  selected: _primaryImageIndex == i,
                                  onTap: () => _setPrimaryImage(i),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: IconButton.filled(
                                    tooltip: AppStrings.of(context)!.cropImageTitle,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _saving ? null : () => _cropExistingImage(i),
                                    icon: const Icon(Icons.crop, size: 16),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    if (_existingImageUrls.isNotEmpty) const SizedBox(height: 10),
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
                                  onPressed: () => setState(() {
                                    _images.removeAt(i);
                                    if (_primaryImageIndex == _existingImagePaths.length + i) {
                                      _primaryImageIndex = 0;
                                    } else if (_primaryImageIndex > _existingImagePaths.length + i) {
                                      _primaryImageIndex--;
                                    }
                                  }),
                                  icon: const Icon(Icons.close, size: 16),
                                ),
                              ),
                              _primaryImageMarker(
                                selected: _primaryImageIndex == _existingImagePaths.length + i,
                                onTap: () => _setPrimaryImage(_existingImagePaths.length + i),
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
                  if (_saving) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.of(context)!.moderationInProgress,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving || _loading || _gender == null ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? AppStrings.of(context)!.publishProductChanges : AppStrings.of(context)!.publishNewProduct),
                  ),
                ],
              ),
            ),
    );
  }
}
