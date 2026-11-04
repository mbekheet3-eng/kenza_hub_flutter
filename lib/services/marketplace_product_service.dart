import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

/// Schema-aligned product access for the current Supabase marketplace schema.
class MarketplaceProductService {
  MarketplaceProductService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _productSelect = '''
    id,seller_id,category_id,title_ar,title_en,description_ar,description_en,
    price,views_count,created_at,updated_at,brand_name,weight_kg,moderation_status,
    brand_id,color_id,size_id,condition_id,status_id,currency_id,audience,
    category:categories!products_category_id_fkey(
      id,slug,name_ar,name_en,parent_id,
      parent:categories!categories_parent_id_fkey(
        id,slug,name_ar,name_en,parent_id,
        parent:categories!categories_parent_id_fkey(
          id,slug,name_ar,name_en,parent_id,
          parent:categories!categories_parent_id_fkey(slug,name_ar)
        )
      )
    ),
    condition:product_conditions!products_condition_id_fkey(name_ar,name_en,slug),
    color:product_colors!products_color_id_fkey(name_ar,name_en,hex_code),
    size:product_sizes!products_size_id_fkey(name_ar,name_en,size_group),
    status:product_statuses!products_status_id_fkey(name_ar,name_en,slug),
    seller:seller_profiles!products_seller_id_fkey(owner_user_id,display_name,avatar_url),
    images:product_images!product_images_product_id_fkey(image_path,storage_bucket,display_order,created_at)
  ''';

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
      if (bucket == 'product-images') {
        urls.add(_client.storage.from(bucket).getPublicUrl(path));
      } else {
        try {
          urls.add(await _client.storage.from(bucket).createSignedUrl(path, 3600));
        } catch (_) {
          // A restricted image is omitted if a signed URL cannot be issued.
        }
      }
    }

    return Product.fromJson({
      ...row,
      'image_urls': urls,
      'image_paths': paths,
    });
  }

  /// Ensures the signed-in member has exactly one active owner membership.
  /// New seller profiles are created only by the approved Edge Function.
  Future<String> ensureSellerProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('يجب تسجيل الدخول قبل البيع');
    }

    final userProfile = await _client
        .from('users')
        .select('default_region_id,first_name,last_name,username')
        .eq('id', userId)
        .single();
    final defaultRegionId = userProfile['default_region_id'] as String?;
    if (defaultRegionId == null) {
      throw StateError(
        'لم يتم تحديد منطقة حسابك بعد. لا يمكن نشر المنتجات قبل استكمال بيانات المنطقة ونطاق الشحن.',
      );
    }
    final region = await _client
        .from('regions')
        .select('name_ar,is_delivery_active')
        .eq('id', defaultRegionId)
        .single();
    if (region['is_delivery_active'] != true) {
      throw StateError(
        'منطقتك (${region['name_ar'] ?? ''}) خارج نطاق الشحن الداخلي الحالي؛ يمكنك التصفح، لكن نشر المنتجات غير متاح لهذه المنطقة الآن.',
      );
    }

    final memberships = await _client
        .from('seller_profile_members')
        .select('seller_profile_id,member_role,revoked_at')
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
      if (membership['member_role'] != 'owner') {
        throw StateError(
          'نشر المنتجات للموظفين سيُفعّل بعد اكتمال صلاحيات الموظفين المعتمدة.',
        );
      }
      sellerProfileId = membership['seller_profile_id'] as String?;
    } else {
      final existingProfile = await _client
          .from('seller_profiles')
          .select('id')
          .eq('owner_user_id', userId)
          .maybeSingle();
      if (existingProfile != null) {
        throw StateError(
          'يوجد ملف متجر لهذا الحساب دون عضوية مالك سليمة؛ يلزم فحصه قبل النشر.',
        );
      }

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
      'p_condition_id': condition['id'],
      'p_color_id': colorId,
      'p_size_id': sizeId,
      'p_brand_name': brandName?.trim().isNotEmpty == true ? brandName!.trim() : null,
      'p_weight_kg': null,
      'p_audience': 'public',
    });

    if (productId is! String || productId.isEmpty) {
      throw StateError('لم تُرجع قاعدة البيانات رقم المنتج بعد إنشائه');
    }
    return productId;
  }

  Future<void> addProductImage({
    required String productId,
    required String imagePath,
    required int displayOrder,
  }) async {
    await _client.rpc('add_product_image', params: {
      'p_product_id': productId,
      'p_image_path': imagePath,
      'p_display_order': displayOrder,
    });
  }

  Future<void> archiveProduct(String productId) async {
    await _client.rpc('archive_product', params: {
      'p_product_id': productId,
    });
  }

  Future<List<Product>> fetchActiveProducts({int limit = 40}) async {
    final rows = await _client
        .from('products')
        .select(_productSelect)
        .eq('status.slug', 'active')
        .order('created_at', ascending: false)
        .limit(limit);

    return await Future.wait((rows as List)
        .map((row) => _parseProductRow(Map<String, dynamic>.from(row as Map))));
  }

  /// Loads every active listing in bounded pages for complete catalogue search.
  /// This avoids silently searching only the first 40/100 newest products.
  Future<List<Product>> fetchAllActiveProducts({int pageSize = 100}) async {
    if (pageSize < 1 || pageSize > 500) {
      throw ArgumentError.value(pageSize, 'pageSize', 'Must be between 1 and 500');
    }

    final products = <Product>[];
    var offset = 0;
    while (true) {
      final rows = await _client
          .from('products')
          .select(_productSelect)
          .eq('status.slug', 'active')
          .order('created_at', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + pageSize - 1);

      final page = (rows as List)
          .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
      products.addAll(page);

      if (page.length < pageSize) break;
      offset += page.length;
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

    String? sellerProfileId;
    if (membershipRows.isNotEmpty) {
      sellerProfileId = membershipRows.single['seller_profile_id'] as String?;
    } else {
      final ownedProfile = await _client
          .from('seller_profiles')
          .select('id')
          .eq('owner_user_id', userId)
          .eq('is_active', true)
          .maybeSingle();
      sellerProfileId = ownedProfile?['id'] as String?;
    }

    if (sellerProfileId == null) return const [];

    final rows = await _client
        .from('products')
        .select(_productSelect)
        .eq('seller_id', sellerProfileId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<void> _requireOwnerMembership() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('يجب تسجيل الدخول أولاً');
    }
    final membership = await _client
        .from('seller_profile_members')
        .select('member_role')
        .eq('user_id', userId)
        .isFilter('revoked_at', null)
        .maybeSingle();

    if (membership == null || membership['member_role'] != 'owner') {
      throw StateError(
        'تعديل المنتجات وإخفاؤها متاحان لصاحب المتجر فقط حتى تكتمل صلاحيات الموظفين المعتمدة.',
      );
    }
  }

  Future<void> updateProductDetails(Product product) async {
    await _requireOwnerMembership();
    await _client.from('products').update({
      'title_ar': product.title,
      'title_en': product.title,
      'description_ar': product.description,
      'description_en': product.description,
      'price': product.price,
    }).eq('id', product.id);
  }

  Future<void> softDeleteProduct(String productId) async {
    await _requireOwnerMembership();
    final deletedStatus = await _client
        .from('product_statuses')
        .select('id')
        .eq('slug', 'deleted')
        .eq('is_active', true)
        .single();

    await _client
        .from('products')
        .update({'status_id': deletedStatus['id']})
        .eq('id', productId);
  }

  Future<Product> fetchProductById(String productId) async {
    final row = await _client
        .from('products')
        .select(_productSelect)
        .eq('id', productId)
        .single();

    return _parseProductRow(Map<String, dynamic>.from(row));
  }
}
