import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/marketplace_product_service.dart';
import '../../services/catalog_service.dart';
import '../../services/upload_service.dart';
import '../../config/theme.dart';
import 'steps/step_images.dart';
import 'steps/step_category.dart';
import 'steps/step_brand.dart';
import 'steps/step_details.dart';
import 'steps/step_price.dart';

class SellWizardScreen extends StatefulWidget {
  const SellWizardScreen({Key? key}) : super(key: key);

  @override
  State<SellWizardScreen> createState() => _SellWizardScreenState();
}

class _SellWizardScreenState extends State<SellWizardScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Form data
  List<File> _selectedImages = [];
  String? _category;
  String? _brand;
  String? _condition;
  String? _color;
  String? _size;
  String _title = '';
  String _description = '';
  double _price = 0;
  bool _skipVariantFields = false;
  bool _isResolvingCategoryRules = false;

  final _productService = MarketplaceProductService();
  final _catalogService = CatalogService();
  final _uploadService = UploadService();

  late List<Step> steps;

  @override
  void initState() {
    super.initState();
    _initializeSteps();
  }

  void _initializeSteps() {
    steps = [
      Step(
        title: const Text('الصور'),
        content: StepImages(
          onImagesSelected: _onImagesSelected,
          initialImages: _selectedImages,
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('الفئة'),
        content: StepCategory(
          onCategorySelected: _onCategorySelected,
          selectedCategory: _category,
        ),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text('البيانات'),
        content: StepDetails(
          onDataChanged: _onDetailsChanged,
          category: _category,
          initialCondition: _condition,
          initialColor: _color,
          initialSize: _size,
          skipVariantFields: _skipVariantFields,
        ),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text('العلامة التجارية'),
        content: StepBrand(
          onBrandSelected: _onBrandSelected,
          selectedBrand: _brand,
          category: _category,
          skipVariantFields: _skipVariantFields,
        ),
        isActive: _currentStep >= 3,
      ),
      Step(
        title: const Text('الوصف'),
        content: StepDescriptionAndTitle(
          onDataChanged: _onDescriptionChanged,
          initialTitle: _title,
          initialDescription: _description,
        ),
        isActive: _currentStep >= 4,
      ),
      Step(
        title: const Text('السعر'),
        content: StepPrice(
          onPriceChanged: _onPriceChanged,
          initialPrice: _price,
        ),
        isActive: _currentStep >= 5,
      ),
      Step(
        title: const Text('التحقق'),
        content: _buildReviewStep(),
        isActive: _currentStep >= 6,
      ),
    ];
  }

  void _onImagesSelected(List<File> images) {
    setState(() {
      _selectedImages = images;
    });
  }

  Future<void> _onCategorySelected(String? category) async {
    setState(() {
      _category = category;
      _skipVariantFields = false;
      _isResolvingCategoryRules = category != null;
      // A category change invalidates previously selected lookup values.
      _brand = null;
      _color = null;
      _size = null;
    });

    if (category == null) return;
    try {
      final rootSlug = await _catalogService.fetchRootCategorySlug(category);
      if (rootSlug == null) {
        throw StateError('Category root could not be resolved');
      }
      if (!mounted) return;
      setState(() {
        _skipVariantFields = rootSlug == 'kids' || rootSlug == 'home';
        _isResolvingCategoryRules = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isResolvingCategoryRules = false);
        _showError('تعذر تحديد قواعد القسم. حاول اختيار القسم مرة أخرى.');
      }
    }
  }

  void _onDetailsChanged(Map<String, String?> data) {
    setState(() {
      _condition = data['condition'];
      _color = data['color'];
      _size = data['size'];
    });
  }

  void _onBrandSelected(String? brand) {
    setState(() {
      _brand = brand;
    });
  }

  void _onDescriptionChanged(Map<String, String> data) {
    setState(() {
      _title = data['title'] ?? '';
      _description = data['description'] ?? '';
    });
  }

  void _onPriceChanged(double price) {
    setState(() {
      _price = price;
    });
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedImages.isNotEmpty;
      case 1:
        return _category != null;
      case 2:
        return !_isResolvingCategoryRules &&
            _condition != null &&
            (_skipVariantFields || (_color != null && _size != null));
      case 3:
        return _category != null; // Brand is optional.
      case 4:
        return _title.isNotEmpty && _description.isNotEmpty;
      case 5:
        return _price > 0;
      default:
        return true;
    }
  }

  Future<void> _publishProduct() async {
    if (!_validateAllData()) {
      _showError('يرجى ملء جميع البيانات المطلوبة');
      return;
    }

    setState(() => _isLoading = true);
    final uploadedImageUrls = <String>[];

    try {
      // 1. Ensure the default seller profile exists before uploading files.
      await _productService.ensureSellerProfile();

      // 2. Upload images
      uploadedImageUrls.addAll(
        await _uploadService.uploadImages(_selectedImages),
      );

      // 3. Resolve database foreign keys and create the product + image rows.
      await _productService.createProduct(
        categorySlug: _category!,
        title: _title,
        description: _description,
        price: _price,
        conditionLabel: _condition!,
        colorLabel: _skipVariantFields ? null : _color,
        sizeLabel: _skipVariantFields ? null : _size,
        brandName: _brand,
        imageUrls: uploadedImageUrls,
      );

      // 4. Clean up cache
      await _uploadService.cleanupCache();

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر المنتج بنجاح')),
        );
        context.pushReplacement('/home');
      }
    } catch (e) {
      if (uploadedImageUrls.isNotEmpty) {
        await _uploadService.deleteImages(uploadedImageUrls);
      }
      _showError('فشل نشر المنتج: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateAllData() {
    return _selectedImages.isNotEmpty &&
        _category != null &&
        _condition != null &&
        !_isResolvingCategoryRules &&
        (_skipVariantFields || (_color != null && _size != null)) &&
        _title.isNotEmpty &&
        _description.isNotEmpty &&
        _price > 0;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewSection('الصور', _buildImagePreview()),
          _buildReviewSection('الفئة', Text(_category ?? '-')),
          _buildReviewSection('الحالة', Text(_condition ?? '-')),
          if (!_skipVariantFields) ...[
            _buildReviewSection('اللون', Text(_color ?? '-')),
            _buildReviewSection('المقاس', Text(_size ?? '-')),
            _buildReviewSection('العلامة التجارية', Text(_brand ?? '-')),
          ],
          _buildReviewSection('العنوان', Text(_title)),
          _buildReviewSection('الوصف', Text(_description)),
          _buildReviewSection('السعر', Text('$_price ج.م', 
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _publishProduct,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('نشر المنتج'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_selectedImages[index]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _initializeSteps();

    if (!context.watch<AuthProvider>().isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('بيع منتج')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'سجّل الدخول أولاً حتى تتمكن من عرض منتجاتك للبيع',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('تسجيل الدخول'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('بيع منتج'),
        elevation: 0,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme,
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) {
            if (step < _currentStep || _canContinue()) {
              setState(() => _currentStep = step);
            }
          },
          onStepContinue: () {
            if (_canContinue()) {
              if (_currentStep < steps.length - 1) {
                setState(() => _currentStep += 1);
              }
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            } else {
              context.pop();
            }
          },
          steps: steps,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (_currentStep < steps.length - 1)
                    ElevatedButton(
                      onPressed: _canContinue() ? details.onStepContinue : null,
                      child: const Text('التالي'),
                    ),
                  if (_currentStep == steps.length - 1)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _publishProduct,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('نشر'),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('السابق'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class StepDescriptionAndTitle extends StatefulWidget {
  final Function(Map<String, String>) onDataChanged;
  final String initialTitle;
  final String initialDescription;

  const StepDescriptionAndTitle({
    required this.onDataChanged,
    required this.initialTitle,
    required this.initialDescription,
  });

  @override
  State<StepDescriptionAndTitle> createState() => _StepDescriptionAndTitleState();
}

class _StepDescriptionAndTitleState extends State<StepDescriptionAndTitle> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'عنوان المنتج',
            hintText: 'أدخل عنوان جذاب',
          ),
          onChanged: (_) => _onChanged(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'وصف المنتج',
            hintText: 'صف المنتج بالتفصيل',
          ),
          maxLines: 4,
          onChanged: (_) => _onChanged(),
        ),
      ],
    );
  }

  void _onChanged() {
    widget.onDataChanged({
      'title': _titleController.text,
      'description': _descriptionController.text,
    });
  }
}
