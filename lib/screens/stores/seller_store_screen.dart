import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/product.dart';
import '../../services/seller_directory_service.dart';

class SellerStoreScreen extends StatefulWidget {
  const SellerStoreScreen({
    super.key,
    required this.sellerProfileId,
    required this.agency,
  });

  final String sellerProfileId;
  final bool agency;

  @override
  State<SellerStoreScreen> createState() => _SellerStoreScreenState();
}

class _SellerStoreScreenState extends State<SellerStoreScreen> {
  final SellerDirectoryService _service = SellerDirectoryService();
  late Future<_StorePageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StorePageData> _load() async {
    final profile = await _service.loadStore(
      id: widget.sellerProfileId,
      agency: widget.agency,
    );
    if (profile == null) throw StateError('المتجر غير متاح');
    final products = await _service.loadStoreProducts(widget.sellerProfileId);
    return _StorePageData(profile: profile, products: products);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.agency ? 'ركن الوكالة' : 'Online Store')),
      body: FutureBuilder<_StorePageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store_mall_directory_outlined, size: 52),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context).sellerStoreLoadError),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _refresh, child: Text(AppLocalizations.of(context).retry)),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final profile = data.profile;
          final name = (profile['business_name'] ?? profile['display_name'] ?? 'متجر')
              .toString();
          final cover = profile['cover_image_url'] as String?;
          final canShowCover = !widget.agency || profile['show_storefront'] == true;
          final avatar = profile['avatar_url'] as String?;
          final links = profile['social_links'] is Map
              ? Map<String, dynamic>.from(profile['social_links'] as Map)
              : <String, dynamic>{};

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (canShowCover && cover != null && cover.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: cover,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox(height: 12),
                        )
                      else
                        Container(
                          height: 120,
                          width: double.infinity,
                          color: const Color(0xFFF1F2F6),
                          child: Icon(
                            widget.agency
                                ? Icons.storefront_outlined
                                : Icons.shopping_bag_outlined,
                            size: 46,
                            color: Colors.black38,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage:
                                  avatar != null && avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : null,
                              child: avatar == null || avatar.isEmpty
                                  ? const Icon(Icons.store, size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (profile['verification_status'] == 'verified')
                              const Icon(Icons.verified, color: Color(0xFF2E7D32)),
                          ],
                        ),
                      ),
                      if ((profile['bio'] as String?)?.trim().isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Text(profile['bio'] as String),
                        ),
                      if (widget.agency && (profile['shop_area'] as String?)?.isNotEmpty == true)
                        _InfoLine(icon: Icons.location_on_outlined,
                            text: 'المنطقة: ${profile['shop_area']}'),
                      if (links.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: Wrap(
                            spacing: 8,
                            children: links.entries.map((entry) => ActionChip(
                              avatar: Icon(_socialIcon(entry.key), size: 17),
                              label: Text(_socialLabel(entry.key)),
                              onPressed: () => _openLink(entry.value.toString()),
                            )).toList(),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(AppLocalizations.of(context).storeProducts,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                if (data.products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(AppLocalizations.of(context).noStoreProducts)),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _StoreProductCard(
                          product: data.products[index],
                          onTap: () => context.push('/product/${data.products[index].id}'),
                        ),
                        childCount: data.products.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  IconData _socialIcon(String key) {
    switch (key) {
      case 'facebook': return Icons.facebook;
      case 'instagram': return Icons.camera_alt_outlined;
      case 'whatsapp': return Icons.chat_outlined;
      default: return Icons.language;
    }
  }

  String _socialLabel(String key) {
    switch (key) {
      case 'facebook': return 'Facebook';
      case 'instagram': return 'Instagram';
      case 'whatsapp': return 'WhatsApp';
      default: return 'الموقع';
    }
  }
}

class _StorePageData {
  const _StorePageData({
    required this.profile,
    required this.products,
  });

  final Map<String, dynamic> profile;
  final List<Product> products;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _StoreProductCard extends StatelessWidget {
  const _StoreProductCard({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: product.primaryImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.primaryImage,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      )
                    : const Center(child: Icon(Icons.image_outlined, size: 40)),
              ),
              Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(product.priceDisplay,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            color: Color(0xFFC62828))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
