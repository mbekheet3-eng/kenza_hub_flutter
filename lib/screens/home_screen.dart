import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      return metadataName.split(RegExp(r'\\s+')).first;
    }
    final emailName = user?.email?.split('@').first;
    return emailName == null || emailName.isEmpty ? AppStrings.of(context)!.greetingFallback : emailName;
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
              ? AppStrings.of(context)!.favoriteRemoved
              : AppStrings.of(context)!.favoriteAddedToast),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.favoriteUpdateError)),
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

  Future<void> _openCategories() async {
    if (_categories.isEmpty) {
      _showComingSoon(AppStrings.of(context)!.homeSections);
      return;
    }
    final selectedId = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
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
            ..._categories.map(
              (category) => ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(category.nameFor(Localizations.localeOf(context).languageCode)),
                onTap: () => Navigator.pop(sheetContext, category.id),
              ),
            ),
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
                              AppStrings.of(context)!.welcomeGreeting,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              user == null ? AppStrings.of(context)!.welcomeGuest : _firstName,
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
                            tooltip: AppStrings.of(context)!.notificationsTitle,
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
                      hintText: AppStrings.of(context)!.searchProductHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: AppStrings.of(context)!.imageSearch,
                        onPressed: () => _showComingSoon(AppStrings.of(context)!.imageSearch),
                        icon: const Icon(Icons.camera_alt_outlined),
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
                          label: Text(AppStrings.of(context)!.allLabel),
                          selected: _categoryId == null,
                          onSelected: (_) {
                            setState(() => _categoryId = null);
                            _load();
                          },
                        ),
                      ),
                      ..._categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(category.nameFor(Localizations.localeOf(context).languageCode)),
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
                          AppStrings.of(context)!.latestProducts,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        AppStrings.of(context)!.discoverAndShop,
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
                          Text(AppStrings.of(context)!.homeProductsLoadError),
                          const SizedBox(height: 8),
                          Text(AppStrings.of(context)!.homeProductsLoadError, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: Text(AppStrings.of(context)!.retryAction),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(AppStrings.of(context)!.noProducts)),
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
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: AppStrings.of(context)!.mainHome),
            NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view_rounded), label: AppStrings.of(context)!.homeSections),
            NavigationDestination(icon: const Icon(Icons.add_circle_outline_rounded), selectedIcon: const Icon(Icons.add_circle_rounded), label: AppStrings.of(context)!.addProduct),
            NavigationDestination(icon: const Icon(Icons.chat_bubble_outline_rounded), selectedIcon: const Icon(Icons.chat_rounded), label: AppStrings.of(context)!.messages),
            NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: AppStrings.of(context)!.accountTab),
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
