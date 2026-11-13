import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
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
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  Set<String> _favoriteIds = {};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  String _sort = 'relevance';
  RangeValues _priceRange = const RangeValues(0, 100000);
  bool _filterPrice = false;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.query);
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loading || _loadingMore || !_hasMore) {
      return;
    }
    if (_scrollController.position.extentAfter < 400) {
      _load(append: true);
    }
  }

  Future<void> _load({bool append = false}) async {
    if (append && (_loadingMore || !_hasMore)) return;
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
        _hasMore = false;
      });
    }

    try {
      final page = await _service.searchProducts(
        categoryId: widget.categoryId,
        query: _query.text.trim(),
        minPrice: _filterPrice ? _priceRange.start : null,
        maxPrice: _filterPrice ? _priceRange.end : null,
        sort: _sort,
        limit: 20,
        offset: append ? _products.length : 0,
      );

      var favoriteIds = _favoriteIds;
      if (Supabase.instance.client.auth.currentUser != null) {
        try {
          favoriteIds = await FavoritesService().getFavoriteProductIds();
        } catch (_) {
          // Search remains available if favorites cannot be loaded.
        }
      }

      if (!mounted) return;
      setState(() {
        if (append) {
          final existingIds = _products.map((product) => product.id).toSet();
          _products = [
            ..._products,
            ...page.products.where((product) => !existingIds.contains(product.id)),
          ];
        } else {
          _products = page.products;
        }
        _favoriteIds = favoriteIds;
        _hasMore = page.hasMore;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.favoriteUpdateError)),
      );
    }
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
                Text(
                  AppStrings.of(context)!.priceRangeTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 12),
                Text(
                  '${draft.start.round()} - ${draft.end.round()} ${AppStrings.of(context)!.currency}',
                ),
                RangeSlider(
                  values: draft,
                  min: 0,
                  max: 100000,
                  divisions: 100,
                  onChanged: (value) => setSheetState(() => draft = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: enabled,
                  onChanged: (value) => setSheetState(() => enabled = value),
                  title: Text(AppStrings.of(context)!.enablePriceFilter),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, (draft, enabled)),
                    child: Text(AppStrings.of(context)!.applyPriceFilter),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _priceRange = result.$1;
        _filterPrice = result.$2;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(strings.searchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: strings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _query.clear();
                    _load();
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sort,
                    decoration: InputDecoration(labelText: strings.sortByLabel),
                    items: [
                      DropdownMenuItem(
                        value: 'relevance',
                        child: Text(strings.relevanceLabel),
                      ),
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text(strings.newestLabel),
                      ),
                      DropdownMenuItem(
                        value: 'price_low',
                        child: Text(strings.priceLowLabel),
                      ),
                      DropdownMenuItem(
                        value: 'price_high',
                        child: Text(strings.priceHighLabel),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _sort = value ?? 'relevance');
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _showPriceFilter,
                  icon: const Icon(Icons.tune),
                  label: Text(
                    _filterPrice ? strings.priceFilterEnabled : strings.priceFilterLabel,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(strings.searchLoadError, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _load,
                                child: Text(strings.retryAction),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _products.isEmpty
                        ? Center(child: Text(strings.noResults))
                        : GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _products.length + (_loadingMore ? 1 : 0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.68,
                            ),
                            itemBuilder: (context, index) {
                              if (index >= _products.length) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final product = _products[index];
                              return ProductCard(
                                product: product,
                                isFavorite: _favoriteIds.contains(product.id),
                                onFavoriteTap: () => _toggleFavorite(product),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(productId: product.id),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
