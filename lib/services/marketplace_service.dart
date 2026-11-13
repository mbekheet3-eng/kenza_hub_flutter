import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_locale.dart';
import '../data/category_labels.dart';
import '../l10n/app_strings.dart';
import '../models/category.dart';
import '../models/product.dart';

class ImageSearchUnavailableException implements Exception {
  const ImageSearchUnavailableException();

  @override
  String toString() => 'Image search temporarily unavailable';
}

class MarketplaceSearchPage {
  const MarketplaceSearchPage({
    required this.products,
    required this.totalCount,
    required this.hasMore,
  });

  final List<Product> products;
  final int totalCount;
  final bool hasMore;
}

class _ProductImageReviewException implements Exception {
  const _ProductImageReviewException(this.message, {required this.retryable});

  final String message;
  final bool retryable;

  @override
  String toString() => message;
}

class MarketplaceService {
  MarketplaceService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AppStrings> _localizedStrings() =>
      AppStrings.delegate.load(AppLocale.notifier.value);
  Future<List<Category>>? _categoriesCache;
  static const String bucket = 'product-images';
  static const int maxImageBytes = 10 * 1024 * 1024;
  static const int maxImages = 8;

  Future<String?> getMyGender() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client
        .from('profiles')
        .select('gender')
        .eq('id', user.id)
        .maybeSingle();
    return row?['gender'] as String?;
  }

  Future<Map<String, dynamic>?> getPublicMemberProfile(String memberId) async {
    return _client
        .from('member_public_profiles')
        .select('first_name,avatar_url')
        .eq('id', memberId)
        .maybeSingle();
  }

  Future<List<Category>> getCategories() async {
    final cached = _categoriesCache;
    if (cached != null) return cached;

    final request = _loadCategories();
    _categoriesCache = request;
    try {
      return await request;
    } catch (_) {
      _categoriesCache = null;
      rethrow;
    }
  }

  Future<List<Category>> _loadCategories() async {
    final rows = await _client
        .from('categories')
        .select('id,parent_id,name_ar,name_en,name_fr,slug,sort_order')
        .eq('is_active', true)
        .order('sort_order');
    return rows.map((row) => Category.fromMap(row)).toList();
  }

  Set<String> _categoryScopeIds(
    List<Category> categories,
    Set<String> selectedIds,
  ) {
    final result = <String>{};
    final pending = selectedIds.toList();
    while (pending.isNotEmpty) {
      final currentId = pending.removeLast();
      if (!result.add(currentId)) continue;
      for (final child in categories.where((item) => item.parentId == currentId)) {
        pending.add(child.id);
      }
    }
    return result;
  }

  Future<List<Product>> getPublishedProducts({
    String? categoryId,
    String? query,
    int limit = 40,
  }) async {
    var request = _client
        .from('products')
        .select(
          'id,owner_id,category_id,title,description,custom_category_name,price,currency,audience,created_at,product_images(id,storage_path,sort_order)',
        )
        .eq('status', 'published');

    final categories = await getCategories();
    final searchSlugs = CategoryLabels.searchSlugs(query);
    final searchCategoryIds = categories
        .where((item) => searchSlugs.contains(item.slug))
        .map((item) => item.id)
        .toSet();

    Set<String>? categoryScope;
    if (categoryId != null && categoryId.isNotEmpty) {
      categoryScope = _categoryScopeIds(categories, {categoryId});
    }
    if (searchCategoryIds.isNotEmpty) {
      final intentScope = _categoryScopeIds(categories, searchCategoryIds);
      categoryScope = categoryScope == null
          ? intentScope
          : categoryScope.intersection(intentScope);
    }

    if (categoryScope != null) {
      if (categoryScope.isEmpty) return [];
      request = request.inFilter('category_id', categoryScope.toList());
    }

    final normalizedQuery = query?.trim() ?? '';
    final isCategoryIntent = searchSlugs.isNotEmpty;
    if (normalizedQuery.isNotEmpty && !isCategoryIntent) {
      request = request.ilike('title', '%$normalizedQuery%');
    }

    final rows = await request.order('created_at', ascending: false).limit(limit);
    return Future.wait(rows.map(_mapProduct));
  }

  Future<MarketplaceSearchPage> searchProducts({
    String query = '',
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String sort = 'relevance',
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.rpc(
      'search_products',
      params: {
        'search_query': query,
        'p_category_id': categoryId,
        'p_min_price': minPrice,
        'p_max_price': maxPrice,
        'p_sort': sort,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (response is! Map) {
      throw Exception('Invalid search response');
    }
    final payload = Map<String, dynamic>.from(response);
    final itemRows = (payload['items'] as List<dynamic>? ?? []);
    final ids = itemRows
        .whereType<Map>()
        .map((item) => item['id'])
        .whereType<String>()
        .toList();

    final loadedProducts = await getProductsByIds(ids);
    final byId = {for (final product in loadedProducts) product.id: product};
    final orderedProducts = ids
        .map((id) => byId[id])
        .whereType<Product>()
        .toList();

    return MarketplaceSearchPage(
      products: orderedProducts,
      totalCount: (payload['total_count'] as num?)?.toInt() ??
          orderedProducts.length,
      hasMore: payload['has_more'] == true,
    );
  }

  Future<String> analyzeImageForSearch(XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxImageBytes) {
      throw Exception('Image must be smaller than 10 MB');
    }

    final extension = image.name.toLowerCase().split('.').last;
    final mimeType = extension == 'png'
        ? 'image/png'
        : extension == 'webp'
            ? 'image/webp'
            : (extension == 'jpg' || extension == 'jpeg')
                ? 'image/jpeg'
                : null;
    if (mimeType == null) {
      throw Exception('Only JPEG, PNG, and WebP images are supported');
    }

    final response = await _client.functions.invoke(
      'visual-product-search',
      body: {
        'image_base64': base64Encode(bytes),
        'mime_type': mimeType,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      if (data is Map && data['error_code'] == 'temporary_unavailable') {
        throw const ImageSearchUnavailableException();
      }
      throw Exception('Image analysis failed');
    }

    final data = response.data;
    if (data is! Map) throw Exception('Invalid image analysis response');
    final terms = (data['terms'] as List<dynamic>? ?? [])
        .whereType<String>()
        .map((term) => term.trim())
        .where((term) => term.length >= 2)
        .toSet()
        .take(10)
        .toList();
    if (terms.isEmpty) {
      throw Exception('No product could be identified in this image');
    }
    return terms.join(' ');
  }

  Future<List<Product>> getMyProducts() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('products')
        .select(
          'id,owner_id,category_id,title,description,custom_category_name,price,currency,audience,created_at,product_images(id,storage_path,sort_order)',
        )
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);

    return Future.wait(rows.map(_mapProduct));
  }

  Future<List<Product>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final rows = await _client
        .from('products')
        .select(
          'id,owner_id,category_id,title,description,custom_category_name,price,currency,audience,created_at,product_images(id,storage_path,sort_order)',
        )
        .inFilter('id', productIds)
        .eq('status', 'published')
        .order('created_at', ascending: false);

    return Future.wait(rows.map(_mapProduct));
  }

  Future<Product> getProduct(String productId) async {
    final row = await _client
        .from('products')
        .select(
          'id,owner_id,category_id,title,description,custom_category_name,price,currency,audience,created_at,product_images(id,storage_path,sort_order)',
        )
        .eq('id', productId)
        .single();
    return _mapProduct(row);
  }

  Future<Product> _mapProduct(Map<String, dynamic> row) async {
    final imageRows = (row['product_images'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
      ..sort(
        (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int),
      );

    final paths = imageRows
        .map((image) => image['storage_path'] as String)
        .toList();

    final signedUrls = await Future.wait(
      paths.map((path) => _client.storage.from(bucket).createSignedUrl(path, 3600)),
    );

    return Product.fromMap(
      row,
      signedImageUrls: signedUrls,
      paths: paths,
    );
  }

  Future<String> publishProduct({
    required String categoryId,
    required String title,
    required String description,
    required double price,
    required List<File> images,
    required String audience,
    String? customCategoryName,
  }) async {
    final strings = await _localizedStrings();
    final user = _client.auth.currentUser;
    if (user == null) throw Exception(strings.loginRequired);
    if (images.isEmpty || images.length > maxImages) {
      throw Exception(strings.selectAtLeastOnePhoto);
    }
    if (title.trim().isEmpty || price <= 0) {
      throw Exception(strings.productTitleAndPriceRequired);
    }

    final created = await _client
        .from('products')
        .insert({
          'owner_id': user.id,
          'category_id': categoryId,
          'title': title.trim(),
          'description': description.trim(),
          'custom_category_name': customCategoryName?.trim().isEmpty == true ? null : customCategoryName?.trim(),
          'price': price,
          'currency': 'EGP',
          'status': 'draft',
          'audience': audience,
        })
        .select('id')
        .single();

    final productId = created['id'] as String;
    final uploadedPaths = <String>[];
    var preserveDraft = false;

    try {
      final imageRows = <Map<String, dynamic>>[];

      for (var index = 0; index < images.length; index++) {
        final file = images[index];
        final bytes = await file.readAsBytes();
        if (bytes.length > maxImageBytes) {
          throw Exception(strings.imageTooLarge);
        }

        final extension = file.path.split('.').last.toLowerCase();
        final contentType = switch (extension) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => throw Exception(strings.unsupportedImageFormat),
        };

        final path =
            '${user.id}/$productId/${DateTime.now().microsecondsSinceEpoch}_$index.$extension';

        await _client.storage.from(bucket).uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: contentType,
                upsert: false,
              ),
            );
        uploadedPaths.add(path);

        imageRows.add({
          'product_id': productId,
          'storage_path': path,
          'sort_order': index,
        });
      }

      await _client.from('product_images').insert(imageRows);

      try {
        await _reviewProductImages(productId);
      } on _ProductImageReviewException {
        // Keep rejected and review-required products, including their uploaded images,
        // so the owner can edit the listing and submit it for review again.
        preserveDraft = true;
        rethrow;
      }

      return productId;
    } catch (_) {
      if (!preserveDraft && uploadedPaths.isNotEmpty) {
        try {
          await _client.storage.from(bucket).remove(uploadedPaths);
        } catch (_) {
          // Keep the original publishing error; orphan cleanup can be retried.
        }
      }
      if (!preserveDraft) {
        try {
          await _client.from('products').delete().eq('id', productId);
        } catch (_) {
          // Keep the original publishing error.
        }
      }
      rethrow;
    }
  }

  Future<void> _reviewProductImages(String productId) async {
    final strings = await _localizedStrings();
    try {
      final response = await _client.functions.invoke(
        'review-product-images',
        body: {'product_id': productId},
      );
      final data = response.data;
      if (data is! Map) {
        throw _ProductImageReviewException(
          strings.imageReviewReadError,
          retryable: true,
        );
      }

      if (data['status'] == 'approved') return;

      final message = data['status'] == 'rejected'
          ? strings.imageReviewRejected
          : strings.imageReviewUnavailable;
      throw _ProductImageReviewException(
        message,
        retryable: data['status'] != 'rejected',
      );
    } on _ProductImageReviewException {
      rethrow;
    } catch (_) {
      throw _ProductImageReviewException(
        strings.imageReviewUnavailable,
        retryable: true,
      );
    }
  }

  Future<void> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String categoryId,
    required String audience,
    String? customCategoryName,
  }) async {
    final strings = await _localizedStrings();
    final user = _client.auth.currentUser;
    if (user == null) throw Exception(strings.loginRequired);

    final previous = await _client
        .from('products')
        .select('title,description,category_id,status')
        .eq('id', productId)
        .eq('owner_id', user.id)
        .maybeSingle();

    if (previous == null) {
      throw Exception(strings.productNotFoundOrNoEditPermission);
    }

    final needsImageReview = previous['status'] == 'draft' ||
        previous['title'] != title.trim() ||
        (previous['description'] ?? '') != description.trim() ||
        previous['category_id'] != categoryId;

    final rows = await _client
        .from('products')
        .update({
          'title': title.trim(),
          'description': description.trim(),
          'price': price,
          'category_id': categoryId,
          'custom_category_name': customCategoryName?.trim().isEmpty == true ? null : customCategoryName?.trim(),
          'audience': audience,
        })
        .eq('id', productId)
        .eq('owner_id', user.id)
        .select('id');

    if (rows.isEmpty) {
      throw Exception(strings.productNotFoundOrNoEditPermission);
    }

    if (needsImageReview) {
      await _reviewProductImages(productId);
    }
  }

  Future<void> deleteProduct(String productId) async {
    final strings = await _localizedStrings();
    final user = _client.auth.currentUser;
    if (user == null) throw Exception(strings.loginRequired);

    final ownedProduct = await _client
        .from('products')
        .select('id')
        .eq('id', productId)
        .eq('owner_id', user.id)
        .maybeSingle();

    if (ownedProduct == null) {
      throw Exception(strings.productNotFoundOrNoDeletePermission);
    }

    final rows = await _client
        .from('product_images')
        .select('storage_path')
        .eq('product_id', productId);

    final paths = rows.map((row) => row['storage_path'] as String).toList();
    if (paths.isNotEmpty) {
      await _client.storage.from(bucket).remove(paths);
    }

    final deleted = await _client
        .from('products')
        .delete()
        .eq('id', productId)
        .eq('owner_id', user.id)
        .select('id');

    if (deleted.isEmpty) throw Exception(strings.productDeleteFailed);
  }
}
