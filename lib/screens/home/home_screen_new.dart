import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:kenza_hub_flutter/models/database_category.dart';
import 'package:kenza_hub_flutter/models/product.dart';
import 'package:kenza_hub_flutter/providers/home_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<DatabaseCategory> _categories = const [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<HomeProvider>().initialize();
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await Supabase.instance.client
          .from('categories')
          .select('id,name_ar,name_en,slug,icon,icon_url,parent_id')
          .eq('is_active', true)
          .order('name_ar');
      final categories = (rows as List)
          .map((row) => DatabaseCategory.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          // The strip is for product types below the four main categories.
          .where((category) => category.parentId != null)
          .toList()
        ..sort((a, b) {
          int priority(String slug) {
            if (slug == 'clothes-women-dresses') return 0;
            if (slug == 'clothes-women-evening-dresses') return 1;
            return 2;
          }

          final priorityCompare = priority(a.slug).compareTo(priority(b.slug));
          return priorityCompare != 0
              ? priorityCompare
              : a.nameAr.compareTo(b.nameAr);
        });
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
        _categoriesError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _categoriesLoading = false;
        _categoriesError = error.toString();
      });
    }
  }

  String get _memberFirstName {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final firstName = (metadata['first_name'] ?? '').toString().trim();
    if (firstName.isNotEmpty) return firstName;
    final fullName = (metadata['full_name'] ?? metadata['name'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName.split(RegExp(r'\s+')).first;
    final email = user?.email ?? '';
    return email.contains('@') ? email.split('@').first : 'عضو كنزة';
  }

  Future<void> _openVisualSearchPicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار صورة من المعرض'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم اختيار الصورة. البحث بالصورة سيتاح بعد ربط خدمة البحث البصري.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الصورة. تحقق من صلاحية الكاميرا أو المعرض.'),
        ),
      );
    }
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    context.push('/search?q=${Uri.encodeQueryComponent(query)}');
  }

  void _openCategory(DatabaseCategory category) {
    context.push('/search?categoryId=${Uri.encodeQueryComponent(category.id)}');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 62,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 18,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'أهلاً',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _memberFirstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'الإشعارات',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('مركز الإشعارات قيد التجهيز.')),
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0F172A),
                size: 27,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar(strings, homeProvider)),
              SliverToBoxAdapter(child: _buildCategoryStrip()),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: _PromoCarousel()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'أحدث المنتجات',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${homeProvider.productCount} منتج',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (homeProvider.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (homeProvider.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _HomeMessage(
                    icon: Icons.cloud_off_outlined,
                    message: 'تعذر تحميل المنتجات',
                    actionLabel: 'إعادة المحاولة',
                    onAction: homeProvider.retry,
                  ),
                )
              else if (homeProvider.filteredProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _HomeMessage(
                    icon: Icons.shopping_bag_outlined,
                    message: strings.noProducts,
                    actionLabel: 'عرض الكل',
                    onAction: homeProvider.clearFilters,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = homeProvider.filteredProducts[index];
                        return _HomeProductCard(
                          product: product,
                          onTap: () => context.push('/product/${product.id}'),
                        );
                      },
                      childCount: homeProvider.filteredProducts.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: const _HomeBottomNavigation(),
    );
  }

  Widget _buildSearchBar(
    AppLocalizations strings,
    HomeProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submitSearch(),
              onChanged: (value) {
                provider.search(value);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: strings.searchProduct,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                // In RTL, prefix is on the right and suffix is on the left.
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF0F172A),
                  size: 27,
                ),
                suffixIcon: IconButton(
                  tooltip: 'البحث بالصورة',
                  onPressed: _openVisualSearchPicker,
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF0F172A),
                    size: 25,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: Color(0xFFC62828),
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStrip() {
    final locale = Localizations.localeOf(context).languageCode;
    if (_categoriesLoading) {
      return const SizedBox(
        height: 112,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_categoriesError != null) {
      return SizedBox(
        height: 82,
        child: Center(
          child: TextButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('تعذر تحميل الأصناف — إعادة المحاولة'),
          ),
        ),
      );
    }
    if (_categories.isEmpty) return const SizedBox(height: 12);

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _CategoryItem(
            category: category,
            title: category.labelFor(locale).isNotEmpty
                ? category.labelFor(locale)
                : category.nameAr,
            onTap: () => _openCategory(category),
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.title,
    required this.onTap,
  });

  final DatabaseCategory category;
  final String title;
  final VoidCallback onTap;

  IconData _iconForSlug(String slug) {
    final value = slug.toLowerCase();
    if (value.contains('dress') || value.contains('fustan')) return Icons.checkroom;
    if (value.contains('shoe') || value.contains('boot')) return Icons.directions_walk;
    if (value.contains('shirt') || value.contains('top')) return Icons.checkroom;
    if (value.contains('bag')) return Icons.shopping_bag_outlined;
    if (value.contains('baby') || value.contains('child') || value.contains('kids')) return Icons.child_friendly_outlined;
    if (value.contains('kitchen')) return Icons.restaurant_outlined;
    if (value.contains('furniture') || value.contains('sofa')) return Icons.chair_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              height: 70,
              width: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F6),
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: category.iconUrl != null && category.iconUrl!.isNotEmpty
                  ? Image.network(
                      category.iconUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        _iconForSlug(category.slug),
                        color: const Color(0xFF0F172A),
                        size: 32,
                      ),
                    )
                  : Icon(
                      _iconForSlug(category.slug),
                      color: const Color(0xFF0F172A),
                      size: 32,
                    ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  static const _promos = [
    _PromoData(
      title: 'فساتين لكل مناسبة',
      subtitle: 'اكتشفي فساتين جديدة للبيع على كنزة هب',
      icon: Icons.checkroom_outlined,
      background: Color(0xFFF7E9E7),
      accent: Color(0xFFC62828),
      categoryId: '6731ec75-9d3c-4c2b-be6b-eee1a8a32cef',
    ),
    _PromoData(
      title: 'لو مش محتاجها... غيرك محتاجها',
      subtitle: 'بيع واشتري بسهولة من غير عمولة',
      icon: Icons.shopping_bag_outlined,
      background: Color(0xFFF7E9E7),
      accent: Color(0xFFC62828),
    ),
    _PromoData(
      title: 'اختيارات كتير في مكان واحد',
      subtitle: 'اكتشف منتجات جديدة كل يوم',
      icon: Icons.auto_awesome_outlined,
      background: Color(0xFFE8EEF8),
      accent: Color(0xFF0F2B55),
    ),
    _PromoData(
      title: 'كل اللي محتاجه تلاقيه هنا',
      subtitle: 'تصفح الأصناف واختار اللي يناسبك',
      icon: Icons.storefront_outlined,
      background: Color(0xFFF4EEE3),
      accent: Color(0xFFC62828),
    ),
    _PromoData(
      title: 'ركن الوكالة',
      subtitle: 'محلات فعلية وأسواق وكالة البلح',
      icon: Icons.storefront_outlined,
      background: Color(0xFFF4EEE3),
      accent: Color(0xFF9A5B2A),
      route: '/agency-corner',
    ),
    _PromoData(
      title: 'Social Corner',
      subtitle: 'متاجر وصفحات البيع أونلاين',
      icon: Icons.shopping_bag_outlined,
      background: Color(0xFFE8EEF8),
      accent: Color(0xFF5367A5),
      route: '/online-stores',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      _index = (_index + 1) % _promos.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 142,
          child: PageView.builder(
            controller: _controller,
            itemCount: _promos.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return GestureDetector(
                onTap: promo.route != null
                    ? () => context.push(promo.route!)
                    : promo.categoryId != null
                        ? () => context.push(
                              '/search?categoryId=${Uri.encodeQueryComponent(promo.categoryId!)}',
                            )
                        : null,
                child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: promo.background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: promo.accent,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            promo.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Icon(
                        promo.icon,
                        size: 76,
                        color: promo.accent.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promos.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _index == index ? 18 : 6,
              decoration: BoxDecoration(
                color: _index == index
                    ? const Color(0xFFC62828)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoData {
  const _PromoData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.accent,
    this.categoryId,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color accent;
  final String? categoryId;
  final String? route;
}

class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFF0F1F4),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: Color(0xFF94A3B8),
                              size: 36,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF94A3B8),
                            size: 36,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_border, size: 16, color: Color(0xFF0F172A)),
                          const SizedBox(width: 4),
                          Text(
                            product.likes.toString(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if ((product.size ?? '').isNotEmpty) 'مقاس ${product.size}',
                      if (product.condition.isNotEmpty) product.condition,
                    ].join(' • ').isEmpty
                        ? 'متاح'
                        : [
                            if ((product.size ?? '').isNotEmpty) 'مقاس ${product.size}',
                            if (product.condition.isNotEmpty) product.condition,
                          ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.priceDisplay,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBottomNavigation extends StatelessWidget {
  const _HomeBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 7, 4, 5),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'الرئيسية',
              selected: true,
              onTap: () => context.go('/home'),
            ),
            _NavItem(
              icon: Icons.search_rounded,
              label: 'اكتشف',
              onTap: () => context.push('/categories'),
            ),
            _NavItem(
              icon: Icons.add_circle_rounded,
              label: 'بيع منتج',
              emphasized: true,
              onTap: () => context.push('/sell-wizard'),
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'الرسائل',
              onTap: () => context.push('/chats'),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'حسابي',
              onTap: () => context.push('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = selected || emphasized
        ? const Color(0xFFC62828)
        : const Color(0xFF0F172A);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: emphasized ? 35 : 27),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: selected || emphasized
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
