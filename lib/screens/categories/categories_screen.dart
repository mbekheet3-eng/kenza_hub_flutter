import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/database_category.dart';
import '../../services/catalog_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CatalogService _catalogService = CatalogService();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late Future<List<DatabaseCategory>> _categoriesFuture;
  final List<DatabaseCategory> _path = [];

  static const Color _red = Color(0xFFC62828);
  static const Color _navy = Color(0xFF0F172A);
  static const Color _card = Color(0xFFEAF0F1);

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _catalogService.fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _path.clear();
      _categoriesFuture = _catalogService.fetchCategories();
    });
  }

  void _openCategory(
    DatabaseCategory category,
    List<DatabaseCategory> categories,
  ) {
    final hasChildren = categories.any((item) => item.parentId == category.id);
    if (hasChildren) {
      setState(() => _path.add(category));
      return;
    }

    context.push('/search?categoryId=${Uri.encodeQueryComponent(category.id)}');
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    context.push('/search?q=${Uri.encodeQueryComponent(query)}');
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
          content: Text(
            'تم اختيار الصورة. البحث بالصورة سيتاح بعد ربط خدمة البحث البصري.',
          ),
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

  IconData _iconFor(DatabaseCategory category) {
    final value = category.slug.toLowerCase();
    if (value.endsWith('-other')) return Icons.widgets_outlined;
    if (value.contains('kids') || value.contains('child')) {
      return Icons.toys_outlined;
    }
    if (value.contains('home') || value.contains('furniture')) {
      return Icons.chair_alt_outlined;
    }
    if (value.contains('shoe') || value.contains('sneaker')) {
      return Icons.directions_walk;
    }
    if (value.contains('clothes') || value.contains('dress') ||
        value.contains('shirt') || value.contains('women') ||
        value.contains('men')) {
      return Icons.checkroom_outlined;
    }
    if (value.contains('stroller') || value.contains('car-seat')) {
      return Icons.child_friendly_outlined;
    }
    if (value.contains('toy')) return Icons.toys_outlined;
    if (value.contains('kitchen') || value.contains('feeding')) {
      return Icons.kitchen_outlined;
    }
    if (value.contains('book') || value.contains('school')) {
      return Icons.menu_book_outlined;
    }
    if (value.contains('light')) return Icons.lightbulb_outline;
    if (value.contains('garden')) return Icons.yard_outlined;
    if (value.contains('textile') || value.contains('bedding')) {
      return Icons.bed_outlined;
    }
    if (value.contains('decor')) return Icons.brush_outlined;
    if (value.contains('appliance')) return Icons.kitchen_outlined;
    return Icons.category_outlined;
  }

  Color _accentFor(DatabaseCategory category, int index) {
    final value = category.slug.toLowerCase();
    if (value.endsWith('-other')) return const Color(0xFF64748B);
    if (value == 'clothes' || value.contains('clothes')) {
      return const Color(0xFFC62828);
    }
    if (value == 'shoes' || value.contains('shoes')) {
      return const Color(0xFF5367A5);
    }
    if (value.contains('kids')) return const Color(0xFFE58A38);
    if (value.contains('home')) return const Color(0xFF3D8C83);
    const palette = [
      Color(0xFFC62828),
      Color(0xFF5367A5),
      Color(0xFFE58A38),
      Color(0xFF3D8C83),
      Color(0xFF8B6BA8),
    ];
    return palette[index % palette.length];
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submitSearch(),
        decoration: InputDecoration(
          hintText: 'ابحث عن منتجات أو أعضاء',
          hintStyle: const TextStyle(color: Color(0xFF8A949B), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: _navy, size: 25),
          suffixIcon: IconButton(
            tooltip: 'البحث بالصورة',
            onPressed: _openVisualSearchPicker,
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: _red,
              size: 24,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFF3F6F7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: _red, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(String languageCode) {
    if (_path.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 2, 16, 10),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            'تصفح الأقسام',
            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: 'رجوع للقسم السابق',
            onPressed: () => setState(() => _path.removeLast()),
            icon: const Icon(Icons.arrow_back_rounded, color: _navy),
          ),
          Expanded(
            child: Text(
              _path.map((item) => item.labelFor(languageCode)).join('  /  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    DatabaseCategory category,
    List<DatabaseCategory> categories,
    int index,
    String languageCode,
  ) {
    final accent = _accentFor(category, index);
    final hasChildren = categories.any((item) => item.parentId == category.id);
    final title = category.labelFor(languageCode).trim();

    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openCategory(category, categories),
        child: Stack(
          children: [
            Positioned(
              top: 13,
              right: 13,
              left: 12,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Color(0xFF20272B),
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 10,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: category.iconUrl != null &&
                        category.iconUrl!.trim().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.network(
                          category.iconUrl!,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            _iconFor(category),
                            size: 37,
                            color: accent,
                          ),
                        ),
                      )
                    : Icon(
                        _iconFor(category),
                        size: 37,
                        color: accent,
                      ),
              ),
            ),
            if (hasChildren)
              Positioned(
                left: 9,
                bottom: 9,
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: accent.withOpacity(0.85),
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
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
            _BrowseNavItem(
              icon: Icons.home_outlined,
              label: 'الرئيسية',
              onTap: () => context.go('/home'),
            ),
            _BrowseNavItem(
              icon: Icons.search_rounded,
              label: 'اكتشف',
              selected: true,
              onTap: () => context.go('/categories'),
            ),
            _BrowseNavItem(
              icon: Icons.add_circle_outline_rounded,
              label: 'بيع منتج',
              onTap: () => context.push('/sell-wizard'),
            ),
            _BrowseNavItem(
              icon: Icons.shopping_cart_outlined,
              label: 'سلة المشتريات',
              onTap: () => context.push('/cart'),
            ),
            _BrowseNavItem(
              icon: Icons.person_outline_rounded,
              label: 'حسابي',
              onTap: () => context.push('/profile'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            FutureBuilder<List<DatabaseCategory>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_outlined, size: 42),
                            const SizedBox(height: 12),
                            const Text('تعذر تحميل الأقسام'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final categories =
                    snapshot.data ?? const <DatabaseCategory>[];
                final currentParent = _path.isEmpty ? null : _path.last;
                final visibleCategories = categories
                    .where((item) => item.parentId == currentParent?.id)
                    .toList()
                  ..sort((a, b) {
                    final order = a.displayOrder.compareTo(b.displayOrder);
                    return order != 0 ? order : a.nameAr.compareTo(b.nameAr);
                  });

                if (categories.isEmpty) {
                  return const Expanded(
                    child: Center(child: Text('لا توجد أقسام متاحة حاليًا')),
                  );
                }

                return Expanded(
                  child: Column(
                    children: [
                      _buildBreadcrumb(languageCode),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                          itemCount: visibleCategories.length,
                          itemBuilder: (context, index) =>
                              _buildCategoryCard(
                            visibleCategories[index],
                            categories,
                            index,
                            languageCode,
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
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}

class _BrowseNavItem extends StatelessWidget {
  const _BrowseNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFC62828) : const Color(0xFF0F172A);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 27),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
