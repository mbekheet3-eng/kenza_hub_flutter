import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/category_labels.dart';
import '../models/category.dart';
import '../models/product.dart';

class MarketplaceService {
  MarketplaceService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String bucket = 'product-images';
  static const int maxImageBytes = 10 * 1024 * 1024;
  static const int maxImages = 8;

  Future<List<Category>> getCategories() async {
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
          'id,owner_id,category_id,title,description,price,currency,created_at,product_images(id,storage_path,sort_order)',
        )
        .eq('status', 'published');

    final categories = await getCategories();
    final searchSlugs = categoryId == null
        ? CategoryLabels.searchSlugs(query)
        : const <String>[];
    final selectedIds = <String>{};
    if (categoryId != null && categoryId.isNotEmpty) {
      selectedIds.add(categoryId);
    } else if (searchSlugs.isNotEmpty) {
      selectedIds.addAll(
        categories.where((item) => searchSlugs.contains(item.slug)).map((item) => item.id),
      );
    }

    if (selectedIds.isNotEmpty) {
      final scopedIds = _categoryScopeIds(categories, selectedIds);
      request = request.inFilter('category_id', scopedIds.toList());
    }

    final normalizedQuery = query?.trim() ?? '';
    final isCategoryIntent = categoryId == null && searchSlugs.isNotEmpty;
    if (normalizedQuery.isNotEmpty && !isCategoryIntent) {
      request = request.ilike('title', '%$normalizedQuery%');
    }

    final rows = await request.order('created_at', ascending: false).limit(limit);
    return Future.wait(rows.map(_mapProduct));
  }

  Future<List<Product>> getMyProducts() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('products')
        .select(
          'id,owner_id,category_id,title,description,price,currency,created_at,product_images(id,storage_path,sort_order)',
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
          'id,owner_id,category_id,title,description,price,currency,created_at,product_images(id,storage_path,sort_order)',
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
          'id,owner_id,category_id,title,description,price,currency,created_at,product_images(id,storage_path,sort_order)',
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
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');
    if (images.isEmpty || images.length > maxImages) {
      throw Exception('اختر صورة واحدة على الأقل وبحد أقصى 8 صور');
    }
    if (title.trim().isEmpty || price <= 0) {
      throw Exception('أدخل عنوانًا وسعرًا صحيحًا للمنتج');
    }

    final created = await _client
        .from('products')
        .insert({
          'owner_id': user.id,
          'category_id': categoryId,
          'title': title.trim(),
          'description': description.trim(),
          'price': price,
          'currency': 'EGP',
          'status': 'draft',
        })
        .select('id')
        .single();

    final productId = created['id'] as String;
    final uploadedPaths = <String>[];

    try {
      final imageRows = <Map<String, dynamic>>[];

      for (var index = 0; index < images.length; index++) {
        final file = images[index];
        final bytes = await file.readAsBytes();
        if (bytes.length > maxImageBytes) {
          throw Exception('حجم الصورة يجب ألا يتجاوز 10 ميجابايت');
        }

        final extension = file.path.split('.').last.toLowerCase();
        final contentType = switch (extension) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => throw Exception('الصيغ المسموحة: JPG وPNG وWebP فقط'),
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

      final published = await _client
          .from('products')
          .update({'status': 'published'})
          .eq('id', productId)
          .eq('owner_id', user.id)
          .select('id');

      if (published.isEmpty) {
        throw Exception('تعذر نشر المنتج. حاول مرة أخرى');
      }

      return productId;
    } catch (_) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await _client.storage.from(bucket).remove(uploadedPaths);
        } catch (_) {
          // Keep the original publishing error; orphan cleanup can be retried.
        }
      }
      try {
        await _client.from('products').delete().eq('id', productId);
      } catch (_) {
        // Keep the original publishing error.
      }
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String categoryId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

    final rows = await _client
        .from('products')
        .update({
          'title': title.trim(),
          'description': description.trim(),
          'price': price,
          'category_id': categoryId,
        })
        .eq('id', productId)
        .eq('owner_id', user.id)
        .select('id');

    if (rows.isEmpty) throw Exception('لم يتم العثور على المنتج أو لا تملك صلاحية تعديله');
  }

  Future<void> deleteProduct(String productId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

    final ownedProduct = await _client
        .from('products')
        .select('id')
        .eq('id', productId)
        .eq('owner_id', user.id)
        .maybeSingle();

    if (ownedProduct == null) {
      throw Exception('لم يتم العثور على المنتج أو لا تملك صلاحية حذفه');
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

    if (deleted.isEmpty) throw Exception('لم يتم حذف المنتج');
  }
}
