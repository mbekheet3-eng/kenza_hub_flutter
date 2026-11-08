import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class UploadService {
  static final UploadService _instance = UploadService._internal();
  late final SupabaseClient _client;
  final ImagePicker _imagePicker = ImagePicker();
  static const String bucketName = 'product-images';
  static const String privateProductImagesBucketName = 'restricted-product-images';
  static const String cacheFolder = 'kenza_hub_cache';
  static const int maxImages = 8;

  factory UploadService() {
    return _instance;
  }

  UploadService._internal() {
    _client = Supabase.instance.client;
  }

  // ==================== IMAGE PICKING ====================

  /// Pick multiple images from device
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxHeight: 1920,
        maxWidth: 1080,
      );

      if (pickedFiles.isEmpty) return [];

      // Limit to MAX_IMAGES
      final limitedFiles = pickedFiles.take(maxImages).toList();

      // Process files and copy to cache
      final files = <File>[];
      for (final xFile in limitedFiles) {
        final cachedFile = await _copyToCacheDirectory(File(xFile.path));
        files.add(cachedFile);
      }

      return files;
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  /// Pick single image from camera or gallery
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxHeight: 1920,
        maxWidth: 1080,
      );

      if (pickedFile == null) return null;

      final cachedFile = await _copyToCacheDirectory(File(pickedFile.path));
      return cachedFile;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Copy file to app cache directory
  Future<File> _copyToCacheDirectory(File sourceFile) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cachePath = '${cacheDir.path}/kenza_hub';
      final cacheFolder = Directory(cachePath);

      // Create folder if not exists
      if (!await cacheFolder.exists()) {
        await cacheFolder.create(recursive: true);
      }

      // Generate unique filename
      final fileName = '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}';
      final extension = _getFileExtension(sourceFile.path);
      final cachedFilePath = '${cacheFolder.path}/$fileName$extension';

      // Copy file
      final cachedFile = await sourceFile.copy(cachedFilePath);
      return cachedFile;
    } catch (e) {
      throw Exception('Failed to copy to cache: $e');
    }
  }

  /// Clean up cache directory
  Future<void> cleanupCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cachePath = '${cacheDir.path}/kenza_hub';
      final cacheFolder = Directory(cachePath);

      if (await cacheFolder.exists()) {
        await cacheFolder.delete(recursive: true);
      }
    } catch (e) {
      print('Failed to cleanup cache: $e');
    }
  }

  // ==================== FILE OPERATIONS ====================

  /// Extract file extension (with fallback logic)
  String _getFileExtension(String filePath) {
    try {
      // First try simple split
      if (filePath.contains('.')) {
        final parts = filePath.split('.');
        final ext = parts.last.toLowerCase();
        // Validate extension
        if (_isValidImageExtension(ext)) {
          return '.$ext';
        }
      }

      // Fallback: read file header to detect type
      return _detectFileExtensionFromHeader(File(filePath));
    } catch (e) {
      print('Extension detection failed: $e');
      throw const FormatException('Only JPEG, PNG and WebP images are supported');
    }
  }

  /// Detect file extension from file header (magic bytes)
  String _detectFileExtensionFromHeader(File file) {
    try {
      final bytes = file.readAsBytesSync().take(12).toList();

      if (bytes.length >= 3) {
        // JPEG: FF D8 FF
        if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
          return '.jpg';
        }
        // PNG: 89 50 4E 47
        if (bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes.length >= 4 &&
            bytes[3] == 0x47) {
          return '.png';
        }
        // WebP: RIFF ... WEBP
        if (bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes.length >= 12) {
          if (bytes[8] == 0x57 &&
              bytes[9] == 0x45 &&
              bytes[10] == 0x42 &&
              bytes[11] == 0x50) {
            return '.webp';
          }
        }
      }
    } catch (e) {
      print('Header detection failed: $e');
    }

    throw const FormatException('Only JPEG, PNG and WebP images are supported');
  }

  /// Validate image extension
  bool _isValidImageExtension(String ext) {
    const validExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    return validExtensions.contains(ext.toLowerCase());
  }

  /// Get MIME type from file
  String _getMimeType(String filePath) {
    final ext = _getFileExtension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        throw const FormatException('Unsupported image format');
    }
  }

  // ==================== UPLOAD TO SUPABASE ====================

  /// Upload single image to Supabase Storage
  Future<String> uploadImage(File imageFile, {String? customPath}) async {
    try {
      // 1. Get file metadata
      final mimeType = _getMimeType(imageFile.path);
      final fileBytes = await imageFile.readAsBytes();
      final fileSize = fileBytes.length;

      // 2. Validate file
      if (fileSize == 0) {
        throw Exception('File is empty');
      }
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('حجم الصورة يتجاوز الحد المسموح 10 ميجابايت');
      }

      // 3. Generate remote path
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw StateError('يجب تسجيل الدخول لرفع الصور');
      final generatedName =
          '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}${_getFileExtension(imageFile.path)}';
      final remoteFileName = customPath ?? 'products/$userId/$generatedName';
      final pathSegments = remoteFileName.split('/');
      if (!remoteFileName.startsWith('products/$userId/') ||
          remoteFileName.contains('\\') ||
          pathSegments.any(
            (segment) =>
                segment.isEmpty || segment == '.' || segment == '..',
          )) {
        throw StateError('مسار رفع الصورة غير مسموح لهذا الحساب');
      }

      // 4. Upload to Supabase
      await _client.storage.from(bucketName).uploadBinary(
            remoteFileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      // 5. Get public URL
      final publicUrl = _client.storage.from(bucketName).getPublicUrl(remoteFileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a product image to the V2 path expected by add_product_image.
  /// Returns the Storage object path (not a public URL).
  Future<String> uploadProductImage(
    File imageFile, {
    required String productId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('يجب تسجيل الدخول لرفع الصور');

    final fileBytes = await imageFile.readAsBytes();
    if (fileBytes.isEmpty || fileBytes.length > 10 * 1024 * 1024) {
      throw StateError('حجم الصورة غير صالح؛ الحد الأقصى 10 ميجابايت');
    }

    final mimeType = _getMimeType(imageFile.path);
    final objectPath =
        'products/$productId/$userId/${const Uuid().v4()}${_getFileExtension(imageFile.path)}';

    await _client.storage.from(privateProductImagesBucketName).uploadBinary(
          objectPath,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    return objectPath;
  }

  Future<void> deleteProductImagePath(String objectPath) async {
    final userId = _client.auth.currentUser?.id;
    final segments = objectPath.split('/');
    if (userId == null ||
        segments.length != 4 ||
        segments[0] != 'products' ||
        segments[2] != userId ||
        segments.any((part) => part.isEmpty || part == '.' || part == '..') ||
        objectPath.contains('\\\\')) {
      throw StateError('مسار حذف الصورة غير صالح لهذا الحساب');
    }
    await _client.storage.from(privateProductImagesBucketName).remove([objectPath]);
  }

  /// Upload multiple images
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final uploadedUrls = <String>[];
    try {
      for (final imageFile in imageFiles) {
        final url = await uploadImage(imageFile);
        uploadedUrls.add(url);
      }
      return uploadedUrls;
    } catch (e) {
      if (uploadedUrls.isNotEmpty) {
        await deleteImages(uploadedUrls);
      }
      throw Exception('Failed to upload images: $e');
    }
  }

  // ==================== PROGRESS TRACKING ====================

  /// Upload image with progress callback
  Future<String> uploadImageWithProgress(
    File imageFile, {
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0);

      final fileBytes = await imageFile.readAsBytes();
      final mimeType = _getMimeType(imageFile.path);
      if (fileBytes.isEmpty) throw StateError('الصورة فارغة');
      if (fileBytes.length > 10 * 1024 * 1024) {
        throw Exception('حجم الصورة يتجاوز الحد المسموح 10 ميجابايت');
      }

      onProgress(0.3); // Simulated preparation progress

      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw StateError('يجب تسجيل الدخول لرفع الصور');
      final remoteFileName =
          'products/$userId/${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}${_getFileExtension(imageFile.path)}';

      await _client.storage.from(bucketName).uploadBinary(
            remoteFileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      onProgress(0.8); // Upload progress

      final publicUrl = _client.storage.from(bucketName).getPublicUrl(remoteFileName);

      onProgress(1.0); // Complete

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // ==================== IMAGE DELETION ====================

  /// Delete image from Supabase
  Future<void> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final marker = '/storage/v1/object/public/$bucketName/';
      final markerIndex = uri.path.indexOf(marker);
      if (markerIndex < 0) {
        throw FormatException('Invalid product image URL');
      }
      final objectPath = Uri.decodeComponent(
        uri.path.substring(markerIndex + marker.length),
      );
      final userId = _client.auth.currentUser?.id;
      final pathSegments = objectPath.split('/');
      if (userId == null ||
          !objectPath.startsWith('products/$userId/') ||
          objectPath.contains('\\') ||
          pathSegments.any(
            (segment) =>
                segment.isEmpty || segment == '.' || segment == '..',
          )) {
        throw StateError('لا يمكن حذف ملف خارج مساحة صور حسابك');
      }
      await _client.storage.from(bucketName).remove([objectPath]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Delete multiple images
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        try {
          await deleteImage(url);
        } catch (e) {
          print('Failed to delete image: $e');
          // Continue with next image
        }
      }
    } catch (e) {
      throw Exception('Failed to delete images: $e');
    }
  }

  // ==================== PROFILE UPLOADS ====================

  /// Upload profile image for user
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null || currentUserId != userId) {
        throw StateError('لا يمكن رفع صورة حساب لمستخدم آخر');
      }

      final fileBytes = await imageFile.readAsBytes();
      if (fileBytes.isEmpty || fileBytes.length > 10 * 1024 * 1024) {
        throw StateError('حجم صورة الحساب غير صالح');
      }
      final extension = _getFileExtension(imageFile.path);
      final mimeType = _getMimeType(imageFile.path);
      final objectPath =
          'products/$userId/profile/${const Uuid().v4()}$extension';

      await _client.storage.from(bucketName).uploadBinary(
            objectPath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      return _client.storage.from(bucketName).getPublicUrl(objectPath);
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // ==================== VERIFICATION ====================

  /// Verify file is accessible
  Future<bool> verifyFileAccess(File file) async {
    try {
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size
  Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      return 0;
    }
  }
}
