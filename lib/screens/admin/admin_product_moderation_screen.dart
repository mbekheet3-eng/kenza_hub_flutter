import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProductModerationScreen extends StatefulWidget {
  const AdminProductModerationScreen({super.key});
  @override
  State<AdminProductModerationScreen> createState() => _AdminProductModerationScreenState();
}
class _AdminProductModerationScreenState extends State<AdminProductModerationScreen> {
  final _client = Supabase.instance.client;
  bool _checkingRole = true, _isAdmin = false, _loading = false;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String tr(String ar, String en) => _ar ? ar : en;

  @override
  void initState() { super.initState(); _checkAdmin(); }

  Future<void> _checkAdmin() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw StateError('AUTH_REQUIRED');
      final row = await _client.from('users').select('role,is_active').eq('id', user.id).single();
      if (row['is_active'] != true || row['role'] != 'admin') {
        if (mounted) setState(() { _checkingRole = false; _isAdmin = false; });
        return;
      }
      if (mounted) setState(() { _isAdmin = true; _checkingRole = false; });
      await _loadQueue();
    } catch (e) {
      if (mounted) setState(() { _checkingRole = false; _error = e.toString(); });
    }
  }

  Future<void> _loadQueue() async {
    if (!_isAdmin) return;
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _client.from('products').select(
        'id,title_ar,title_en,price,created_at,product_images(id,image_path,storage_bucket,display_order,ai_review_status,ai_review_result)',
      ).eq('moderation_status', 'pending').order('created_at').limit(100);
      final items = <Map<String, dynamic>>[];
      for (final raw in rows) {
        final product = Map<String, dynamic>.from(raw);
        final images = <Map<String, dynamic>>[];
        for (final rawImage in (product['product_images'] as List? ?? const [])) {
          final image = Map<String, dynamic>.from(rawImage as Map);
          final path = image['image_path'] as String?;
          final bucket = image['storage_bucket'] as String?;
          if (path != null && bucket != null) {
            try { image['signed_url'] = await _client.storage.from(bucket).createSignedUrl(path, 300); }
            catch (_) { image['signed_url'] = null; }
          }
          images.add(image);
        }
        product['product_images'] = images;
        items.add(product);
      }
      if (mounted) setState(() => _products = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(Map<String, dynamic> product, String decision) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(decision == 'approved' ? tr('اعتماد المنتج؟', 'Approve product?') : tr('رفض المنتج؟', 'Reject product?')),
        content: TextField(controller: reasonController, maxLines: 3,
          decoration: InputDecoration(labelText: tr('ملاحظة للمراجعة (اختياري)', 'Review note (optional)'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, reasonController.text), child: Text(tr('تأكيد', 'Confirm'))),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    try {
      await _client.rpc('moderate_product', params: {
        'p_product_id': product['id'], 'p_decision': decision,
        'p_reason': reason.trim().isEmpty ? null : reason.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('تم حفظ قرار المراجعة', 'Review decision saved'))));
      await _loadQueue();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('تعذر تنفيذ القرار: ', 'Could not apply decision: ') + e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = tr('مراجعة المنتجات', 'Product moderation');
    if (_checkingRole) return Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator()));
    if (!_isAdmin) return Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text(tr('هذه الصفحة للمشرفين فقط', 'Administrators only'))));
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [IconButton(onPressed: _loadQueue, icon: const Icon(Icons.refresh))]),
      body: _loading && _products.isEmpty ? const Center(child: CircularProgressIndicator())
        : _error != null && _products.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
        : _products.isEmpty ? Center(child: Text(tr('لا توجد منتجات تنتظر المراجعة البشرية', 'No products are waiting for human review')))
        : RefreshIndicator(onRefresh: _loadQueue, child: ListView.builder(
            padding: const EdgeInsets.all(12), itemCount: _products.length,
            itemBuilder: (context, index) => _buildProduct(_products[index]))),
    );
  }

  Widget _buildProduct(Map<String, dynamic> product) {
    final images = (product['product_images'] as List).cast<Map<String, dynamic>>();
    final localized = (_ar ? product['title_ar'] : product['title_en'])?.toString().trim();
    final fallback = (product['title_ar'] ?? product['title_en'] ?? '').toString();
    final reasons = images.map((image) {
      final result = image['ai_review_result'];
      return result is Map ? result['reason_ar']?.toString() : null;
    }).whereType<String>().where((s) => s.isNotEmpty).toSet();
    return Card(margin: const EdgeInsets.only(bottom: 14), child: Padding(
      padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(localized?.isNotEmpty == true ? localized! : fallback, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8), Text((product['price'] ?? '').toString() + ' EGP'), const SizedBox(height: 10),
        if (images.isEmpty) Text(tr('لا توجد صور مسجلة', 'No registered images'))
        else SizedBox(height: 150, child: ListView.separated(
          scrollDirection: Axis.horizontal, itemCount: images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final url = images[index]['signed_url'] as String?;
            return ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 150,
              child: url == null ? Container(color: Colors.black12, child: const Icon(Icons.broken_image_outlined))
                : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))));
          })),
        if (reasons.isNotEmpty) ...[const SizedBox(height: 8), Text(reasons.join(' • '))],
        const SizedBox(height: 12), Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _decide(product, 'rejected'),
            icon: const Icon(Icons.close), label: Text(tr('رفض', 'Reject')),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: () => _decide(product, 'approved'),
            icon: const Icon(Icons.check), label: Text(tr('اعتماد', 'Approve')))),
        ]),
      ]),
    ));
  }
}
