import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';
import 'product_detail_screen.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final _client = Supabase.instance.client;
  final _marketplace = MarketplaceService();
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _description = TextEditingController();
  Map<String, dynamic>? _store;
  List<Product> _products = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _language => Localizations.localeOf(context).languageCode;
  String _t(String ar, String en, String fr) =>
      _language == 'ar' ? ar : _language == 'fr' ? fr : en;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final store = await _client
          .from('stores')
          .select('id,owner_id,store_name,description,logo_url,banner_url,status')
          .eq('owner_id', user.id)
          .maybeSingle();
      if (store == null) throw Exception(_t('لم يتم العثور على متجرك', 'Your store was not found', 'Votre boutique est introuvable'));
      final products = await _marketplace.getMyProducts();
      if (!mounted) return;
      setState(() {
        _store = Map<String, dynamic>.from(store);
        _name.text = store['store_name'] as String? ?? '';
        _description.text = store['description'] as String? ?? '';
        _products = products;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDetails() async {
    final store = _store;
    final user = _client.auth.currentUser;
    if (store == null || user == null || _saving) return;
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('اسم المتجر مطلوب', 'Store name is required', 'Le nom de la boutique est obligatoire')),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await _client.from('stores').update({
        'store_name': _name.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      }).eq('id', store['id']).eq('owner_id', user.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('تم حفظ بيانات المتجر', 'Store details saved', 'Informations de la boutique enregistrées')),
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeImage(String field) async {
    final store = _store;
    final user = _client.auth.currentUser;
    if (store == null || user == null || _saving) return;
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await File(picked.path).readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw Exception(_t('حجم الصورة يجب ألا يتجاوز 10 ميجابايت', 'Image must not exceed 10 MB', 'L’image ne doit pas dépasser 10 Mo'));
      }
      final extension = picked.path.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'jpg' || 'jpeg' => 'image/jpeg',
        _ => throw Exception(_t('صيغة الصورة غير مدعومة', 'Unsupported image format', 'Format d’image non pris en charge')),
      };
      final safeExtension = extension == 'jpeg' ? 'jpg' : extension;
      final path = '${user.id}/${store['id']}/${field}_${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
      setState(() => _saving = true);
      await _client.storage.from('store-media').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mime, upsert: false),
      );
      final url = _client.storage.from('store-media').getPublicUrl(path);
      await _client.from('stores').update({field: url})
          .eq('id', store['id']).eq('owner_id', user.id);
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _imageEditor(String field, String label, IconData icon) {
    final url = _store?[field] as String?;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (url != null && url.isNotEmpty)
          Image.network(url, height: field == 'banner_url' ? 130 : 110, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => SizedBox(height: 90, child: Icon(icon, size: 36)))
        else
          SizedBox(height: 90, child: Icon(icon, size: 36)),
        TextButton.icon(
          onPressed: _saving ? null : () => _changeImage(field),
          icon: Icon(icon),
          label: Text(label),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_t('إدارة متجري', 'Manage my store', 'Gérer ma boutique'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: Text(strings.retryAction)),
                  ]),
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Text(_t('بيانات المتجر', 'Store details', 'Informations de la boutique'),
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(controller: _name, maxLength: 80,
                      decoration: InputDecoration(labelText: _t('اسم المتجر', 'Store name', 'Nom de la boutique'))),
                    const SizedBox(height: 8),
                    TextField(controller: _description, maxLength: 500, maxLines: 4,
                      decoration: InputDecoration(labelText: _t('وصف المتجر', 'Store description', 'Description de la boutique'))),
                    Align(alignment: AlignmentDirectional.centerEnd,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _saveDetails,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? _t('جارٍ الحفظ…', 'Saving…', 'Enregistrement…') : _t('حفظ التعديلات', 'Save changes', 'Enregistrer')),
                      )),
                    const SizedBox(height: 16),
                    Text(_t('صور المتجر', 'Store images', 'Images de la boutique'),
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _imageEditor('logo_url', _t('تغيير الشعار', 'Change logo', 'Changer le logo'), Icons.storefront_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _imageEditor('banner_url', _t('تغيير الغلاف', 'Change banner', 'Changer la bannière'), Icons.panorama_outlined)),
                    ]),
                    const Divider(height: 32),
                    Text(_t('منتجاتي', 'My products', 'Mes produits'),
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_t('اختر منتجًا لفتح تفاصيله وتعديل بياناته أو حذفه إذا كانت هذه الخيارات متاحة له.',
                      'Open a product to edit its details or delete it when those actions are available.',
                      'Ouvrez un produit pour modifier ses détails ou le supprimer si ces actions sont disponibles.')),
                    const SizedBox(height: 8),
                    if (_products.isEmpty)
                      Padding(padding: const EdgeInsets.all(20),
                        child: Center(child: Text(strings.noProductsYet)))
                    else
                      ..._products.map((product) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(product.status),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(productId: product.id),
                            ));
                            if (mounted) await _load();
                          },
                        ),
                      )),
                  ]),
                ),
    );
  }
}
