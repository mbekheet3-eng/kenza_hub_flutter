import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerStoreSettingsScreen extends StatefulWidget {
  const SellerStoreSettingsScreen({super.key});

  @override
  State<SellerStoreSettingsScreen> createState() => _SellerStoreSettingsScreenState();
}

class _SellerStoreSettingsScreenState extends State<SellerStoreSettingsScreen> {
  final _client = Supabase.instance.client;
  final _imagePicker = ImagePicker();
  final _displayName = TextEditingController();
  final _businessName = TextEditingController();
  final _bio = TextEditingController();
  final _avatar = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _cover = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();
  final _website = TextEditingController();
  final _whatsapp = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  bool _showStorefront = false;
  bool _isOwner = false;
  bool _agency = false;
  String? _profileId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _businessName.dispose();
    _bio.dispose();
    _avatar.dispose();
    _area.dispose();
    _address.dispose();
    _cover.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _website.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw StateError('يجب تسجيل الدخول أولاً');

      final membership = await _client
          .from('seller_profile_members')
          .select('seller_profile_id,member_role')
          .eq('user_id', userId)
          .isFilter('revoked_at', null)
          .maybeSingle();
      if (membership == null) throw StateError('لا توجد عضوية متجر نشطة');

      final profileId = membership['seller_profile_id'] as String;
      final profile = await _client
          .from('seller_profiles')
          .select('id,display_name,business_name,bio,avatar_url,business_type,shop_area,show_storefront,cover_image_url,social_links')
          .eq('id', profileId)
          .single();

      final addressRow = profile['business_type'] == 'agency'
          ? await _client
              .from('seller_shop_addresses')
              .select('address_line')
              .eq('seller_profile_id', profileId)
              .maybeSingle()
          : null;
      final links = profile['social_links'] is Map
          ? Map<String, dynamic>.from(profile['social_links'] as Map)
          : <String, dynamic>{};

      if (!mounted) return;
      setState(() {
        _profileId = profileId;
        _displayName.text = profile['display_name'] as String? ?? '';
        _businessName.text = profile['business_name'] as String? ?? '';
        _bio.text = profile['bio'] as String? ?? '';
        _avatar.text = profile['avatar_url'] as String? ?? '';
        _agency = profile['business_type'] == 'agency';
        _isOwner = membership['member_role'] == 'owner';
        _area.text = profile['shop_area'] as String? ?? '';
        _address.text = addressRow?['address_line'] as String? ?? '';
        _cover.text = profile['cover_image_url'] as String? ?? '';
        _facebook.text = links['facebook'] as String? ?? '';
        _instagram.text = links['instagram'] as String? ?? '';
        _website.text = links['website'] as String? ?? '';
        _whatsapp.text = links['whatsapp'] as String? ?? '';
        _showStorefront = profile['show_storefront'] == true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickStoreImage({required bool cover}) async {
    if (!_isOwner || _profileId == null || _uploadingImage) return;
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null) return;

      setState(() => _uploadingImage = true);
      var extension = image.path.split('.').last.toLowerCase();
      if (!const ['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        extension = 'jpg';
      }
      final mimeType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      final imageKind = cover ? 'cover' : 'logo';
      final fileName =
          "${imageKind}_${DateTime.now().millisecondsSinceEpoch}.$extension";
      final objectPath = '$_profileId/$fileName';
      await _client.storage.from('seller-store-media').uploadBinary(
            objectPath,
            await image.readAsBytes(),
            fileOptions: FileOptions(contentType: mimeType),
          );
      final publicUrl =
          _client.storage.from('seller-store-media').getPublicUrl(objectPath);
      if (!mounted) return;
      setState(() {
        if (cover) {
          _cover.text = publicUrl;
        } else {
          _avatar.text = publicUrl;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع الصورة، احفظ البيانات لتثبيتها في صفحة المتجر')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر رفع الصورة: $error')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  String? _validatedHttps(String value, String label) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException('رابط $label لازم يبدأ بـ https://');
    }
    return trimmed;
  }

  Future<void> _save() async {
    if (!_isOwner || _profileId == null) return;
    if (_agency && _showStorefront && _address.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عنوان المحل الفعلي لتفعيل عرض واجهته')),
      );
      return;
    }

    if (_agency && _showStorefront && _cover.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختَر صورة واجهة المحل قبل تفعيل عرضها')),
      );
      return;
    }

    if (_displayName.text.trim().length < 3 || _displayName.text.trim().length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم العرض لازم يكون من 3 إلى 60 حرفًا')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final links = <String, String>{};
      final facebook = _validatedHttps(_facebook.text, 'Facebook');
      final instagram = _validatedHttps(_instagram.text, 'Instagram');
      final website = _validatedHttps(_website.text, 'الموقع');
      final whatsapp = _validatedHttps(_whatsapp.text, 'WhatsApp');
      if (facebook != null) links['facebook'] = facebook;
      if (instagram != null) links['instagram'] = instagram;
      if (website != null) links['website'] = website;
      if (whatsapp != null) links['whatsapp'] = whatsapp;

      final avatar = _validatedHttps(_avatar.text, 'صورة المتجر');
      final cover = _validatedHttps(_cover.text, 'صورة الغلاف');
      final update = <String, dynamic>{
        'display_name': _displayName.text.trim(),
        'business_name': _businessName.text.trim().isEmpty ? null : _businessName.text.trim(),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'avatar_url': avatar,
        'cover_image_url': cover,
        'social_links': links,
        if (_agency) ...{
          'shop_area': _area.text.trim().isEmpty ? null : _area.text.trim(),
          'show_storefront': _showStorefront,
        },
      };

      if (_agency) {
        final address = _address.text.trim();
        if (address.isEmpty && !_showStorefront) {
          // Turn off public disclosure before removing the address row.
          await _client
              .from('seller_profiles')
              .update({'show_storefront': false})
              .eq('id', _profileId!);
          await _client
              .from('seller_shop_addresses')
              .delete()
              .eq('seller_profile_id', _profileId!);
        } else if (address.isNotEmpty) {
          await _client.from('seller_shop_addresses').upsert({
            'seller_profile_id': _profileId,
            'address_line': address,
          }, onConflict: 'seller_profile_id');
        }
      }

      await _client
          .from('seller_profiles')
          .update(update)
          .eq('id', _profileId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات المتجر')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('إعدادات المتجر')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('إعدادات المتجر')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('تعذر تحميل بيانات المتجر: $_error', textAlign: TextAlign.center),
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المتجر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_isOwner)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('تعديل بيانات المتجر متاح لصاحب المتجر فقط حاليًا.'),
              ),
            ),
          Text(
            _agency ? 'بيانات المحل الفعلي' : 'بيانات المتجر الأونلاين',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _field(_displayName, 'اسم العرض'),
          _field(_businessName, 'اسم النشاط أو المتجر'),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _bio,
              enabled: _isOwner && !_saving,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'نبذة عن المتجر',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          _field(_avatar, 'رابط صورة الشعار أو صورة المتجر', hint: 'https://...'),
          OutlinedButton.icon(
            onPressed: _isOwner && !_saving && !_uploadingImage
                ? () => _pickStoreImage(cover: false)
                : null,
            icon: const Icon(Icons.upload_outlined),
            label: const Text('اختيار صورة الشعار من الجهاز'),
          ),
          if (_agency) ...[
            _field(_area, 'المنطقة أو الحي', hint: 'مثال: وكالة البلح - بولاق'),
            _field(_address, 'عنوان المحل', hint: 'العنوان الفعلي للمحل'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showStorefront,
              onChanged: _isOwner ? (value) => setState(() => _showStorefront = value) : null,
              title: const Text('إظهار واجهة المحل'),
              subtitle: const Text('عند التفعيل تظهر صورة واجهة المحل للزوار. عنوان المحل الكامل يظل خاصًا في كل الأحوال.'),
            ),
          ] else
            const Text('لا نطلب عنوان محل من المتاجر الأونلاين.'),
          const SizedBox(height: 8),
          _field(_cover, _agency ? 'رابط صورة واجهة المحل' : 'رابط صورة غلاف المتجر', hint: 'https://...'),
          OutlinedButton.icon(
            onPressed: _isOwner && !_saving && !_uploadingImage
                ? () => _pickStoreImage(cover: true)
                : null,
            icon: const Icon(Icons.upload_outlined),
            label: Text(_agency ? 'اختيار صورة واجهة المحل' : 'اختيار صورة الغلاف'),
          ),
          const SizedBox(height: 8),
          Text('روابط التواصل الاختيارية',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _field(_facebook, 'Facebook', hint: 'https://facebook.com/...'),
          _field(_instagram, 'Instagram', hint: 'https://instagram.com/...'),
          _field(_website, 'الموقع الإلكتروني', hint: 'https://...'),
          _field(_whatsapp, 'رابط WhatsApp', hint: 'https://wa.me/...'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isOwner && !_saving && !_uploadingImage ? _save : null,
            icon: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ البيانات'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: _isOwner && !_saving,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
