import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/upload_service.dart';
import '../../config/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;

  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      _showError('فشل اختيار الصورة: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('لم يتم العثور على المستخدم');
      }

      String? newAvatarUrl = currentUser.avatarUrl;

      // Upload new avatar if selected
      if (_selectedImage != null) {
        final uploadService = UploadService();
        newAvatarUrl = await uploadService.uploadProfileImage(
          _selectedImage!,
          currentUser.id,
        );
      }

      // Update user in database
      final updatedUser = currentUser.copyWith(
        displayName: _nameController.text,
        bio: _bioController.text,
        location: _locationController.text,
        phone: _phoneController.text,
        avatarUrl: newAvatarUrl,
        updatedAt: DateTime.now(),
      );

      await authProvider.updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الملف الشخصي بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError('فشل حفظ الملف الشخصي: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Avatar Section
              _buildAvatarSection(user),
              const SizedBox(height: 32),

              // Form Fields
              _buildNameField(),
              const SizedBox(height: 16),

              _buildBioField(),
              const SizedBox(height: 16),

              _buildLocationField(),
              const SizedBox(height: 16),

              _buildPhoneField(),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'حفظ التغييرات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(User user) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                child: _selectedImage == null && user.avatarUrl == null
                    ? Icon(Icons.person, size: 60, color: AppTheme.primaryColor)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'اضغط لتغيير الصورة',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'الاسم الكامل',
        hintText: 'أدخل اسمك الكامل',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      enabled: !_isLoading,
    );
  }

  Widget _buildBioField() {
    return TextField(
      controller: _bioController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'نبذة عني',
        hintText: 'اكتب نبذة قصيرة عن نفسك',
        prefixIcon: const Icon(Icons.info),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      enabled: !_isLoading,
    );
  }

  Widget _buildLocationField() {
    return TextField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'المدينة / المنطقة',
        hintText: 'أين تقع؟',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      enabled: !_isLoading,
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'رقم الهاتف',
        hintText: '+20xxxxxxxxx',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      keyboardType: TextInputType.phone,
      enabled: !_isLoading,
    );
  }
}
