import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/member_avatar.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'about_kenza_screen.dart';
import 'policies_screen.dart';
import 'password_recovery_screen.dart';
import 'messages_inbox_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _avatarChoices = ['🧑', '👩', '👨', '🧕', '🦊', '🐼', '🌸', '⭐'];

  final _auth = AuthService();
  final _service = MarketplaceService();
  final _imagePicker = ImagePicker();
  Map<String, dynamic>? _profile;
  List<Product> _products = [];
  bool _loading = true;
  bool _savingAvatar = false;
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
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'اسمك',
            helperText: 'يمكنك كتابة الاسم الأول فقط أو الاسم بالكامل.',
          ),
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

  Future<void> _showAvatarOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الصورة الشخصية', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('اختر صورة من جهازك أو Avatar جاهزًا.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, 'photo'),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('اختيار صورة من الجهاز'),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('اختيار Avatar', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: _avatarChoices.map((avatar) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () => Navigator.pop(sheetContext, 'preset:$avatar'),
                    child: CircleAvatar(
                      radius: 27,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(avatar, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, 'default'),
                child: const Text('استخدام الصورة الافتراضية'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;
    if (choice == 'photo') {
      await _pickProfilePhoto();
    } else if (choice == 'default') {
      await _saveAvatar(null);
    } else if (choice.startsWith('preset:')) {
      await _saveAvatar(choice);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final user = _user;
    if (user == null || _savingAvatar) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('حجم الصورة بعد ضغطها يجب ألا يتجاوز 5 ميجابايت');
      }

      final extension = picked.path.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final path = '${user.id}/avatar_${DateTime.now().microsecondsSinceEpoch}.${extension == 'png' || extension == 'webp' ? extension : 'jpg'}';

      setState(() => _savingAvatar = true);
      await Supabase.instance.client.storage.from('member-avatars').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      final publicUrl = Supabase.instance.client.storage
          .from('member-avatars')
          .getPublicUrl(path);
      await _saveAvatar(publicUrl, uploadedPath: path);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث الصورة: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }

  Future<void> _saveAvatar(String? avatar, {String? uploadedPath}) async {
    final user = _user;
    if (user == null) return;
    final oldAvatar = _profile?['avatar_url'] as String?;
    try {
      setState(() => _savingAvatar = true);
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': avatar})
          .eq('id', user.id);

      final marker = '/storage/v1/object/public/member-avatars/';
      if (oldAvatar != null && oldAvatar.contains(marker)) {
        final oldPath = oldAvatar.split(marker).last;
        if (oldPath.isNotEmpty && oldPath != uploadedPath) {
          try {
            await Supabase.instance.client.storage.from('member-avatars').remove([oldPath]);
          } catch (_) {
            // A stale image should not block saving the new profile photo.
          }
        }
      }
      await _load();
    } catch (error) {
      if (uploadedPath != null) {
        try {
          await Supabase.instance.client.storage.from('member-avatars').remove([uploadedPath]);
        } catch (_) {}
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
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
                        leading: MemberAvatar(
                          avatarUrl: _profile?['avatar_url'] as String?,
                          radius: 28,
                        ),
                        title: Text(
                          (_profile?['display_name'] as String?)?.isNotEmpty == true
                              ? _profile!['display_name'] as String
                              : 'عضو كنزة هب',
                        ),
                        subtitle: Text(user.email ?? ''),
                        trailing: IconButton(
                          onPressed: _editName,
                          tooltip: 'تعديل الاسم',
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _savingAvatar ? null : _showAvatarOptions,
                        icon: _savingAvatar
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt_outlined),
                        label: const Text('تغيير الصورة الشخصية أو اختيار Avatar'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'الاسم الكامل، إذا كتبته، يظهر لك وحدك. الأعضاء الآخرون يرون الاسم الأول فقط.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const Divider(height: 28),
                      ListTile(
                        leading: const Icon(Icons.notifications_none_rounded),
                        title: const Text('الإشعارات'),
                        subtitle: const Text('تنبيهات الرسائل والعروض وطلبات الشراء'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.mail_outline_rounded),
                        title: const Text('الرسائل والعروض وطلبات الشراء'),
                        subtitle: const Text('محادثاتك والطلبات الواردة والصادرة'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MessagesInboxScreen()),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.favorite_border_rounded),
                        title: const Text('المفضلة'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
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
