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

class _CachedSignedImageUrl {
  const _CachedSignedImageUrl(this.url, this.expiresAt);

  final String url;
  final DateTime expiresAt;
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

  Future<Map<String, dynamic>> getSellerPublicDetails(String sellerId) async {
    final results = await Future.wait<dynamic>([
      _client.from('seller_public_locations')
          .select('governorate,city,area')
          .eq('seller_id', sellerId)
          .maybeSingle(),
      _client.from('seller_review_summaries')
          .select('average_rating,review_count')
          .eq('seller_id', sellerId)
          .maybeSingle(),
      _client.from('seller_public_reviews')
          .select('id,rating,comment,created_at')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false)
          .limit(20),
      _client.from('seller_public_badges')
          .select('badge_type,verified_at')
          .eq('seller_id', sellerId),
    ]);
    return {
      'location': results[0] as Map<String, dynamic>?,
      'summary': results[1] as Map<String, dynamic>?,
      'reviews': (results[2] as List).cast<Map<String, dynamic>>(),
      'badges': (results[3] as List).cast<Map<String, dynamic>>(),
    };
  }

  Future<void> saveSellerPublicLocation({
    required String governorate,
    required String city,
    String? area,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Authentication required');
    await _client.from('seller_public_locations').upsert({
      'seller_id': userId,
      'governorate': governorate.trim(),
      'city': city.trim(),
      'area': area?.trim().isEmpty == true ? null : area?.trim(),
    }, onConflict: 'seller_id');
  }

  Future<void> removeSellerPublicLocation() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Authentication required');
    await _client.from('seller_public_locations').delete().eq('seller_id', userId);
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
    int offset = 0,
  }) async {
    var request = _client
        .from('products')
        .select(
          'id,owner_id,category_id,title,description,custom_category_name,price,currency,audience,status,created_at,product_images(id,storage_path,sort_order)',
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

    final safeLimit = limit.clamp(1, 100).toInt();
    final safeOffset = offset < 0 ? 0 : offset;
    final rows = await request
        .order('created_at', ascending: false)
        .order('id', ascending: true)
        .range(safeOffset, safeOffset + safeLimit - 1);
    return _mapProducts(rows);
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

    late final dynamic response;
    try {
      response = await _client.functions.invoke(
        'visual-product-search',
        body: {
          'image_base64': base64Encode(bytes),
          'mime_type': mimeType,
        },
      );
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error_code'] == 'temporary_unavailable') {
        throw const ImageSearchUnavailableException();
      }
      rethrow;
    }
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
          'id,owner_id,category_id,title,description,custom_category_name,price,currency,audience,status,created_at,product_images(id,storage_path,sort_order)',
        )
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);

    return _mapProducts(rows);
  }

  Future<List<Map<String, dynamic>>> getActiveStoresByType(String storeType) async {
    const legacyTypes = {
      'wekala_markets': 'wekala_corner',
      'social_stores': 'online_store',
      'kenza_stock': 'individual_seller',
      'local_brands': 'physical_shop',
    };
    const supportedTypes = {
      'wekala_markets',
      'social_stores',
      'kenza_stock',
      'local_brands',
    };
    if (!supportedTypes.contains(storeType)) {
      throw ArgumentError.value(storeType, 'storeType');
    }
    final rows = await _client
        .from('stores')
        .select('id,owner_id,store_name,store_type,description,logo_url,banner_url,created_at')
        .inFilter('store_type', [storeType, legacyTypes[storeType]!])
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<Product>> getPublishedProductsBySeller(
    String sellerId, {
    int limit = 40,
  }) async {
    final rows = await _client
        .from('products')
        .select(
          'id,owner_id,category_id,title,description,custom_category_name,price,currency,audience,created_at,product_images(id,storage_path,sort_order)',
        )
        .eq('owner_id', sellerId)
        .eq('status', 'published')
        .order('created_at', ascending: false)
        .limit(limit);

    return _mapProducts(rows);
  }

  Future<int> getPublishedProductCountBySeller(String sellerId) async {
    final response = await _client
        .from('products')
        .select('id')
        .eq('owner_id', sellerId)
        .eq('status', 'published')
        .count(CountOption.exact);
    return response.count;
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

    return _mapProducts(rows);
  }

  Future<Product> getProduct(String productId) async {
    final row = await _client
        .from('products')
        .select(
          'id,owner_id,category_id,title,description,custom_category_name,price,currency,audience,created_at,product_images(id,storage_path,sort_order)',
        )
        .eq('id', productId)
        .single();
    return (await _mapProducts([row], includeAllImages: true)).single;
  }

  static const int _signedImageUrlLifetimeSeconds = 3600;
  static const Duration _signedImageUrlSafetyWindow = Duration(minutes: 5);
  static const int _maxCachedSignedImageUrls = 500;
  static final Map<String, _CachedSignedImageUrl> _signedImageUrlCache = {};

  Future<Map<String, String>> _getSignedImageUrls(List<String> paths) async {
    final uniquePaths = paths.toSet().toList();
    if (uniquePaths.isEmpty) return {};

    // Signed URLs are bearer links. Scope the in-memory cache to the signed-in
    // user so one account never reuses another account's cached image links.
    final userScope = _client.auth.currentUser?.id ?? 'anonymous';
    final now = DateTime.now();
    final urlsByPath = <String, String>{};
    final pathsToSign = <String>[];

    for (final path in uniquePaths) {
      final cacheKey = '$userScope::$path';
      final cached = _signedImageUrlCache[cacheKey];
      if (cached != null &&
          cached.expiresAt.isAfter(now.add(_signedImageUrlSafetyWindow))) {
        urlsByPath[path] = cached.url;
      } else {
        if (cached != null) _signedImageUrlCache.remove(cacheKey);
        pathsToSign.add(path);
      }
    }

    if (pathsToSign.isNotEmpty) {
      final results = await _client.storage
          .from(bucket)
          .createSignedUrlsResult(pathsToSign, _signedImageUrlLifetimeSeconds);
      final expiresAt = DateTime.now().add(
        Duration(seconds: _signedImageUrlLifetimeSeconds) -
            _signedImageUrlSafetyWindow,
      );

      for (final result in results) {
        if (result is SignedUrlSuccess) {
          urlsByPath[result.path] = result.signedUrl;
          _signedImageUrlCache['$userScope::${result.path}'] =
              _CachedSignedImageUrl(result.signedUrl, expiresAt);
        } else if (result is SignedUrlFailure) {
          throw StateError(
            'Unable to create a signed URL for product image: ${result.path}',
          );
        }
      }

      for (final path in pathsToSign) {
        if (!urlsByPath.containsKey(path)) {
          throw StateError('No signed URL returned for product image: $path');
        }
      }
    }

    _pruneSignedImageUrlCache(DateTime.now());
    return urlsByPath;
  }

  static void _pruneSignedImageUrlCache(DateTime now) {
    _signedImageUrlCache.removeWhere(
      (_, cached) => !cached.expiresAt.isAfter(now),
    );
    if (_signedImageUrlCache.length <= _maxCachedSignedImageUrls) return;

    final oldestFirst = _signedImageUrlCache.entries.toList()
      ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
    final overflow = _signedImageUrlCache.length - _maxCachedSignedImageUrls;
    for (final entry in oldestFirst.take(overflow)) {
      _signedImageUrlCache.remove(entry.key);
    }
  }

  Future<List<Product>> _mapProducts(
    List<Map<String, dynamic>> rows, {
    bool includeAllImages = false,
  }) async {
    final pathsByProduct = <List<String>>[];
    final allPaths = <String>[];

    for (final row in rows) {
      final imageRows = (row['product_images'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
        ..sort(
          (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int),
        );

      // Listing cards use only the primary image. Full galleries are fetched
      // when the product detail/editor screen requests the complete product.
      final visibleImageRows = includeAllImages || imageRows.isEmpty
          ? imageRows
          : imageRows.take(1).toList();
      final paths = visibleImageRows
          .map((image) => image['storage_path'] as String)
          .toList();
      pathsByProduct.add(paths);
      allPaths.addAll(paths);
    }

    // Sign all uncached images in one Storage request for this product batch,
    // instead of firing one request per product card.
    final urlsByPath = await _getSignedImageUrls(allPaths);
    return List<Product>.generate(rows.length, (index) {
      final paths = pathsByProduct[index];
      return Product.fromMap(
        rows[index],
        signedImageUrls: paths.map((path) => urlsByPath[path]!).toList(),
        paths: paths,
      );
    });
  }

  Future<File> downloadImageForEditing(String storagePath) async {
    final bytes = await _client.storage.from(bucket).download(storagePath);
    final directory = await Directory.systemTemp.createTemp('kenza-image-edit-');
    final extension = storagePath.split('.').last.toLowerCase();
    final safeExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
    final file = File('${directory.path}/source.$safeExtension');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<String> publishProduct({
    required String categoryId,
    required String title,
    required String description,
    required double price,
    required List<File> images,
    required String audience,
    String? customCategoryName,
    int primaryImageIndex = 0,
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

      final safePrimaryIndex = primaryImageIndex.clamp(0, imageRows.length - 1).toInt();
      final primaryImageRow = imageRows.removeAt(safePrimaryIndex);
      imageRows.insert(0, primaryImageRow);
      for (var index = 0; index < imageRows.length; index++) {
        imageRows[index]['sort_order'] = index;
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
    List<File> images = const [],
    List<String> removedImagePaths = const [],
    int primaryImageIndex = 0,
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

    final currentImageRows = await _client
        .from('product_images')
        .select('storage_path,sort_order')
        .eq('product_id', productId)
        .order('sort_order');
    final currentPaths = currentImageRows
        .map((row) => row['storage_path'] as String)
        .toSet();
    final removedPaths = removedImagePaths.toSet();
    if (!currentPaths.containsAll(removedPaths)) {
      throw Exception(strings.productNotFoundOrNoEditPermission);
    }

    final finalImageCount = currentPaths.length - removedPaths.length + images.length;
    if (finalImageCount < 1 || finalImageCount > maxImages) {
      throw Exception(strings.selectAtLeastOnePhoto);
    }

    final needsImageReview = previous['status'] == 'draft' ||
        previous['title'] != title.trim() ||
        (previous['description'] ?? '') != description.trim() ||
        previous['category_id'] != categoryId ||
        images.isNotEmpty ||
        removedPaths.isNotEmpty;

    final uploadedPaths = <String>[];
    final insertedPaths = <String>[];
    try {
      var nextSortOrder = currentImageRows.isEmpty
          ? 0
          : currentImageRows
                  .map((row) => (row['sort_order'] as num).toInt())
                  .reduce((a, b) => a > b ? a : b) +
              1;
      final imageRows = <Map<String, dynamic>>[];

      for (final file in images) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty || bytes.length > maxImageBytes) {
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
            '${user.id}/$productId/${DateTime.now().microsecondsSinceEpoch}_$nextSortOrder.$extension';

        await _client.storage.from(bucket).uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: contentType, upsert: false),
            );
        uploadedPaths.add(path);
        insertedPaths.add(path);
        imageRows.add({
          'product_id': productId,
          'storage_path': path,
          'sort_order': nextSortOrder,
        });
        nextSortOrder++;
      }

      if (imageRows.isNotEmpty) {
        await _client.from('product_images').insert(imageRows);
      }

      final rows = await _client
          .from('products')
          .update({
            'title': title.trim(),
            'description': description.trim(),
            'price': price,
            'category_id': categoryId,
            'custom_category_name': customCategoryName?.trim().isEmpty == true
                ? null
                : customCategoryName?.trim(),
            'audience': audience,
            // Hide changed content until the image review approves it.
            if (needsImageReview) 'status': 'draft',
          })
          .eq('id', productId)
          .eq('owner_id', user.id)
          .select('id');

      if (rows.isEmpty) {
        throw Exception(strings.productNotFoundOrNoEditPermission);
      }

      if (removedPaths.isNotEmpty) {
        await _client
            .from('product_images')
            .delete()
            .eq('product_id', productId)
            .inFilter('storage_path', removedPaths.toList());
        try {
          await _client.storage.from(bucket).remove(removedPaths.toList());
        } catch (_) {
          // The database no longer references these files; orphan cleanup is best-effort.
        }
      }

      final orderedPaths = <String>[
        ...currentImageRows
            .map((row) => row['storage_path'] as String)
            .where((path) => !removedPaths.contains(path)),
        ...insertedPaths,
      ];
      if (orderedPaths.isNotEmpty) {
        final safePrimaryIndex = primaryImageIndex.clamp(0, orderedPaths.length - 1).toInt();
        final primaryPath = orderedPaths.removeAt(safePrimaryIndex);
        orderedPaths.insert(0, primaryPath);
        for (var index = 0; index < orderedPaths.length; index++) {
          await _client
              .from('product_images')
              .update({'sort_order': index})
              .eq('product_id', productId)
              .eq('storage_path', orderedPaths[index]);
        }
      }
    } catch (_) {
      if (insertedPaths.isNotEmpty) {
        try {
          await _client
              .from('product_images')
              .delete()
              .eq('product_id', productId)
              .inFilter('storage_path', insertedPaths);
        } catch (_) {
          // Preserve the original failure; storage cleanup can be retried.
        }
      }
      if (uploadedPaths.isNotEmpty) {
        try {
          await _client.storage.from(bucket).remove(uploadedPaths);
        } catch (_) {
          // Preserve the original failure; storage cleanup can be retried.
        }
      }
      rethrow;
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
