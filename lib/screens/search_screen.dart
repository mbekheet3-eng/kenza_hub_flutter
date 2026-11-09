import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../services/marketplace_service.dart';
import '../services/favorites_service.dart';
import 'login_screen.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.query = '', this.categoryId});
  final String query;
  final String? categoryId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = MarketplaceService();
  late final TextEditingController _query;
  List<Product> _products = [];
  Set<String> _favoriteIds = {};
  bool _loading = true;
  String? _error;
  String _sort = 'newest';
  RangeValues _priceRange = const RangeValues(0, 100000);
  bool _filterPrice = false;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.query);
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await _service.getPublishedProducts(
        categoryId: widget.categoryId,
        query: _query.text.trim(),
        limit: 100,
      );
      var favoriteIds = <String>{};
      if (Supabase.instance.client.auth.currentUser != null) {
        try {
          favoriteIds = await FavoritesService().getFavoriteProductIds();
        } catch (_) {
          // Keep search results usable if the favorites request fails.
        }
      }
      if (!mounted) return;
      setState(() {
        _products = results;
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

  List<Product> get _visibleProducts {
    final results = _products.where((product) {
      if (!_filterPrice) return true;
      return product.price >= _priceRange.start && product.price <= _priceRange.end;
    }).toList();
    switch (_sort) {
      case 'price_low': results.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'price_high': results.sort((a, b) => b.price.compareTo(a.price)); break;
      default: results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return results;
  }

  Future<void> _showPriceFilter() async {
    var draft = _priceRange;
    var enabled = _filterPrice;
    final result = await showModalBottomSheet<(RangeValues, bool)>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نطاق السعر بالجنيه المصري', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 12),
                Text('${draft.start.round()} - ${draft.end.round()} ج.م'),
                RangeSlider(
                  values: draft, min: 0, max: 100000, divisions: 100,
                  onChanged: (value) => setSheetState(() => draft = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero, value: enabled,
                  onChanged: (value) => setSheetState(() => enabled = value),
                  title: const Text('تفعيل فلتر السعر'),
                ),
                SizedBox(width: double.infinity, child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, (draft, enabled)),
                  child: const Text('تطبيق'),
                )),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() { _priceRange = result.$1; _filterPrice = result.$2; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    return Scaffold(
      appBar: AppBar(title: const Text('البحث عن المنتجات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _query, textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج', prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(onPressed: () { _query.clear(); _load(); }, icon: const Icon(Icons.close)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: _sort,
                decoration: const InputDecoration(labelText: 'ترتيب حسب'),
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('الأحدث')),
                  DropdownMenuItem(value: 'price_low', child: Text('السعر: الأقل أولاً')),
                  DropdownMenuItem(value: 'price_high', child: Text('السعر: الأعلى أولاً')),
                ],
                onChanged: (value) => setState(() => _sort = value ?? 'newest'),
              )),
              const SizedBox(width: 10),
              OutlinedButton.icon(onPressed: _showPriceFilter, icon: const Icon(Icons.tune), label: Text(_filterPrice ? 'السعر مفعّل' : 'السعر')),
            ]),
          ),
          Expanded(
            child: _loading ? const Center(child: CircularProgressIndicator())
                : _error != null ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('تعذر تحميل نتائج البحث'), const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                    ]),
                  ))
                : products.isEmpty ? const Center(child: Text('لا توجد نتائج مطابقة'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12), itemCount: products.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.68,
                    ),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        isFavorite: _favoriteIds.contains(product.id),
                        onFavoriteTap: () => _toggleFavorite(product),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(productId: product.id),
                        )),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
