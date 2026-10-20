import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
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
  bool _isLoadingProfile = true;
  String? _errorMessage;
  User? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Load the actual user profile from database
      final user = await SupabaseService().getUser(userId);

      setState(() {
        _currentUserProfile = user;
        _nameController.text = user.displayName ?? '';
        _bioController.text = user.bio ?? '';
        _locationController.text = user.location ?? '';
        _phoneController.text = user.phone ?? '';
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل تحميل الملف الشخصي: $e';
        _isLoadingProfile = false;
      });
    }
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
    if (_currentUserProfile == null) {
      _showError('بيانات المستخدم غير متاحة');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? newAvatarUrl = _currentUserProfile!.avatarUrl;

      // Upload new avatar if selected
      if (_selectedImage != null) {
        final uploadService = UploadService();
        newAvatarUrl = await uploadService.uploadProfileImage(
          _selectedImage!,
          _currentUserProfile!.id,
        );
      }

      // Create updated user object with new values
      final updatedUser = _currentUserProfile!.copyWith(
        displayName: _nameController.text,
        bio: _bioController.text,
        location: _locationController.text,
        phone: _phoneController.text,
        avatarUrl: newAvatarUrl,
      );

      // Update using SupabaseService
      await SupabaseService().updateProfile(updatedUser);

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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تحرير الملف الشخصي'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحرير الملف الشخصي'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFC85A32),
                          width: 3,
                        ),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : (_currentUserProfile?.avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        _currentUserProfile!.avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                        color: Colors.grey[300],
                      ),
                      child: _selectedImage == null &&
                              _currentUserProfile?.avatarUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('غيّر الصورة'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Section
            _buildFormField(
              label: 'الاسم',
              controller: _nameController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'السيرة الذاتية',
              controller: _bioController,
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'الموقع',
              controller: _locationController,
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              label: 'رقم الهاتف',
              controller: _phoneController,
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 32),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC85A32),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
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
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFC85A32),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
