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
      final cachePath = '${cacheDir.path}/$cacheFolder';
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
      final cachePath = '${cacheDir.path}/$cacheFolder';
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
      return '.jpg'; // Default fallback
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
        // GIF: 47 49 46
        if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
          return '.gif';
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

    return '.jpg'; // Default fallback
  }

  /// Validate image extension
  bool _isValidImageExtension(String ext) {
    const validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
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
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // ==================== UPLOAD TO SUPABASE ====================

  /// Upload single image to Supabase Storage
  Future<String> uploadImage(File imageFile, {String? customPath}) async {
    try {
      // 1. Get file metadata
      final fileName = imageFile.path.split('/').last;
      final mimeType = _getMimeType(imageFile.path);
      final fileBytes = await imageFile.readAsBytes();
      final fileSize = fileBytes.length;

      // 2. Validate file
      if (fileSize == 0) {
        throw Exception('File is empty');
      }
      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('File size exceeds 50MB limit');
      }

      // 3. Generate remote path
      final remoteFileName =
          customPath ?? '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '$bucketName/$remoteFileName';

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

  /// Upload multiple images
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    try {
      final uploadedUrls = <String>[];

      for (int i = 0; i < imageFiles.length; i++) {
        try {
          final url = await uploadImage(imageFiles[i]);
          uploadedUrls.add(url);
        } catch (e) {
          print('Failed to upload image ${i + 1}: $e');
          // Continue with next image
        }
      }

      if (uploadedUrls.isEmpty) {
        throw Exception('Failed to upload any images');
      }

      return uploadedUrls;
    } catch (e) {
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

      onProgress(0.3); // Simulated preparation progress

      final remoteFileName =
          '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}';

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
      // Extract filename from URL
      final fileName = imageUrl.split('/').last.split('?').first;
      await _client.storage.from(bucketName).remove([fileName]);
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
