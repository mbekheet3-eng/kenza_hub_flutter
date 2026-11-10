import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/favorites_service.dart';
import '../services/marketplace_service.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favorites = FavoritesService();
  final _marketplace = MarketplaceService();
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ids = await _favorites.getFavoriteProductIds();
      final products = ids.isEmpty
          ? <Product>[]
          : await _marketplace.getProductsByIds(ids.toList());
      if (!mounted) return;
      setState(() => _products = products);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(Product product) async {
    try {
      await _favorites.removeFavorite(product.id);
      if (!mounted) return;
      setState(() => _products.removeWhere((item) => item.id == product.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.favoriteRemoved)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.favoriteUpdateError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context)!.favoritesTitle)),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppStrings.of(context)!.favoriteLoadError),
                        const SizedBox(height: 8),
                        Text(AppStrings.of(context)!.favoriteLoadError, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(AppStrings.of(context)!.retryAction),
                        ),
                      ],
                    ),
                  ),
                )
              : _products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_border_rounded, size: 56),
                            SizedBox(height: 12),
                            Text(AppStrings.of(context)!.emptyFavorites),
                            SizedBox(height: 6),
                            Text(AppStrings.of(context)!.favoriteHint),
                            ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ProductCard(
                            product: product,
                            isFavorite: true,
                            onFavoriteTap: () => _remove(product),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(productId: product.id),
                              ),
                            ).then((_) => _load()),
                          );
                        },
                      ),
                    ),
    );
  }
}
