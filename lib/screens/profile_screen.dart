import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/account_access_service.dart';
import '../services/marketplace_service.dart';
import '../services/push_notification_service.dart';
import '../widgets/member_avatar.dart';
import '../widgets/kenza_asset_icon.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'about_kenza_screen.dart';
import 'policies_screen.dart';
import 'password_recovery_screen.dart';
import 'messages_inbox_screen.dart';
import 'favorites_screen.dart';
import 'gender_change_request_screen.dart';
import 'admin_gender_requests_screen.dart';
import 'admin_pro_seller_requests_screen.dart';
import 'pro_seller_request_screen.dart';
import 'seller_profile_screen.dart';
import 'store_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _avatarChoices = ['🧑', '👩', '👨', '🧕', '🦊', '🐼', '🌸', '⭐'];

  final _auth = AuthService();
  final _service = MarketplaceService();
  final _accountAccess = AccountAccessService();
  final _imagePicker = ImagePicker();
  Map<String, dynamic>? _profile;
  List<Product> _products = [];
  bool _loading = true;
  bool _savingAvatar = false;
  String? _error;
  String _accountRole = 'buyer';
  bool _isKenzaAdmin = false;
  Map<String, dynamic>? _latestProSellerRequest;
  Map<String, dynamic>? _store;

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
      final accountAccess = await _accountAccess.loadCurrentAccount();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _products = products;
        _accountRole = accountAccess['role'] as String;
        _isKenzaAdmin = accountAccess['isAdmin'] as bool;
        _latestProSellerRequest = accountAccess['request'] as Map<String, dynamic>?;
        _store = accountAccess['store'] as Map<String, dynamic>?;
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
        title: Text(AppStrings.of(dialogContext)!.editNameTitle),
        content: TextField(
          controller: controller,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: AppStrings.of(dialogContext)!.yourName,
            helperText: AppStrings.of(dialogContext)!.displayNameHelper,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.of(dialogContext)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(AppStrings.of(dialogContext)!.saveChanges),
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
          SnackBar(content: Text('${AppStrings.of(context)!.updateNameFailed}: $error')),
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
              Text(AppStrings.of(sheetContext)!.avatarTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(AppStrings.of(sheetContext)!.avatarChooseHint),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, 'photo'),
                  icon: KenzaAssetIcon('assets/icons/camera.png', size: 22, scale: 1.25),
                  label: Text(AppStrings.of(sheetContext)!.choosePhotoFromDevice),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(AppStrings.of(sheetContext)!.chooseAvatar, style: Theme.of(context).textTheme.titleMedium),
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
                child: Text(AppStrings.of(sheetContext)!.useDefaultAvatar),
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
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception(AppStrings.of(context)!.avatarTooLarge);
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
          SnackBar(content: Text('${AppStrings.of(context)!.updateAvatarFailed}: $error')),
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
    await PushNotificationService.instance.deactivateCurrentDevice();
    await _auth.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context)!.profileTitle),
        actions: [
          IconButton(
            onPressed: _signOut,
            tooltip: AppStrings.of(context)!.logout,
            icon: Transform.scale(
              scaleX: Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0,
              child: const Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text(AppStrings.of(context)!.loginToViewAccount))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_error != null)
                        Material(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppStrings.of(context)!.profileDataLoadError}: $_error',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton(
                                    onPressed: _load,
                                    child: Text(AppStrings.of(context)!.retryAction),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            MemberAvatar(
                              avatarUrl: _profile?['avatar_url'] as String?,
                              radius: 48,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (_profile?['display_name'] as String?)?.isNotEmpty == true
                                        ? _profile!['display_name'] as String
                                        : AppStrings.of(context)!.memberFallback,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _editName,
                              tooltip: AppStrings.of(context)!.editNameTooltip,
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
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
                        label: Text(AppStrings.of(context)!.changeProfilePhoto),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.of(context)!.profileNamePrivacy,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Divider(height: 28),
                      Builder(
                        builder: (context) {
                          final strings = AppStrings.of(context)!;
                          final languageCode = Localizations.localeOf(context).languageCode;
                          final languageName = languageCode == 'ar'
                              ? 'العربية'
                              : languageCode == 'fr'
                                  ? 'Français'
                                  : 'English';
                          return ListTile(
                            leading: KenzaAssetIcon('assets/language.png', size: 28, scale: 1.25),
                            title: Text(strings.languageSettingsTitle),
                            subtitle: Text('$languageName · ${strings.languageSettingsSubtitle}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              showDragHandle: true,
                              builder: (sheetContext) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        strings.chooseLanguage,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    ),
                                    ListTile(
                                      leading: const Text('🇪🇬', style: TextStyle(fontSize: 24)),
                                      title: const Text('العربية'),
                                      trailing: languageCode == 'ar' ? const Icon(Icons.check) : null,
                                      onTap: () async {
                                        await AppLocale.setLanguage('ar');
                                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                                      title: const Text('English'),
                                      trailing: languageCode == 'en' ? const Icon(Icons.check) : null,
                                      onTap: () async {
                                        await AppLocale.setLanguage('en');
                                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
                                      title: const Text('Français'),
                                      trailing: languageCode == 'fr' ? const Icon(Icons.check) : null,
                                      onTap: () async {
                                        await AppLocale.setLanguage('fr');
                                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: KenzaAssetIcon('assets/message.png', size: 28, scale: 1.25),
                        title: Text(AppStrings.of(context)!.messagesOffersOrdersTitle),
                        subtitle: Text(
                          '${AppStrings.of(context)!.messagesOffersOrdersSubtitle} · '
                          '${AppStrings.of(context)!.notificationsTitle}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MessagesInboxScreen()),
                        ),
                      ),
                      ListTile(
                        leading: KenzaAssetIcon('assets/seller.png', size: 28, scale: 1.25),
                        title: Text(AppStrings.of(context)!.sellerPublicProfile),
                        subtitle: Text(AppStrings.of(context)!.sellerLocationPrivacy),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SellerProfileScreen(sellerId: user.id),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: KenzaAssetIcon('assets/favorite.png', size: 28, scale: 1.25),
                        title: Text(AppStrings.of(context)!.favoritesTitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        ),
                      ),
                      const Divider(height: 28),
                      ExpansionTile(
                        leading: KenzaAssetIcon('assets/profile.png', size: 28, scale: 1.25),
                        title: Text(AppStrings.of(context)!.accountTab),
                        initiallyExpanded: false,
                        children: [
                        ListTile(
                          leading: KenzaAssetIcon(_accountRole == 'pro_seller' ? 'assets/store.png' : 'assets/profile.png', size: 28, scale: 1.25),
                          title: Text(_accountRole == 'pro_seller'
                              ? AppStrings.of(context)!.accountTypeProSeller
                              : AppStrings.of(context)!.accountTypeBuyer),
                          subtitle: Text(
                            _accountRole == 'pro_seller'
                                ? (_store?['store_name'] as String?) ?? AppStrings.of(context)!.myStore
                                : _latestProSellerRequest?['status'] == 'pending'
                                    ? AppStrings.of(context)!.upgradeRequestPending
                                    : _latestProSellerRequest?['status'] == 'approved'
                                        ? AppStrings.of(context)!.requestApproved
                                        : _latestProSellerRequest?['status'] == 'rejected'
                                            ? AppStrings.of(context)!.requestRejected
                                            : AppStrings.of(context)!.upgradeProSeller,
                          ),
                          trailing: _accountRole == 'buyer' &&
                                  _latestProSellerRequest?['status'] != 'pending'
                              ? const Icon(Icons.chevron_right)
                              : null,
                          onTap: _accountRole == 'buyer' &&
                                  _latestProSellerRequest?['status'] != 'pending'
                              ? () async {
                                  final submitted = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(builder: (_) => const ProSellerRequestScreen()),
                                  );
                                  if (submitted == true) await _load();
                                }
                              : null,
                        ),
                        if (_isKenzaAdmin)
                          ListTile(
                            leading: KenzaAssetIcon('assets/admin.png', size: 28, scale: 1.25),
                            title: Text(AppStrings.of(context)!.adminProSellerRequests),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdminProSellerRequestsScreen()),
                            ).then((_) => _load()),
                          ),
                        if (_isKenzaAdmin)
                          ListTile(
                            leading: KenzaAssetIcon('assets/admin.png', size: 28, scale: 1.25),
                            title: Text(AppStrings.of(context)!.reviewGenderRequests),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdminGenderRequestsScreen()),
                            ),
                          ),
                        if (_accountRole == 'pro_seller' && _store != null)
                          ListTile(
                            leading: KenzaAssetIcon('assets/store.png', size: 28, scale: 1.25),
                            title: Text(Localizations.localeOf(context).languageCode == 'ar'
                                ? 'إدارة متجري'
                                : Localizations.localeOf(context).languageCode == 'fr'
                                    ? 'Gérer ma boutique'
                                    : 'Manage my store'),
                            subtitle: Text(_store?['store_name'] as String? ?? ''),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const StoreManagementScreen()),
                              );
                              if (mounted) await _load();
                            },
                          ),
                        ListTile(
                          leading: KenzaAssetIcon('assets/profile.png', size: 28, scale: 1.25),
                          title: Text(AppStrings.of(context)!.registeredGender),
                          subtitle: Text(AppStrings.of(context)!.genderChangeAdminOnly),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const GenderChangeRequestScreen()),
                          ).then((_) => _load()),
                        ),
                        ListTile(
                          leading: KenzaAssetIcon('assets/lock.png', size: 28, scale: 1.25),
                          title: Text(AppStrings.of(context)!.changePassword),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PasswordRecoveryScreen()),
                          ),
                        ),
                        ListTile(
                          leading: KenzaAssetIcon('assets/info.png', size: 28, scale: 1.25),
                          title: Text(AppStrings.of(context)!.aboutKenzaTitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AboutKenzaScreen()),
                          ),
                        ),
                        ListTile(
                          leading: KenzaAssetIcon('assets/document.png', size: 28, scale: 1.25),
                          title: Text(AppStrings.of(context)!.policiesAndTerms),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                          ),
                        ),
  
                        ],
                      ),
                      const Divider(height: 28),
                      ListTile(
                        leading: KenzaAssetIcon('assets/products.png', size: 28, scale: 1.25),
                        title: Text('${AppStrings.of(context)!.myProductsTitle} (${_products.length})'),
                        subtitle: Text(AppStrings.of(context)!.myProductsSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MyProductsScreen(initialProducts: _products),
                          ),
                        ).then((_) => _load()),
                      ),
                    ],
                  ),
                ),
    );
  }
}


class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key, required this.initialProducts});
  final List<Product> initialProducts;

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  final _service = MarketplaceService();
  late List<Product> _products;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _products = List<Product>.from(widget.initialProducts);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final products = await _service.getMyProducts();
      if (!mounted) return;
      setState(() => _products = products);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context)!.myProductsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(AppStrings.of(context)!.myProductsLoadError),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: Text(AppStrings.of(context)!.retryAction)),
                  ]),
                ))
              : _products.isEmpty
                  ? Center(child: Text(AppStrings.of(context)!.noProductsYet))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
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
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(productId: product.id),
                              ));
                              if (mounted) await _load();
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
