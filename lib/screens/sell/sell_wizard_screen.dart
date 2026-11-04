import 'dart:io';
import 'package:flutter/material.dart';
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
  bool _skipVariantFields = false;
  bool _isResolvingCategoryRules = false;
  bool _categoryRulesResolved = false;
  int _categoryRulesRequestId = 0;

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
        _skipVariantFields = rootSlug == 'kids' || rootSlug == 'home';
        _categoryRulesResolved = true;
        _isResolvingCategoryRules = false;
      });
    } catch (_) {
      if (mounted && requestId == _categoryRulesRequestId) {
        setState(() {
          _categoryRulesResolved = false;
          _isResolvingCategoryRules = false;
        });
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
        return _categoryRulesResolved &&
            !_isResolvingCategoryRules &&
            _condition != null;
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
      _showError('يرجى ملء البيانات المطلوبة وإضافة صورة واحدة على الأقل');
      return;
    }

    setState(() => _isLoading = true);
    final uploadedImagePaths = <String>[];
    String? createdProductId;
    var retryAfterPhoneVerification = false;

    try {
      final sellerProfileId = await _productService.ensureSellerProfile();

      // The V2 RPC creates the listing as pending_review and enforces
      // verified-phone, seller permission, service coverage and weight rules.
      createdProductId = await _productService.createProduct(
        sellerProfileId: sellerProfileId,
        categorySlug: _category!,
        title: _title,
        description: _description,
        price: _price,
        conditionLabel: _condition!,
        colorLabel: _skipVariantFields ? null : _color,
        sizeLabel: _skipVariantFields ? null : _size,
        brandName: _brand,
      );

      // V2 image paths must be scoped to product UUID + authenticated user.
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

        // Run server-side AI moderation when its provider key is configured.
        // A provider outage leaves the listing pending review; it never marks
        // an unreviewed image as approved.
        try {
          final moderation = await Supabase.instance.client.functions.invoke(
            'moderate-product-image',
            body: {'image_id': imageId},
          );
          if (moderation.status < 200 || moderation.status >= 300) {
            debugPrint('Image moderation remains pending: ${moderation.status}');
          }
        } catch (moderationError) {
          debugPrint('Image moderation remains pending: $moderationError');
        }
      }

      try {
        await _uploadService.cleanupCache();
      } catch (_) {
        // Cache cleanup is non-critical after a successful submission.
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال المنتج للمراجعة بنجاح')),
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

      final errorText = e.toString();
      if (errorText.contains('PHONE_VERIFICATION_REQUIRED')) {
        retryAfterPhoneVerification = await _showPhoneVerificationDialog();
      } else if (errorText.contains('OUTSIDE_DELIVERY_COVERAGE')) {
        _showError('منطقتك خارج نطاق التوصيل الداخلي الحالي؛ يمكنك التصفح فقط.');
      } else {
        _showError('فشل إرسال المنتج للمراجعة: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (retryAfterPhoneVerification && mounted) {
      await _publishProduct();
    }
  }

  String _normalizeEgyptianPhone(String input) {
    final compact = input.replaceAll(RegExp(r'[\s()-]'), '');
    if (compact.startsWith('+')) return compact;
    if (compact.startsWith('00')) return '+${compact.substring(2)}';
    if (compact.startsWith('0')) return '+20${compact.substring(1)}';
    if (compact.startsWith('20')) return '+$compact';
    return '+20$compact';
  }

  Future<bool> _showPhoneVerificationDialog() async {
    final client = Supabase.instance.client;
    final phoneController = TextEditingController(
      text: client.auth.currentUser?.phone ?? '',
    );
    final otpController = TextEditingController();
    var otpSent = false;
    var busy = false;
    String? dialogError;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('توثيق رقم الهاتف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'نطلب توثيق الهاتف مرة واحدة فقط قبل أول عملية بيع أو شراء.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '01xxxxxxxxx',
                  ),
                ),
                if (otpSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'رمز SMS',
                      hintText: 'أدخل الرمز المكوّن من 6 أرقام',
                    ),
                  ),
                ],
                if (dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    dialogError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() {
                        busy = true;
                        dialogError = null;
                      });
                      try {
                        final phone =
                            _normalizeEgyptianPhone(phoneController.text.trim());
                        if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
    return _selectedImages.isNotEmpty &&
        _category != null &&
        _condition != null &&
        _categoryRulesResolved &&
        !_isResolvingCategoryRules &&
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
).hasMatch(phone)) {
                          throw const FormatException(
                            'أدخل رقم هاتف صحيحًا مع كود الدولة.',
                          );
                        }

                        if (!otpSent) {
                          await client.auth.updateUser(
                            UserAttributes(phone: phone),
                          );
                          setDialogState(() {
                            otpSent = true;
                            dialogError = 'تم إرسال الرمز. أدخل رمز SMS للتحقق.';
                          });
                        } else {
                          await client.auth.verifyOTP(
                            phone: phone,
                            token: otpController.text.trim(),
                            type: OtpType.phoneChange,
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            dialogError = error is FormatException
                                ? error.message
                                : 'تعذر إتمام التوثيق: $error';
                          });
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => busy = false);
                        }
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(otpSent ? 'تحقق من الرمز' : 'إرسال الرمز'),
            ),
          ],
        ),
      ),
    );

    phoneController.dispose();
    otpController.dispose();
    return verified ?? false;
  }

  bool _validateAllData() {
    return _selectedImages.isNotEmpty &&
        _category != null &&
        _condition != null &&
        _categoryRulesResolved &&
        !_isResolvingCategoryRules &&
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
