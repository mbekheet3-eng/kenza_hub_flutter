import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';
import '../services/favorites_service.dart';
import '../services/notification_service.dart';
import '../widgets/product_card.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'messages_inbox_screen.dart';
import 'special_markets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = MarketplaceService();
  final _search = TextEditingController();
  List<Category> _categories = [];
  List<Product> _products = [];
  Set<String> _favoriteIds = {};
  String? _categoryId;
  bool _loading = true;
  String? _error;
  Stream<List<Map<String, dynamic>>>? _notificationStream;

  void _bindNotificationStream() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _notificationStream = userId == null ? null : NotificationService().watchNotifications();
  }

  String get _firstName {
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = user?.userMetadata?['display_name']?.toString().trim();
    if (metadataName != null && metadataName.isNotEmpty) {
      return metadataName.split(RegExp(r'\s+')).first;
    }
    final emailName = user?.email?.split('@').first;
    return emailName == null || emailName.isEmpty ? 'بك' : emailName;
  }

  @override
  void initState() {
    super.initState();
    _bindNotificationStream();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await _service.getCategories();
      final products = await _service.getPublishedProducts(
        categoryId: _categoryId,
        query: _search.text,
      );
      var favoriteIds = <String>{};
      if (Supabase.instance.client.auth.currentUser != null) {
        try {
          favoriteIds = await FavoritesService().getFavoriteProductIds();
        } catch (_) {
          // Product discovery should remain available if favorites cannot load.
        }
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _products = products;
        _favoriteIds = favoriteIds;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    var user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted) return;
      user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
    }

    final wasFavorite = _favoriteIds.contains(product.id);
    try {
      final favorites = FavoritesService();
      if (wasFavorite) {
        await favorites.removeFavorite(product.id);
      } else {
        await favorites.addFavorite(product.id);
      }
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favoriteIds.remove(product.id);
        } else {
          _favoriteIds.add(product.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasFavorite
              ? 'تمت إزالة المنتج من المفضلة'
              : 'تمت إضافة المنتج للمفضلة'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث المفضلة: $error')),
      );
    }
  }

  Future<void> _openSell() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (mounted) _load();
  }

  Future<void> _openProfile() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
    if (mounted) {
      setState(_bindNotificationStream);
    }
  }

  Future<void> _openNotifications() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
      setState(_bindNotificationStream);
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> _openMessages() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MessagesInboxScreen()),
    );
  }

  List<Category> get _rootCategories =>
      _categories.where((category) => category.parentId == null).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Category> _childrenOf(String? parentId) => _categories
      .where((category) => category.parentId == parentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Widget _categoryTile(Category category, BuildContext sheetContext) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final children = _childrenOf(category.id);
    if (children.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.category_outlined),
        title: Text(category.nameFor(languageCode)),
        onTap: () => Navigator.pop(sheetContext, category.id),
      );
    }
    return ExpansionTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(category.nameFor(languageCode)),
      children: [
        ListTile(
          dense: true,
          title: Text('${category.nameFor(languageCode)} — ${AppStrings.of(context)!.allProducts}'),
          onTap: () => Navigator.pop(sheetContext, category.id),
        ),
        ...children.map((child) => _categoryTile(child, sheetContext)),
      ],
    );
  }

  Future<void> _openSpecialMarkets() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SpecialMarketsScreen(),
      ),
    );
  }

  Future<void> _openCategories() async {
    if (_rootCategories.isEmpty) {
      _showComingSoon(AppStrings.of(context)!.homeSections);
      return;
    }
    final selectedId = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              title: Text(AppStrings.of(context)!.homeSections),
              titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: Text(AppStrings.of(context)!.allProducts),
              onTap: () => Navigator.pop(sheetContext, ''),
            ),
            ..._rootCategories.map((category) => _categoryTile(category, sheetContext)),
          ],
        ),
      ),
    );
    if (selectedId == null || !mounted) return;
    setState(() => _categoryId = selectedId.isEmpty ? null : selectedId);
    await _load();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context)!.featureComingSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final colors = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلاً',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              user == null ? 'بك في كنزة هب' : _firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _notificationStream,
                        builder: (context, snapshot) {
                          final unread = (snapshot.data ?? [])
                              .where((item) => item['is_read'] != true)
                              .length;
                          return IconButton(
                            tooltip: 'الإشعارات',
                            onPressed: _openNotifications,
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_none_rounded, size: 27),
                                if (unread > 0)
                                  Positioned(
                                    top: -5,
                                    right: -7,
                                    child: Container(
                                      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(
                          query: _search.text.trim(),
                          categoryId: _categoryId,
                        ),
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'البحث بالصور',
                        onPressed: () => _showComingSoon('البحث بالصور'),
                        icon: const Icon(Icons.camera_alt_outlined),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Material(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openSpecialMarkets,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.storefront_outlined,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.of(context)!.specialMarketsTitle,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    AppStrings.of(context)!.specialMarketsSubtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.arrow_back_ios_new_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: colors.onSurface,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('الكل'),
                          selected: _categoryId == null,
                          onSelected: (_) {
                            setState(() => _categoryId = null);
                            _load();
                          },
                        ),
                      ),
                      ..._rootCategories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(category.nameFor(languageCode)),
                            selected: _categoryId == category.id,
                            onSelected: (_) {
                              setState(() => _categoryId = category.id);
                              _load();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'أحدث المنتجات',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        'تسوّق واكتشف',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 42),
                          const SizedBox(height: 12),
                          const Text('تعذر تحميل المنتجات'),
                          const SizedBox(height: 8),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('لا توجد منتجات منشورة حتى الآن')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _products[index];
                        return ProductCard(
                          product: product,
                          isFavorite: _favoriteIds.contains(product.id),
                          onFavoriteTap: () => _toggleFavorite(product),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(productId: product.id),
                              ),
                            );
                            if (mounted) _load();
                          },
                        );
                      },
                      childCount: _products.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'الأقسام'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded), selectedIcon: Icon(Icons.add_circle_rounded), label: 'إضافة منتج'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_rounded), label: 'الرسائل'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'حسابي'),
          ],
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                break;
              case 1:
                _openCategories();
                break;
              case 2:
                _openSell();
                break;
              case 3:
                _openMessages();
                break;
              case 4:
                _openProfile();
                break;
            }
          },
        ),
      ),
    );
  }
}
