import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerStoreSettingsScreen extends StatefulWidget {
  const SellerStoreSettingsScreen({super.key});

  @override
  State<SellerStoreSettingsScreen> createState() => _SellerStoreSettingsScreenState();
}

class _SellerStoreSettingsScreenState extends State<SellerStoreSettingsScreen> {
  final _client = Supabase.instance.client;
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _cover = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();
  final _website = TextEditingController();
  final _whatsapp = TextEditingController();

  bool _loading = true;
  bool _saving = false;
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
          .select('id,business_type,shop_area,show_storefront,cover_image_url,social_links')
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
        const SnackBar(content: Text('اكتب عنوان المحل قبل إظهار واجهته للعامة')),
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

      final cover = _validatedHttps(_cover.text, 'صورة الغلاف');
      final update = <String, dynamic>{
        'cover_image_url': cover,
        'social_links': links,
        if (_agency) ...{
          'shop_area': _area.text.trim().isEmpty ? null : _area.text.trim(),
          'show_storefront': _showStorefront,
        },
      };

      if (_agency) {
        final address = _address.text.trim();
        if (address.isEmpty) {
          await _client
              .from('seller_shop_addresses')
              .delete()
              .eq('seller_profile_id', _profileId!);
        } else {
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
          if (_agency) ...[
            _field(_area, 'المنطقة أو الحي', hint: 'مثال: وكالة البلح - بولاق'),
            _field(_address, 'عنوان المحل', hint: 'العنوان الفعلي للمحل'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _showStorefront,
              onChanged: _isOwner ? (value) => setState(() => _showStorefront = value) : null,
              title: const Text('إظهار واجهة المحل'),
              subtitle: const Text('عند التفعيل سيظهر عنوان المحل للزوار. عند الإيقاف يظل العنوان خاصًا.'),
            ),
          ] else
            const Text('لا نطلب عنوان محل من المتاجر الأونلاين.'),
          const SizedBox(height: 8),
          _field(_cover, 'رابط صورة الغلاف', hint: 'https://...'),
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
            onPressed: _isOwner && !_saving ? _save : null,
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
