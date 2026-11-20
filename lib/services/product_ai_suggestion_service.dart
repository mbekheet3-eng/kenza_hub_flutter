import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';

class ProductAiSuggestionService {
  ProductAiSuggestionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const int _maxImageBytes = 4 * 1024 * 1024;

  Future<Map<String, dynamic>> suggest({
    required List<File> images,
    required List<Category> categories,
    required String title,
    required String description,
    required String languageCode,
  }) async {
    if (images.isEmpty) {
      throw Exception('Add a product photo before requesting AI suggestions.');
    }
    if (categories.isEmpty) {
      throw Exception('Product categories are not available yet.');
    }

    final imagePayload = <Map<String, String>>[];
    var totalBytes = 0;

    for (final image in images.take(3)) {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) continue;
      if (bytes.length > _maxImageBytes) {
        if (imagePayload.isEmpty) {
          throw Exception('The main photo is too large for AI analysis. Please use a smaller photo.');
        }
        break;
      }
      if (totalBytes + bytes.length > _maxImageBytes) break;

      final extension = image.path.toLowerCase().split('.').last;
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => null,
      };
      if (mimeType == null) continue;

      imagePayload.add({
        'mime_type': mimeType,
        'data': base64Encode(bytes),
      });
      totalBytes += bytes.length;
    }

    if (imagePayload.isEmpty) {
      throw Exception('No supported product photo could be read.');
    }

    final categoryPayload = categories.map((category) => {
      'id': category.id,
      'parent_id': category.parentId,
      'name_ar': category.nameAr,
      'name_en': category.nameEn,
      'name_fr': category.nameFr,
      'slug': category.slug,
    }).toList();

    final response = await _client.functions.invoke(
      'suggest-product-details',
      body: {
        'images': imagePayload,
        'categories': categoryPayload,
        'title': title.trim(),
        'description': description.trim(),
        'language': ['ar', 'en', 'fr'].contains(languageCode)
            ? languageCode
            : 'ar',
      },
    );

    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : 'AI suggestions are temporarily unavailable. Please try again.';
      throw Exception(message);
    }
    if (data is! Map) {
      throw Exception('The AI suggestion response was invalid.');
    }

    return Map<String, dynamic>.from(data);
  }
}
