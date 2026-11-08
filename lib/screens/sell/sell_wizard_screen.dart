import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  double? _weightKg;
  bool _skipVariantFields = false;
  bool _isResolvingCategoryRules = false;
  bool _categoryRulesResolved = false;
  int _categoryRulesRequestId = 0;

  final _productService = MarketplaceProductService();
  final _catalogService = CatalogService();
  final _uploadService = UploadService();

  late List<Step> steps;

  void _initializeSteps() {
    steps = [
      Step(
        title: Text(AppLocalizations.of(context).photos),
        content: StepImages(
          onImagesSelected: _onImagesSelected,
          initialImages: _selectedImages,
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text(AppLocalizations.of(context).productInfo),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepCategory(
              onCategorySelected: _onCategorySelected,
              selectedCategory: _category,
            ),
            const SizedBox(height: 20),
            if (_isResolvingCategoryRules)
              const Center(child: CircularProgressIndicator())
            else if (_categoryRulesResolved) ...[
              StepDetails(
                onDataChanged: _onDetailsChanged,
                category: _category,
                initialCondition: _condition,
                initialColor: _color,
                initialSize: _size,
                skipVariantFields: _skipVariantFields,
              ),
              if (!_skipVariantFields)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context).optionalDetails),
                  subtitle: Text(AppLocalizations.of(context).colorSizeBrand),
                  children: [
                    StepBrand(
                      onBrandSelected: _onBrandSelected,
                      selectedBrand: _brand,
                      category: _category,
                      skipVariantFields: _skipVariantFields,
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              StepDescriptionAndTitle(
                onDataChanged: _onDescriptionChanged,
                initialTitle: _title,
                initialDescription: _description,
              ),
            ] else
              Text(AppLocalizations.of(context).chooseCategoryFirst),
            if (_category != null) ...[
              const SizedBox(height: 20),
              StepPrice(
                onPriceChanged: _onPriceChanged,
                initialPrice: _price,
              ),
            ],
          ],
        ),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: Text(AppLocalizations.of(context).reviewAndPublish),
        content: _buildReviewStep(),
        isActive: _currentStep >= 2,
      ),
    ];
  }

  void _onImagesSelected(List<File> images) {
    setState(() {
      _selectedImages = images;
    });
  }

  Future<void> _onCategorySelected(String? category) async {
    final requestId = ++_categoryRulesRequestId;
    setState(() {
      _category = category;
      _skipVariantFields = false;
      _categoryRulesResolved = false;
      _isResolvingCategoryRules = category != null;
      // A category change invalidates previously selected lookup values.
      _brand = null;
      _color = null;
      _size = null;
    });

    if (category == null) return;
    try {
      final rootSlug = await _catalogService.fetchRootCategorySlug(category);
      if (!mounted || requestId != _categoryRulesRequestId) return;
      if (rootSlug == null) {
        throw StateError('Category root could not be resolved');
      }
      if (!mounted || requestId != _categoryRulesRequestId) return;
      setState(() {
        _skipVariantFields = rootSlug == 'kids-supplies' || rootSlug == 'home-supplies';
        _categoryRulesResolved = true;
        _isResolvingCategoryRules = false;
      });
    } catch (_) {
      if (mounted && requestId == _categoryRulesRequestId) {
        setState(() {
          _categoryRulesResolved = false;
          _isResolvingCategoryRules = false;
        });
        _showError(AppLocalizations.of(context).categoryRulesError);
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
        return _category != null &&
            _categoryRulesResolved &&
            !_isResolvingCategoryRules &&
            _condition != null &&
            _title.trim().isNotEmpty &&
            _price > 0;
      case 2:
        return true;
      default:
        return false;
    }
  }

  Future<void> _publishProduct() async {
    if (!_validateAllData()) {
      _showError(AppLocalizations.of(context).completeRequiredFields);
      return;
    }

    setState(() => _isLoading = true);
    final uploadedImagePaths = <String>[];
    String? createdProductId;
    var allModerationRequestsSucceeded = true;

    try {
      final sellerProfileId = await _productService.ensureSellerProfile();

      // The V2 RPC creates the listing as pending_review and enforces
      // seller permission, valid catalog data and weight rules. Phone
      // verification and Kenza delivery-zone selection are currently optional.
      createdProductId = await _productService.createProduct(
        sellerProfileId: sellerProfileId,
        categorySlug: _category!,
        title: _title,
        description: _description,
        price: _price,
        weightKg: _weightKg,
        conditionLabel: _condition!,
        colorLabel: _skipVariantFields ? null : _color,
        sizeLabel: _skipVariantFields ? null : _size,
        brandName: _brand,
      );

      // Upload and register every image before starting AI moderation.
      // This prevents the first approved image from publishing a product
      // before the remaining images have even been registered.
      final imageIds = <String>[];
      for (var index = 0; index < _selectedImages.length; index++) {
        final imagePath = await _uploadService.uploadProductImage(
          _selectedImages[index],
          productId: createdProductId,
        );
        uploadedImagePaths.add(imagePath);
        final imageId = await _productService.addProductImage(
          productId: createdProductId,
          imagePath: imagePath,
          displayOrder: index,
        );
        imageIds.add(imageId);
      }

      // Ask Gemini to review each registered image.
      for (final imageId in imageIds) {
        try {
          final moderation = await Supabase.instance.client.functions.invoke(
            'moderate-product-image',
            body: {'image_id': imageId},
          );
          if (moderation.status < 200 || moderation.status >= 300) {
            allModerationRequestsSucceeded = false;
            debugPrint('Gemini moderation failed: ${moderation.status} ${moderation.data}');
          }
        } catch (moderationError) {
          allModerationRequestsSucceeded = false;
          debugPrint('Gemini moderation request failed: $moderationError');
        }
      }

      if (!allModerationRequestsSucceeded) {
        debugPrint('Product remains pending until Gemini moderation succeeds.');
      }

      try {
        await _uploadService.cleanupCache();
      } catch (_) {
        // Cache cleanup is non-critical after a successful submission.
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allModerationRequestsSucceeded
                  ? AppLocalizations.of(context).geminiSubmitted
                  : AppLocalizations.of(context).geminiPending,
            ),
          ),
        );
        context.pushReplacement('/home');
      }
    } catch (e) {
      if (createdProductId != null) {
        try {
          await _productService.archiveProduct(createdProductId);
        } catch (_) {
          // Preserve the original error if cleanup is blocked.
        }
      }
      for (final imagePath in uploadedImagePaths) {
        try {
          await _uploadService.deleteProductImagePath(imagePath);
        } catch (_) {
          // Continue cleaning remaining uploaded objects.
        }
      }

      _showError('${AppLocalizations.of(context).moderationSubmitError}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }



  bool _validateAllData() {
    return _selectedImages.isNotEmpty &&
        _category != null &&
        _condition != null &&
        _categoryRulesResolved &&
        !_isResolvingCategoryRules &&
        _title.trim().isNotEmpty &&
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
          _buildReviewSection(AppLocalizations.of(context).photos, _buildImagePreview()),
          _buildReviewSection(AppLocalizations.of(context).categoryLabel, Text(_category ?? '-')),
          _buildReviewSection(AppLocalizations.of(context).conditionLabel, Text(_condition ?? '-')),
          if (!_skipVariantFields && _color != null)
            _buildReviewSection(AppLocalizations.of(context).colorLabel, Text(_color!)),
          if (!_skipVariantFields && _size != null)
            _buildReviewSection(AppLocalizations.of(context).sizeLabel, Text(_size!)),
          if (_brand != null)
            _buildReviewSection(AppLocalizations.of(context).brandLabel, Text(_brand!)),
          _buildReviewSection(AppLocalizations.of(context).addressLabel, Text(_title)),
          if (_description.trim().isNotEmpty)
            _buildReviewSection(AppLocalizations.of(context).description, Text(_description)),
          _buildReviewSection(AppLocalizations.of(context).priceLabel, Text('$_price ${AppLocalizations.of(context).currency}', 
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
                  : Text(AppLocalizations.of(context).publishProduct),
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
        appBar: AppBar(title: Text(AppLocalizations.of(context).sellProduct)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).loginToSell,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  child: Text(AppLocalizations.of(context).login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).sellProduct),
        elevation: 0,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme,
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) {
            if (step <= _currentStep ||
                (step == _currentStep + 1 && _canContinue())) {
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
                      child: Text(AppLocalizations.of(context).next),
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
                          : Text(AppLocalizations.of(context).publish),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: Text(AppLocalizations.of(context).previous),
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
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).productTitleLabel,
            hintText: AppLocalizations.of(context).catchyTitleHint,
          ),
          onChanged: (_) => _onChanged(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).optionalProductDescription,
            hintText: AppLocalizations.of(context).optionalDescriptionHint,
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
