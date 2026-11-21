import 'dart:async';
import '../widgets/kenza_asset_icon.dart';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';
import '../services/favorites_service.dart';
import '../services/notification_service.dart';
import '../widgets/product_card.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = MarketplaceService();
  final _notificationService = NotificationService();
  late Stream<List<Map<String, dynamic>>> _notificationStream;
  late final StreamSubscription<AuthState> _authSubscription;
  final _search = TextEditingController();
  List<Category> _categories = [];
  List<Product> _products = [];
  Set<String> _favoriteIds = {};
  String? _categoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notificationStream = _currentNotificationStream();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() {
        _notificationStream = state.session == null
            ? Stream.value(const <Map<String, dynamic>>[])
            : _notificationService.watchNotifications();
      });
    });
    _load();
  }

  Stream<List<Map<String, dynamic>>> _currentNotificationStream() {
    return Supabase.instance.client.auth.currentUser == null
        ? Stream.value(const <Map<String, dynamic>>[])
        : _notificationService.watchNotifications();
  }

  Future<void> _openNotifications() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const FractionallySizedBox(
          heightFactor: 0.94,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            child: LoginScreen(),
          ),
        ),
      );
      if (!mounted || Supabase.instance.client.auth.currentUser == null) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
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
              : AppStrings.of(context)!.favoriteAdded),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(context)!.favoriteUpdateFailed}: $error')),
      );
    }
  }


  List<Category> get _rootCategories =>
      _categories.where((category) => category.parentId == null).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Future<void> _showImageSearchOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(AppStrings.of(context)!.imageTakeCamera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppStrings.of(context)!.imagePickGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null && mounted) {
      await _startImageSearch(source);
    }
  }

  Future<void> _startImageSearch(ImageSource source) async {
    var loadingDialogOpen = false;
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image == null || !mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(AppStrings.of(dialogContext)!.imageSearch)),
            ],
          ),
        ),
      );
      loadingDialogOpen = true;

      final query = await _service.analyzeImageForSearch(image);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      loadingDialogOpen = false;

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SearchScreen(query: query)),
      );
    } catch (error) {
      if (!mounted) return;
      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      final strings = AppStrings.of(context)!;
      final message = error is ImageSearchUnavailableException
          ? strings.imageSearchTemporarilyUnavailable
          : strings.searchLoadError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _homeGreeting(String languageCode) {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final displayName = metadata?['display_name'] as String?;
    final trimmedName = displayName?.trim();
    final firstName = trimmedName == null || trimmedName.isEmpty
        ? null
        : trimmedName.split(RegExp(r'\s+')).first;

    if (languageCode == 'ar') {
      return firstName == null ? 'أهلاً' : 'أهلاً $firstName';
    }
    if (languageCode == 'fr') {
      return firstName == null ? 'Bonjour' : 'Bonjour $firstName';
    }
    return firstName == null ? 'Hello' : 'Hello $firstName';
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _homeGreeting(languageCode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _notificationStream,
                        builder: (context, snapshot) {
                          final unreadCount = (snapshot.data ?? const [])
                              .where((notification) => notification['is_read'] != true)
                              .length;
                          return IconButton(
                            tooltip: AppStrings.of(context)!.notificationsTitle,
                            onPressed: _openNotifications,
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset(
                                  'assets/notification.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                                if (unreadCount > 0)
                                  PositionedDirectional(
                                    top: -3,
                                    end: -4,
                                    child: Container(
                                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onError,
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
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
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
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: KenzaAssetIcon('assets/brows.png', size: 22, scale: 1.3),
                      ),
                      suffixIcon: IconButton(
                        tooltip: AppStrings.of(context)!.imageSearch,
                        onPressed: _showImageSearchOptions,
                        icon: KenzaAssetIcon('assets/icons/camera.png', size: 24, scale: 1.3),
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
                          Text(_error!, textAlign: TextAlign.center),
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
                  child: Center(child: Text(AppStrings.of(context)!.noPublishedProducts)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
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
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }
}
