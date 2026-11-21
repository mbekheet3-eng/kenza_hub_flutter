import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../l10n/app_strings.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';
import '../services/product_ai_suggestion_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _service = MarketplaceService();
  final _aiService = ProductAiSuggestionService();
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
  int _selectedImageIndex = 0;
  bool _loading = false;
  bool _saving = false;
  bool _aiLoading = false;
  Map<String, dynamic>? _aiSuggestion;
  String? _aiError;
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
        setState(() {
          final wasEmpty = _currentImageCount == 0;
          _images.addAll(croppedFiles);
          if (wasEmpty) _selectedImageIndex = 0;
        });
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
        setState(() {
          final wasEmpty = _currentImageCount == 0;
          _images.add(cropped);
          if (wasEmpty) _selectedImageIndex = 0;
        });
      }
    } catch (_) {
      _showCropError();
    }
  }

  Future<void> _cropImageAt(int index) async {
    if (index < 0 || index >= _currentImageCount) return;

    if (index < _existingImagePaths.length) {
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
          if (_primaryImageIndex > index) {
            _primaryImageIndex--;
          } else if (wasPrimary) {
            _primaryImageIndex = _currentImageCount;
          }
          _images.add(cropped);
          _selectedImageIndex = _currentImageCount - 1;
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
      return;
    }

    final localIndex = index - _existingImagePaths.length;
    try {
      final cropped = await _cropFile(_images[localIndex]);
      if (!mounted || cropped == null) return;
      setState(() {
        _images[localIndex] = cropped;
        _selectedImageIndex = index;
      });
    } catch (_) {
      _showCropError();
    }
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _currentImageCount) return;
    setState(() {
      if (index < _existingImagePaths.length) {
        _removedImagePaths.add(_existingImagePaths.removeAt(index));
        _existingImageUrls.removeAt(index);
      } else {
        _images.removeAt(index - _existingImagePaths.length);
      }

      if (_primaryImageIndex == index) {
        _primaryImageIndex = 0;
      } else if (_primaryImageIndex > index) {
        _primaryImageIndex--;
      }

      if (_currentImageCount == 0) {
        _selectedImageIndex = 0;
        _primaryImageIndex = 0;
      } else if (_selectedImageIndex == index) {
        _selectedImageIndex = index >= _currentImageCount ? _currentImageCount - 1 : index;
      } else if (_selectedImageIndex > index) {
        _selectedImageIndex--;
      }
    });
  }

  Widget _buildImageAt(int index, {double? width, double? height}) {
    if (index < _existingImagePaths.length) {
      return Image.network(
        _existingImageUrls[index],
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    }
    return Image.file(
      _images[index - _existingImagePaths.length],
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  Widget _buildImageEditor() {
    final strings = AppStrings.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final count = _currentImageCount;
    if (count == 0) return const SizedBox.shrink();

    final selected = _selectedImageIndex.clamp(0, count - 1).toInt();
    final isPrimary = _primaryImageIndex == selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: _buildImageAt(selected),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _primaryImageMarker(
                        selected: isPrimary,
                        onTap: () => _setPrimaryImage(selected),
                      ),
                      const SizedBox(width: 8),
                      _imageActionButton(
                        icon: Icons.crop_rotate,
                        tooltip: strings.cropImageTitle,
                        onTap: () => _cropImageAt(selected),
                      ),
                      const SizedBox(width: 8),
                      _imageActionButton(
                        icon: Icons.delete_outline,
                        tooltip: strings.removeImage,
                        onTap: () => _removeImageAt(selected),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text(
                        isPrimary
                            ? (isArabic ? 'الصورة الرئيسية' : 'Main photo')
                            : (isArabic ? 'اختر النجمة لتعيينها رئيسية' : 'Tap the star to set as main'),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                if (_saving)
                  const ColoredBox(
                    color: Color(0x55000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(isArabic ? 'اضغط على صورة لمعاينتها' : 'Tap a photo to preview it',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final active = index == selected;
              return GestureDetector(
                onTap: _saving ? null : () => setState(() => _selectedImageIndex = index),
                child: Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: _buildImageAt(index, width: 72, height: 72),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _imageActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: _saving ? null : onTap,
        color: Theme.of(context).colorScheme.primary,
        icon: Icon(icon),
      ),
    );
  }

  void _setPrimaryImage(int index) {
    setState(() => _primaryImageIndex = index);
  }

  Widget _primaryImageMarker({required bool selected, required VoidCallback onTap}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return IconButton(
      tooltip: selected
          ? (isArabic ? 'الصورة الرئيسية' : 'Main photo')
          : (isArabic ? 'تعيين كصورة رئيسية' : 'Set as main photo'),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: selected ? Theme.of(context).colorScheme.primary : Colors.white,
        foregroundColor: selected ? Colors.white : Theme.of(context).colorScheme.primary,
      ),
      onPressed: _saving ? null : onTap,
      icon: Icon(selected ? Icons.star : Icons.star_border, size: 19),
    );
  }


  Future<void> _requestAiSuggestions() async {
    if (_currentImageCount == 0 || _aiLoading || _saving) return;

    // Read inherited widget data before the first async gap.
    final languageCode = Localizations.localeOf(context).languageCode;

    setState(() {
      _aiLoading = true;
      _aiError = null;
      _aiSuggestion = null;
    });

    final files = <File>[..._images];
    final temporaryFiles = <File>[];
    try {
      for (final path in _existingImagePaths) {
        if (files.length >= 3) break;
        final temporary = await _service.downloadImageForEditing(path);
        temporaryFiles.add(temporary);
        files.add(temporary);
      }

      final suggestion = await _aiService.suggest(
        images: files,
        categories: _categories,
        title: _title.text,
        description: _description.text,
        languageCode: languageCode,
      );
      if (mounted) setState(() => _aiSuggestion = suggestion);
    } catch (error) {
      if (mounted) {
        setState(() => _aiError = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      for (final file in temporaryFiles) {
        try {
          await file.parent.delete(recursive: true);
        } catch (_) {
          // Temporary image cleanup is best-effort.
        }
      }
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _applyAiSuggestion() {
    final suggestion = _aiSuggestion;
    if (suggestion == null) return;

    final categoryId = suggestion['category_id'];
    final title = suggestion['suggested_title'];
    final description = suggestion['suggested_description'];
    final price = suggestion['recommended_price'];

    final byId = {for (final category in _categories) category.id: category};
    final nextPath = <Category>[];
    var current = categoryId is String ? byId[categoryId] : null;
    while (current != null) {
      nextPath.add(current);
      current = current.parentId == null ? null : byId[current.parentId];
    }

    setState(() {
      if (title is String && title.trim().isNotEmpty) _title.text = title.trim();
      if (description is String && description.trim().isNotEmpty) {
        _description.text = description.trim();
      }
      if (nextPath.isNotEmpty) {
        _selectionPath
          ..clear()
          ..addAll(nextPath.reversed);
      }
      if (price is num && price > 0) _price.text = price.round().toString();
      _aiSuggestion = null;
    });
  }

  Widget _buildAiSuggestionCard() {
    final suggestion = _aiSuggestion!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabic = languageCode == 'ar';
    final isFrench = languageCode == 'fr';

    String label(String ar, String en, String fr) =>
        isArabic ? ar : isFrench ? fr : en;

    String? categoryName;
    final categoryId = suggestion['category_id'];
    if (categoryId is String) {
      for (final category in _categories) {
        if (category.id == categoryId) {
          categoryName = category.nameFor(languageCode);
          break;
        }
      }
    }

    final title = suggestion['suggested_title'] as String? ?? '';
    final description = suggestion['suggested_description'] as String? ?? '';
    final minPrice = suggestion['price_min'];
    final maxPrice = suggestion['price_max'];
    final recommendedPrice = suggestion['recommended_price'];
    final missingInfo = (suggestion['missing_info'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label('اقتراحات كنزا الذكية', 'Kenza AI suggestions', 'Suggestions IA Kenza'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (categoryName != null && categoryName.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('${label("التصنيف المقترح", "Suggested category", "Catégorie suggérée")}: $categoryName'),
            ],
            if (title.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${label("العنوان", "Title", "Titre")}: $title'),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${label("الوصف", "Description", "Description")}: $description'),
            ],
            if (minPrice is num && maxPrice is num) ...[
              const SizedBox(height: 8),
              Text(
                '${label("النطاق السعري الاسترشادي", "Indicative price range", "Fourchette de prix indicative")}: '
                '${minPrice.round()} - ${maxPrice.round()} ${label("جنيه", "EGP", "EGP")}',
              ),
              if (recommendedPrice is num)
                Text(
                  '${label("السعر المقترح", "Suggested price", "Prix suggéré")}: '
                  '${recommendedPrice.round()} ${label("جنيه", "EGP", "EGP")}',
                ),
              Text(
                label(
                  'السعر تقديري وليس سعرًا ملزمًا.',
                  'This is an estimate, not a required price.',
                  'Il s’agit d’une estimation, pas d’un prix imposé.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (missingInfo.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                label('معلومات ناقصة يُفضّل استكمالها:', 'Information to confirm:', 'Informations à confirmer:'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...missingInfo.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $item'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _saving ? null : _applyAiSuggestion,
              child: Text(label('تطبيق الاقتراحات', 'Apply suggestions', 'Appliquer les suggestions')),
            ),
          ],
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
                          icon: Image.asset('assets/gallery.png', width: 22, height: 22),
                          label: Text(AppStrings.of(context)!.gallery),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving || _currentImageCount >= MarketplaceService.maxImages ? null : _pickCamera,
                          icon: Image.asset('assets/icons/camera.png', width: 22, height: 22),
                          label: Text(AppStrings.of(context)!.camera),
                        ),
                      ],
                    ),
                    _buildImageEditor(),
                  ],
                  if (_currentImageCount > 0) ...[
                    OutlinedButton.icon(
                      onPressed: _saving || _aiLoading ? null : _requestAiSuggestions,
                      icon: _aiLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'اقتراح التصنيف والوصف والسعر بالذكاء الاصطناعي'
                            : Localizations.localeOf(context).languageCode == 'fr'
                                ? 'Suggérer catégorie, description et prix avec l’IA'
                                : 'Suggest category, description and price with AI',
                      ),
                    ),
                    if (_aiError != null)
                      Text(_aiError!, style: const TextStyle(color: Colors.red)),
                    if (_aiSuggestion != null) _buildAiSuggestionCard(),
                  ],
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
                  const SizedBox(height: 12),
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
