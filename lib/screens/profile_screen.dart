import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'about_kenza_screen.dart';
import 'policies_screen.dart';
import 'password_recovery_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _service = MarketplaceService();
  Map<String, dynamic>? _profile;
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  User? get _user => Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _user;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('display_name,avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      final products = await _service.getMyProducts();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _products = products;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
      text: (_profile?['display_name'] as String?) ?? '',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: TextField(
          controller: controller,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'الاسم الظاهر'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || _user == null) return;
    try {
      // Keep the Auth metadata (used by the home greeting) and profile row
      // (used by the account screen) in sync.
      await _auth.updateDisplayName(name);
      await Supabase.instance.client
          .from('profiles')
          .update({'display_name': name})
          .eq('id', _user!.id);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث الاسم: $error')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            onPressed: _signOut,
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('سجّل الدخول لعرض حسابك'))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                        title: Text(
                          (_profile?['display_name'] as String?)?.isNotEmpty == true
                              ? _profile!['display_name'] as String
                              : 'عضو كنزة هب',
                        ),
                        subtitle: Text(user.email ?? ''),
                        trailing: IconButton(
                          onPressed: _editName,
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                      const Divider(height: 28),
                      ListTile(
                        leading: const Icon(Icons.favorite_border_rounded),
                        title: const Text('المفضلة'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('قسم المفضلة قريبًا')),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock_reset_outlined),
                        title: const Text('تغيير كلمة المرور'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PasswordRecoveryScreen()),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('عن كنزة هب'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutKenzaScreen()),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.policy_outlined),
                        title: const Text('الشروط والسياسات'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                        ),
                      ),
                      const Divider(height: 28),
                      Text('منتجاتي (${_products.length})',
                          style: Theme.of(context).textTheme.titleLarge),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      if (_products.isEmpty && _error == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('لم تضف أي منتجات بعد'),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.68,
                          ),
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return ProductCard(
                              product: product,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(productId: product.id),
                                ),
                              ).then((_) => _load()),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}
