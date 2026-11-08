import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

/// Schema-aligned product access for the current Supabase marketplace schema.
class MarketplaceProductService {
  MarketplaceProductService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _productColumns = '''
    id,seller_id,category_id,title_ar,title_en,description_ar,description_en,
    price,views_count,created_at,updated_at,brand_name,weight_kg,moderation_status,
    brand_id,color_id,size_id,condition_id,status_id,currency_id,audience
  ''';

  Future<List<Map<String, dynamic>>> _rowsByIds(
    String table,
    String columns,
    String column,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const [];
    final rows = await _client.from(table).select(columns).inFilter(column, ids);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<String>> _availableStatusIds() async {
    final rows = await _client
        .from('product_statuses')
        .select('id')
        .eq('slug', 'available');
    return (rows as List)
        .map((row) => (row as Map)['id'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  Future<Product> _parseProductRow(Map<String, dynamic> row) async {
    final rawImages = row['images'];
    final imageRows = rawImages is List ? rawImages : const [];
    final urls = <String>[];
    final paths = <String>[];

    for (final rawImage in imageRows) {
      if (rawImage is! Map) continue;
      final image = Map<String, dynamic>.from(rawImage);
      final path = image['image_path'] as String?;
      final bucket = image['storage_bucket'] as String?;
      if (path == null || bucket == null) continue;
      paths.add(path);
      try {
        urls.add(await _client.storage.from(bucket).createSignedUrl(path, 3600));
      } catch (error) {
        // Keep the product visible, but make inaccessible image paths diagnosable.
        // ignore: avoid_print
        print('Product image URL failed for ${row['id']} ($bucket/$path): $error');
      }
    }

    return Product.fromJson({
      ...row,
      'image_urls': urls,
      'image_paths': paths,
    });
  }

  /// Hydrates product rows using independent, bounded IN queries. Avoids fragile
  /// nested PostgREST embeds that previously caused the whole home feed to 400.
  Future<List<Product>> _hydrateProductRows(
    List<Map<String, dynamic>> productRows,
  ) async {
    if (productRows.isEmpty) return const [];

    List<String> idsFor(String key) => productRows
        .map((row) => row[key] as String?)
        .whereType<String>()
        .toSet()
        .toList(growable: false);

    final productIds = idsFor('id');
    final categoryIds = idsFor('category_id');
    final conditionIds = idsFor('condition_id');
    final colorIds = idsFor('color_id');
    final sizeIds = idsFor('size_id');
    final statusIds = idsFor('status_id');
    final sellerIds = idsFor('seller_id');

    final results = await Future.wait<List<Map<String, dynamic>>>([
      _rowsByIds('product_images',
          'product_id,image_path,storage_bucket,display_order,created_at',
          'product_id', productIds),
      _rowsByIds('categories', 'id,slug,name_ar,name_en,parent_id',
          'id', categoryIds),
      _rowsByIds('product_conditions', 'id,name_ar,name_en,slug',
          'id', conditionIds),
      _rowsByIds('product_colors', 'id,name_ar,name_en,hex_code',
          'id', colorIds),
      _rowsByIds('product_sizes', 'id,name_ar,name_en,size_group',
          'id', sizeIds),
      _rowsByIds('product_statuses', 'id,name_ar,name_en,slug',
          'id', statusIds),
      _rowsByIds('seller_profiles',
          'id,owner_user_id,display_name,avatar_url,seller_type',
          'id', sellerIds),
    ]);

    final imageRows = results[0];
    final categoryRows = results[1];
    final conditionRows = results[2];
    final colorRows = results[3];
    final sizeRows = results[4];
    final statusRows = results[5];
    final sellerRows = results[6];

    final imagesByProduct = <String, List<Map<String, dynamic>>>{};
    for (final image in imageRows) {
      final productId = image['product_id'] as String?;
      if (productId == null) continue;
      imagesByProduct.putIfAbsent(productId, () => <Map<String, dynamic>>[]);
      imagesByProduct[productId]!.add(image);
    }
    for (final images in imagesByProduct.values) {
      images.sort((a, b) =>
          ((a['display_order'] as num?)?.toInt() ?? 0).compareTo(
            (b['display_order'] as num?)?.toInt() ?? 0,
          ));
    }

    final categoriesById = <String, Map<String, dynamic>>{
      for (final row in categoryRows) row['id'] as String: row,
    };
    var parentIds = categoryRows
        .map((row) => row['parent_id'] as String?)
        .whereType<String>()
        .where((id) => !categoriesById.containsKey(id))
        .toSet()
        .toList(growable: false);
    // Category depth is intentionally bounded to protect the feed from cycles.
    for (var depth = 0; depth < 4 && parentIds.isNotEmpty; depth++) {
      final parents = await _rowsByIds(
        'categories', 'id,slug,name_ar,name_en,parent_id', 'id', parentIds);
      for (final parent in parents) {
        categoriesById[parent['id'] as String] = parent;
      }
      parentIds = parents
          .map((row) => row['parent_id'] as String?)
          .whereType<String>()
          .where((id) => !categoriesById.containsKey(id))
          .toSet()
          .toList(growable: false);
    }

    Map<String, dynamic>? categoryTree(String? id, [Set<String>? visited]) {
      if (id == null) return null;
      final seen = visited ?? <String>{};
      if (!seen.add(id)) return null;
      final source = categoriesById[id];
      if (source == null) return null;
      final result = Map<String, dynamic>.from(source);
      final parentId = source['parent_id'] as String?;
      final parent = categoryTree(parentId, seen);
      if (parent != null) result['parent'] = parent;
      return result;
    }

    final conditionsById = {for (final row in conditionRows) row['id'] as String: row};
    final colorsById = {for (final row in colorRows) row['id'] as String: row};
    final sizesById = {for (final row in sizeRows) row['id'] as String: row};
    final statusesById = {for (final row in statusRows) row['id'] as String: row};
    final sellersById = {for (final row in sellerRows) row['id'] as String: row};

    return await Future.wait(productRows.map((row) async {
      final productId = row['id'] as String;
      final category = categoryTree(row['category_id'] as String?);
      return _parseProductRow({
        ...row,
        if (category != null) 'category': category,
        if (row['condition_id'] != null &&
            conditionsById.containsKey(row['condition_id']))
          'condition': conditionsById[row['condition_id']],
        if (row['color_id'] != null && colorsById.containsKey(row['color_id']))
          'color': colorsById[row['color_id']],
        if (row['size_id'] != null && sizesById.containsKey(row['size_id']))
          'size': sizesById[row['size_id']],
        if (row['status_id'] != null && statusesById.containsKey(row['status_id']))
          'status': statusesById[row['status_id']],
        if (row['seller_id'] != null && sellersById.containsKey(row['seller_id']))
          'seller': sellersById[row['seller_id']],
        'images': imagesByProduct[productId] ?? const [],
      });
    }));
  }

  Future<List<Map<String, dynamic>>> fetchDeliveryRegions() async {
    final rows = await _client
        .from('regions')
        .select('id,name_ar,city_ar')
        .eq('is_active', true)
        .eq('is_delivery_active', true)
        .order('name_ar', ascending: true);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<void> setDefaultDeliveryRegion(String regionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('يجب تسجيل الدخول أولاً');
    final region = await _client
        .from('regions')
        .select('id')
        .eq('id', regionId)
        .eq('is_active', true)
        .eq('is_delivery_active', true)
        .maybeSingle();
    if (region == null) {
      throw StateError('منطقة التوصيل المختارة غير متاحة');
    }
    await _client
        .from('users')
        .update({'default_region_id': regionId})
        .eq('id', userId);
  }

  /// Ensures the signed-in member has exactly one active owner membership.
  /// New seller profiles are created only by the approved Edge Function.
  Future<String> ensureSellerProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('يجب تسجيل الدخول قبل البيع');
    }

    // Phone verification and Kenza delivery-zone selection are currently
    // optional product requirements. Members may list from anywhere in Egypt
    // and arrange delivery directly with the buyer when Kenza delivery is
    // unavailable or not selected.
    final userProfile = await _client
        .from('users')
        .select('first_name,last_name,username')
        .eq('id', userId)
        .single();

    final memberships = await _client
        .from('seller_profile_members')
        .select('seller_profile_id,member_role,permissions,revoked_at')
        .eq('user_id', userId)
        .isFilter('revoked_at', null)
        .limit(2);

    final membershipRows = (memberships as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    String? sellerProfileId;
    if (membershipRows.isNotEmpty) {
      final activeMemberships = membershipRows
          .where((row) => row['revoked_at'] == null)
          .toList(growable: false);
      if (activeMemberships.length != 1) {
        throw StateError('عضوية المتجر غير نشطة أو غير محددة؛ لا يمكن النشر.');
      }

      final membership = activeMemberships.single;
      final permissions = membership['permissions'];
      final canCreateProducts =
          permissions is Map && permissions['products:create'] == true;
      final canManageProductImages =
          permissions is Map && permissions['products:update'] == true;
      if (!canCreateProducts || !canManageProductImages) {
        throw StateError(
          'لا تملك صلاحيات إنشاء المنتجات وإدارة صورها في هذا المتجر. '
          'اطلب من صاحب المتجر تفعيل صلاحية إنشاء المنتجات وتعديلها.',
        );
      }
      sellerProfileId = membership['seller_profile_id'] as String?;
    } else {
      final username = (userProfile['username'] as String?)?.trim() ?? '';
      final fullName = [
        (userProfile['first_name'] as String?)?.trim() ?? '',
        (userProfile['last_name'] as String?)?.trim() ?? '',
      ].where((part) => part.isNotEmpty).join(' ');
      final displayName = fullName.length >= 3 ? fullName : username;

      if (displayName.length < 3) {
        throw StateError('أكمل اسمك في الملف الشخصي قبل إنشاء ملف البائع.');
      }

      final response = await _client.functions.invoke(
        'seller-profile-create',
        body: {'display_name': displayName},
      );
      final data = response.data;
      if (data is Map) {
        sellerProfileId = data['seller_profile_id'] as String?;
      }
      if (sellerProfileId == null) {
        throw StateError(
          'تعذر إنشاء ملف البائع من المسار المعتمد؛ حاول مرة أخرى أو تواصل مع الدعم.',
        );
      }
    }

    if (sellerProfileId == null) {
      throw StateError('لا يوجد ملف بائع نشط لهذا الحساب');
    }

    final sellerProfile = await _client
        .from('seller_profiles')
        .select('id,is_active')
        .eq('id', sellerProfileId)
        .single();
    if (sellerProfile['is_active'] != true) {
      throw StateError('ملف البائع غير نشط حالياً');
    }

    return sellerProfileId;
  }

  Future<String> createProduct({
    required String sellerProfileId,
    required String categorySlug,
    required String title,
    required String description,
    required double price,
    double? weightKg,
    required String conditionLabel,
    String? colorLabel,
    String? sizeLabel,
    String? brandName,
  }) async {
    final category = await _client
        .from('categories')
        .select('id')
        .eq('slug', categorySlug)
        .eq('is_active', true)
        .single();

    final condition = await _client
        .from('product_conditions')
        .select('id')
        .eq('name_ar', conditionLabel)
        .eq('is_active', true)
        .single();

    String? colorId;
    if (colorLabel != null && colorLabel.trim().isNotEmpty) {
      final color = await _client
          .from('product_colors')
          .select('id')
          .eq('name_ar', colorLabel.trim())
          .eq('is_active', true)
          .maybeSingle();
      colorId = color?['id'] as String?;
      if (colorId == null) {
        throw StateError('اللون المختار غير موجود في بيانات قاعدة البيانات');
      }
    }

    String? sizeId;
    if (sizeLabel != null && sizeLabel.trim().isNotEmpty) {
      final size = await _client
          .from('product_sizes')
          .select('id')
          .eq('name_ar', sizeLabel.trim())
          .eq('is_active', true)
          .maybeSingle();
      sizeId = size?['id'] as String?;
      if (sizeId == null) {
        throw StateError('المقاس المختار غير موجود في بيانات قاعدة البيانات');
      }
    }

    // V2 stores the seller-entered brand as products.brand_name (text).
    // Product creation must use the guarded RPC, not a direct table INSERT.
    final productId = await _client.rpc('create_product', params: {
      'p_seller_profile_id': sellerProfileId,
      'p_category_id': category['id'],
      'p_title_ar': title.trim(),
      'p_title_en': title.trim(),
      'p_description_ar': description.trim(),
      'p_description_en': description.trim(),
      'p_price': price,
      'p_weight_kg': weightKg,
      'p_condition_id': condition['id'],
      'p_color_id': colorId,
      'p_size_id': sizeId,
      'p_brand_name': brandName?.trim().isNotEmpty == true ? brandName!.trim() : null,
      'p_audience': 'public',
    });

    if (productId is! String || productId.isEmpty) {
      throw StateError('لم تُرجع قاعدة البيانات رقم المنتج بعد إنشائه');
    }
    return productId;
  }

  Future<String> addProductImage({
    required String productId,
    required String imagePath,
    required int displayOrder,
  }) async {
    final imageId = await _client.rpc('add_product_image', params: {
      'p_product_id': productId,
      'p_image_path': imagePath,
      'p_display_order': displayOrder,
    });
    if (imageId is! String || imageId.isEmpty) {
      throw StateError('لم تُرجع قاعدة البيانات معرّف الصورة بعد حفظها');
    }
    return imageId;
  }

  Future<void> archiveProduct(String productId) async {
    await _client.rpc('archive_product', params: {
      'p_product_id': productId,
    });
  }

  /// Loads public, available listings belonging to one store profile.
  Future<List<Product>> fetchProductsForStore(
    String sellerProfileId, {
    int limit = 60,
  }) async {
    final availableIds = await _availableStatusIds();
    if (availableIds.isEmpty) return const [];
    final rows = await _client
        .from('products')
        .select(_productColumns)
        .eq('seller_id', sellerProfileId)
        .inFilter('status_id', availableIds)
        .eq('moderation_status', 'approved')
        .order('created_at', ascending: false)
        .limit(limit);
    return _hydrateProductRows((rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false));
  }

  Future<List<Product>> fetchActiveProducts({int limit = 40}) async {
    final availableIds = await _availableStatusIds();
    if (availableIds.isEmpty) return const [];
    final rows = await _client
        .from('products')
        .select(_productColumns)
        .inFilter('status_id', availableIds)
        .eq('moderation_status', 'approved')
        .order('created_at', ascending: false)
        .limit(limit);
    return _hydrateProductRows((rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false));
  }

  /// Loads all available listings in pages for complete catalogue search.
  Future<List<Product>> fetchAllActiveProducts({int pageSize = 100}) async {
    if (pageSize < 1 || pageSize > 500) {
      throw ArgumentError.value(pageSize, 'pageSize', 'Must be between 1 and 500');
    }
    final availableIds = await _availableStatusIds();
    if (availableIds.isEmpty) return const [];

    final products = <Product>[];
    var offset = 0;
    while (true) {
      final rows = await _client
          .from('products')
          .select(_productColumns)
          .inFilter('status_id', availableIds)
          .eq('moderation_status', 'approved')
          .order('created_at', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + pageSize - 1);
      final pageRows = (rows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
      products.addAll(await _hydrateProductRows(pageRows));
      if (pageRows.length < pageSize) break;
      offset += pageRows.length;
    }
    return products;
  }

  Future<List<Product>> fetchSellerProducts(
    String userId, {
    int limit = 100,
  }) async {
    final memberships = await _client
        .from('seller_profile_members')
        .select('seller_profile_id')
        .eq('user_id', userId)
        .isFilter('revoked_at', null)
        .limit(2);
    final membershipRows = (memberships as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    if (membershipRows.length > 1) {
      throw StateError(
        'حسابك مرتبط بأكثر من متجر نشط. اختر المتجر المطلوب قبل عرض المنتجات.',
      );
    }
    if (membershipRows.isEmpty) return const [];
    final sellerProfileId = membershipRows.single['seller_profile_id'] as String?;
    if (sellerProfileId == null) return const [];

    final rows = await _client
        .from('products')
        .select(_productColumns)
        .eq('seller_id', sellerProfileId)
        .order('created_at', ascending: false)
        .limit(limit);
    final productRows = (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    return _hydrateProductRows(productRows);
  }

  Future<void> updateProductDetails(Product product) async {
    // The edit_product RPC performs the authoritative products:update check,
    // including the employee permissions granted by the store owner.
    final current = await _client
        .from('products')
        .select('category_id,condition_id,color_id,size_id,brand_name,weight_kg,audience')
        .eq('id', product.id)
        .single();

    await _client.rpc('edit_product', params: {
      'p_product_id': product.id,
      'p_category_id': product.categoryId ?? current['category_id'],
      'p_title_ar': product.title,
      'p_title_en': product.title,
      'p_description_ar': product.description,
      'p_description_en': product.description,
      'p_price': product.price,
      'p_condition_id': product.conditionId ?? current['condition_id'],
      'p_color_id': product.colorId ?? current['color_id'],
      'p_size_id': product.sizeId ?? current['size_id'],
      'p_brand_name': product.brand ?? current['brand_name'],
      'p_weight_kg': current['weight_kg'],
      'p_audience': product.audience,
    });
  }

  Future<void> softDeleteProduct(String productId) =>
      archiveProduct(productId);

  Future<Product> fetchProductById(String productId) async {
    final row = await _client
        .from('products')
        .select(_productColumns)
        .eq('id', productId)
        .single();
    final products = await _hydrateProductRows([
      Map<String, dynamic>.from(row),
    ]);
    if (products.isEmpty) {
      throw StateError('تعذر تحميل بيانات المنتج');
    }
    return products.single;
  }
}
