import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

/// Schema-aligned product reads for the current Supabase marketplace schema.
class MarketplaceProductService {
  MarketplaceProductService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _productSelect = '''
    id,seller_id,category_id,title_ar,title_en,description_ar,description_en,
    price,views_count,created_at,updated_at,brand_id,brand,color_id,size_id,
    condition_id,status_id,currency_id,audience,
    category:categories!products_category_id_fkey(id,slug,name_ar,name_en,parent_id),
    condition:product_conditions!products_condition_id_fkey(slug,label_ar,label_en),
    color:product_colors!products_color_id_fkey(slug,label_ar,label_en,hex_code),
    size:product_sizes!products_size_id_fkey(slug,label_ar,label_en),
    status:product_statuses!products_status_id_fkey(slug,label_ar,label_en),
    seller:seller_profiles!products_seller_id_fkey(owner_user_id,display_name,avatar_url),
    images:product_images!product_images_product_id_fkey(image_url,display_order)
  ''';

  Future<String> createProduct({
    required String categorySlug,
    required String title,
    required String description,
    required double price,
    required String conditionLabel,
    String? colorLabel,
    String? sizeLabel,
    String? brandName,
    required List<String> imageUrls,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('يجب تسجيل الدخول قبل نشر المنتج');
    }
    if (imageUrls.isEmpty) {
      throw ArgumentError('يجب إضافة صورة واحدة على الأقل');
    }

    // Resolve the active seller profile through the member table. An auth
    // user ID is never written into products.seller_id.
    final memberships = await _client
        .from('seller_profile_members')
        .select('seller_profile_id,member_role,revoked_at')
        .eq('user_id', userId)
        .limit(2);

    String? sellerProfileId;
    final membershipRows = List<Map<String, dynamic>>.from(
      (memberships as List).map((row) => Map<String, dynamic>.from(row as Map)),
    );

    if (membershipRows.isNotEmpty) {
      final activeMemberships = membershipRows
          .where((row) => row['revoked_at'] == null)
          .toList();
      if (activeMemberships.length != 1) {
        throw StateError(
          'عضوية المتجر غير نشطة أو غير محددة؛ لا يمكن نشر المنتج.',
        );
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

      // The approved Edge Function creates the default seller profile and
      // owner membership atomically. Never insert either table from Flutter.
      final userProfile = await _client
          .from('users')
          .select('first_name,last_name,username,phone')
          .eq('id', userId)
          .single();
      final username = (userProfile['username'] as String?)?.trim() ?? '';
      final fullName = [
        (userProfile['first_name'] as String?)?.trim() ?? '',
        (userProfile['last_name'] as String?)?.trim() ?? '',
      ].where((part) => part.isNotEmpty).join(' ');
      final displayName = username.isNotEmpty ? username : fullName;
      if (displayName.length < 3) {
        throw StateError(
          'أكمل اسمك في الملف الشخصي قبل إنشاء ملف البائع.',
        );
      }

      final phone = (userProfile['phone'] as String?)?.trim();
      final functionResponse = await _client.functions.invoke(
        'seller-profile-create',
        body: {
          'display_name': displayName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      final responseData = functionResponse.data;
      if (responseData is Map) {
        sellerProfileId = responseData['seller_profile_id'] as String?;
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

    final category = await _client
        .from('categories')
        .select('id,parent_id')
        .eq('slug', categorySlug)
        .eq('is_active', true)
        .single();
    final categoryId = category['id'] as String;
    final parentId = category['parent_id'] as String?;

    final condition = await _client
        .from('product_conditions')
        .select('id')
        .eq('label_ar', conditionLabel)
        .eq('is_active', true)
        .single();

    final activeStatus = await _client
        .from('product_statuses')
        .select('id')
        .eq('slug', 'active')
        .eq('is_active', true)
        .single();

    final currency = await _client
        .from('currencies')
        .select('id')
        .eq('code', 'EGP')
        .eq('is_active', true)
        .single();

    String? colorId;
    if (colorLabel != null && colorLabel.isNotEmpty) {
      final color = await _client
          .from('product_colors')
          .select('id')
          .eq('label_ar', colorLabel)
          .eq('is_active', true)
          .maybeSingle();
      colorId = color?['id'] as String?;
      if (colorId == null) {
        throw StateError('اللون المختار غير موجود في بيانات قاعدة البيانات');
      }
    }

    String? sizeId;
    if (sizeLabel != null && sizeLabel.isNotEmpty) {
      final sizes = await _client
          .from('product_sizes')
          .select('id,slug,label_ar,label_en,category_id')
          .eq('is_active', true);
      final allowedCategoryIds = {categoryId, if (parentId != null) parentId};
      final matchingSizes = (sizes as List).where((row) {
        final data = Map<String, dynamic>.from(row as Map);
        final matchesLabel = data['label_ar'] == sizeLabel ||
            data['label_en'] == sizeLabel ||
            data['slug'] == sizeLabel;
        return matchesLabel &&
            allowedCategoryIds.contains(data['category_id']);
      }).toList();
      if (matchingSizes.isNotEmpty) {
        sizeId = matchingSizes.first['id'] as String;
      } else {
        throw StateError('المقاس المختار غير متاح لهذا القسم');
      }
    }

    String? brandId;
    if (brandName != null && brandName.trim().isNotEmpty) {
      final brand = await _client
          .from('brands')
          .select('id')
          .eq('name', brandName.trim())
          .maybeSingle();
      brandId = brand?['id'] as String?;
      if (brandId == null) {
        throw StateError('العلامة التجارية المختارة غير موجودة في القائمة المعتمدة');
      }
    }

    final productPayload = <String, dynamic>{
      'seller_id': sellerProfileId,
      'category_id': categoryId,
      'title_ar': title.trim(),
      'title_en': title.trim(),
      'description_ar': description.trim(),
      'description_en': description.trim(),
      'price': price,
      'condition_id': condition['id'],
      'status_id': activeStatus['id'],
      'currency_id': currency['id'],
      'audience': 'everyone',
      if (colorId != null) 'color_id': colorId,
      if (sizeId != null) 'size_id': sizeId,
      if (brandId != null) 'brand_id': brandId,
    };

    final created = await _client
        .from('products')
        .insert(productPayload)
        .select('id')
        .single();
    final productId = created['id'] as String;

    try {
      final imageRows = <Map<String, dynamic>>[];
      for (var index = 0; index < imageUrls.length; index++) {
        imageRows.add({
          'product_id': productId,
          'image_url': imageUrls[index],
          'display_order': index,
        });
      }
      await _client.from('product_images').insert(imageRows);
    } catch (error) {
      // Do not leave a visible product without its images if the image-row
      // write is rejected. This only attempts to remove the just-created row.
      try {
        await _client.from('products').delete().eq('id', productId);
      } catch (_) {
        // Preserve the original failure; the owner can remove the draft later.
      }
      rethrow;
    }

    return productId;
  }

  Future<List<Product>> fetchActiveProducts({int limit = 40}) async {
    final rows = await _client
        .from('products')
        .select(_productSelect)
        .eq('status.slug', 'active')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => Product.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<List<Product>> fetchSellerProducts(String userId,
      {int limit = 100}) async {
    final memberships = await _client
        .from('seller_profile_members')
        .select('seller_profile_id')
        .eq('user_id', userId)
        .isFilter('revoked_at', null)
        .limit(1);

    String? sellerProfileId;
    if ((memberships as List).isNotEmpty) {
      sellerProfileId =
          (memberships.first as Map)['seller_profile_id'] as String?;
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

  Future<void> updateProductDetails(Product product) async {
    await _client.from('products').update({
      'title_ar': product.title,
      'title_en': product.title,
      'description_ar': product.description,
      'description_en': product.description,
      'price': product.price,
    }).eq('id', product.id);
  }

  Future<void> softDeleteProduct(String productId) async {
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

    return Product.fromJson(Map<String, dynamic>.from(row));
  }
}
