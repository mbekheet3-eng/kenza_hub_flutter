import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';
import '../widgets/member_avatar.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key, required this.sellerId});

  final String sellerId;

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final _service = MarketplaceService();
  Map<String, dynamic>? _profile;
  List<Product> _products = [];
  int _productCount = 0;
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
      final results = await Future.wait<dynamic>([
        _service.getPublicMemberProfile(widget.sellerId),
        _service.getPublishedProductsBySeller(widget.sellerId),
        _service.getPublishedProductCountBySeller(widget.sellerId),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _products = results[1] as List<Product>;
        _productCount = results[2] as int;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    final sellerName = (_profile?['first_name'] as String?)?.trim();
    return Scaffold(
      appBar: AppBar(title: Text(strings.sellerOnKenza)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(strings.sellerStoreLoadError),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(strings.retryAction),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          child: Row(
                            children: [
                              MemberAvatar(
                                avatarUrl: _profile?['avatar_url'] as String?,
                                radius: 38,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sellerName?.isNotEmpty == true
                                          ? sellerName!
                                          : strings.memberFallbackName,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(strings.sellerOnKenza),
                                    const SizedBox(height: 5),
                                    Text(
                                      '$_productCount ${strings.productsCount}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: _products.isEmpty
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(child: Text(strings.noPublishedProducts)),
                              )
                            : SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.68,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final product = _products[index];
                                    return ProductCard(
                                      product: product,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(productId: product.id),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: _products.length,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
