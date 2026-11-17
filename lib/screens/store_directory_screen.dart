import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class StoreDirectoryScreen extends StatefulWidget {
  const StoreDirectoryScreen({
    super.key,
    required this.storeType,
    required this.title,
  });

  final String storeType;
  final String title;

  @override
  State<StoreDirectoryScreen> createState() => _StoreDirectoryScreenState();
}

class _StoreDirectoryScreenState extends State<StoreDirectoryScreen> {
  final _service = MarketplaceService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _stores = [];

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
      final stores = await _service.getActiveStoresByType(widget.storeType);
      if (!mounted) return;
      setState(() => _stores = stores);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 100),
                    Center(child: Text(strings.homeProductsLoadError)),
                    const SizedBox(height: 8),
                    Center(child: Text(_error!, textAlign: TextAlign.center)),
                    Center(child: TextButton(onPressed: _load, child: Text(strings.retryAction))),
                  ])
                : _stores.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 140),
                        Center(child: Text(strings.noPublishedProducts)),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stores.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final store = _stores[index];
                          final logo = store['logo_url'] as String?;
                          final banner = store['banner_url'] as String?;
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StorefrontScreen(store: store),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (banner != null && banner.isNotEmpty)
                                    Image.network(
                                      banner,
                                      height: 112,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox(height: 12),
                                    ),
                                  ListTile(
                                    leading: CircleAvatar(
                                      radius: 27,
                                      backgroundImage: logo == null || logo.isEmpty ? null : NetworkImage(logo),
                                      child: logo == null || logo.isEmpty
                                          ? const Icon(Icons.storefront_outlined)
                                          : null,
                                    ),
                                    title: Text(
                                      store['store_name'] as String? ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    subtitle: Text(
                                      (store['description'] as String?)?.trim().isNotEmpty == true
                                          ? (store['description'] as String).trim()
                                          : strings.sellerOnKenza,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class StorefrontScreen extends StatefulWidget {
  const StorefrontScreen({super.key, required this.store});

  final Map<String, dynamic> store;

  @override
  State<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends State<StorefrontScreen> {
  final _service = MarketplaceService();
  bool _loading = true;
  String? _error;
  List<Product> _products = [];

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
      final products = await _service.getPublishedProductsBySeller(
        widget.store['owner_id'] as String,
      );
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
    final strings = AppStrings.of(context)!;
    final logo = widget.store['logo_url'] as String?;
    final banner = widget.store['banner_url'] as String?;
    final description = (widget.store['description'] as String?)?.trim() ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(widget.store['store_name'] as String? ?? '')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (banner != null && banner.isNotEmpty)
                    Image.network(
                      banner,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 12),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundImage: logo == null || logo.isEmpty ? null : NetworkImage(logo),
                          child: logo == null || logo.isEmpty
                              ? const Icon(Icons.storefront_outlined, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.store['store_name'] as String? ?? '',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(description),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(strings.homeProductsLoadError),
                      TextButton(onPressed: _load, child: Text(strings.retryAction)),
                    ],
                  ),
                ),
              )
            else if (_products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(strings.noPublishedProducts)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
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
