import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import "../../../services/upload_service.dart";
import '../../../config/theme.dart';

class StepImages extends StatefulWidget {
  final Function(List<File>) onImagesSelected;
  final List<File> initialImages;

  const StepImages({
    required this.onImagesSelected,
    required this.initialImages,
  });

  @override
  State<StepImages> createState() => _StepImagesState();
}

class _StepImagesState extends State<StepImages> {
  late List<File> _selectedImages;
  final _uploadService = UploadService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedImages = List.from(widget.initialImages);
  }

  Future<void> _pickImages() async {
    setState(() => _isLoading = true);
    try {
      final images = await _uploadService.pickMultipleImages();
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 8) {
          _selectedImages = _selectedImages.sublist(0, 8);
        }
      });
      widget.onImagesSelected(_selectedImages);
    } catch (e) {
      _showError('فشل اختيار الصور: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromCamera() async {
    setState(() => _isLoading = true);
    try {
      final image = await _uploadService.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
          if (_selectedImages.length > 8) {
            _selectedImages = _selectedImages.sublist(0, 8);
          }
        });
        widget.onImagesSelected(_selectedImages);
      }
    } catch (e) {
      _showError('فشل التقاط الصورة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onImagesSelected(_selectedImages);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقط صورة'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أضف صور للمنتج (حد أقصى 8 صور)',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          
          // Image grid
          if (_selectedImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return _ImageThumbnail(
                  image: _selectedImages[index],
                  onRemove: () => _removeImage(index),
                  index: index + 1,
                );
              },
            ),

          if (_selectedImages.isNotEmpty) const SizedBox(height: 16),

          // Add images button
          if (_selectedImages.length < 8)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.borderLight,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showImageSourceBottomSheet,
                          icon: const Icon(Icons.image),
                          label: const Text('إضافة صور'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedImages.length} من 8 صور مضافة',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),

          if (_selectedImages.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.borderLight,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showImageSourceBottomSheet,
                          icon: const Icon(Icons.image),
                          label: const Text('إضافة صور'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'أضف صوراً واضحة وجذابة لمنتجك',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
            ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نصائح لصور جيدة:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildTip('استخدم إضاءة طبيعية جيدة'),
                _buildTip('صور المنتج من جوانب مختلفة'),
                _buildTip('تأكد من وضوح تفاصيل المنتج'),
                _buildTip('تجنب الصور الضبابية أو المظلمة'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final File image;
  final VoidCallback onRemove;
  final int index;

  const _ImageThumbnail({
    required this.image,
    required this.onRemove,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black26,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
