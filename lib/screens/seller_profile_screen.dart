import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Map<String, dynamic>? _details;
  List<Product> _products = [];
  int _productCount = 0;
  bool _loading = true;
  bool _savingLocation = false;
  String? _error;
  bool get _isOwnProfile => Supabase.instance.client.auth.currentUser?.id == widget.sellerId;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final values = await Future.wait<dynamic>([
        _service.getPublicMemberProfile(widget.sellerId),
        _service.getPublishedProductsBySeller(widget.sellerId),
        _service.getPublishedProductCountBySeller(widget.sellerId),
        _service.getSellerPublicDetails(widget.sellerId),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = values[0] as Map<String, dynamic>?;
        _products = values[1] as List<Product>;
        _productCount = values[2] as int;
        _details = values[3] as Map<String, dynamic>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editLocation() async {
    final strings = AppStrings.of(context)!;
    final location = _details?['location'] as Map<String, dynamic>?;
    final governorate = TextEditingController(text: location?['governorate'] as String? ?? '');
    final city = TextEditingController(text: location?['city'] as String? ?? '');
    final area = TextEditingController(text: location?['area'] as String? ?? '');
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.sellerLocationTitle),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(strings.sellerLocationPrivacy),
          const SizedBox(height: 10),
          TextField(controller: governorate, maxLength: 80, decoration: InputDecoration(labelText: strings.sellerLocationGovernorate)),
          TextField(controller: city, maxLength: 100, decoration: InputDecoration(labelText: strings.sellerLocationCity)),
          TextField(controller: area, maxLength: 100, decoration: InputDecoration(labelText: strings.sellerLocationAreaOptional)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(strings.cancelLabel)),
          if (location != null)
            TextButton(onPressed: () => Navigator.pop(dialogContext, {'action': 'hide'}), child: Text(strings.sellerLocationHide)),
          FilledButton(
            onPressed: () {
              if (governorate.text.trim().length < 2 || city.text.trim().length < 2) return;
              Navigator.pop(dialogContext, {
                'action': 'save', 'governorate': governorate.text.trim(),
                'city': city.text.trim(), 'area': area.text.trim(),
              });
            },
            child: Text(strings.sellerLocationSave),
          ),
        ],
      ),
    );
    governorate.dispose(); city.dispose(); area.dispose();
    if (result == null) return;
    setState(() => _savingLocation = true);
    try {
      if (result['action'] == 'hide') {
        await _service.removeSellerPublicLocation();
      } else {
        await _service.saveSellerPublicLocation(
          governorate: result['governorate']!, city: result['city']!, area: result['area'],
        );
      }
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.sellerLocationSaved)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.sellerLocationSaveFailed)));
    } finally {
      if (mounted) setState(() => _savingLocation = false);
    }
  }

  Widget _badge(String type, AppStrings strings) {
    final label = switch (type) {
      'phone' => strings.verifiedPhoneBadge,
      'identity' => strings.verifiedIdentityBadge,
      'store' => strings.verifiedStoreBadge,
      _ => type,
    };
    return Chip(avatar: const Icon(Icons.verified, size: 18, color: Colors.green), label: Text(label), visualDensity: VisualDensity.compact);
  }

  Widget _detailsSection(AppStrings strings) {
    final location = _details?['location'] as Map<String, dynamic>?;
    final summary = _details?['summary'] as Map<String, dynamic>?;
    final reviews = (_details?['reviews'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final badges = (_details?['badges'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final average = (summary?['average_rating'] as num?)?.toDouble();
    final count = (summary?['review_count'] as num?)?.toInt() ?? 0;
    final locationText = location == null
        ? strings.sellerLocationNotShared
        : [location['area'], location['city'], location['governorate']]
            .whereType<String>().where((v) => v.trim().isNotEmpty).join('، ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (badges.isNotEmpty)
          Wrap(spacing: 6, children: badges.map((b) => _badge(b['badge_type'] as String, strings)).toList()),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 20), const SizedBox(width: 8),
          Expanded(child: Text(locationText)),
          if (_isOwnProfile)
            IconButton(
              tooltip: strings.sellerLocationEdit,
              onPressed: _savingLocation ? null : _editLocation,
              icon: _savingLocation
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.edit_location_alt_outlined),
            ),
        ]),
        Row(children: [
          const Icon(Icons.star, color: Colors.amber), const SizedBox(width: 6),
          Text(average == null ? strings.sellerNoReviews : average.toStringAsFixed(1) + ' / 5 (' + count.toString() + ')'),
        ]),
        if (reviews.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(strings.sellerReviewTitle, style: Theme.of(context).textTheme.titleMedium),
          ...reviews.map((review) {
            final rating = (review['rating'] as num?)?.toInt() ?? 0;
            final comment = (review['comment'] as String?)?.trim() ?? '';
            final date = DateTime.tryParse(review['created_at']?.toString() ?? '')?.toLocal();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 18, child: Text(rating.toString())),
              title: Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, size: 16, color: Colors.amber))),
              subtitle: comment.isEmpty ? null : Text(comment, maxLines: 4, overflow: TextOverflow.ellipsis),
              trailing: date == null ? null : Text(
                date.day.toString() + '/' + date.month.toString() + '/' + date.year.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }),
        ],
      ]),
    );
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
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(strings.sellerStoreLoadError), const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: Text(strings.retryAction)),
                ])))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        child: Row(children: [
                          MemberAvatar(avatarUrl: _profile?['avatar_url'] as String?, radius: 38),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(sellerName?.isNotEmpty == true ? sellerName! : strings.memberFallbackName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 5), Text(strings.sellerOnKenza),
                            const SizedBox(height: 5), Text(_productCount.toString() + ' ' + strings.productsCount),
                          ])),
                        ]),
                      ),
                    ),
                    SliverToBoxAdapter(child: _detailsSection(strings)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: _products.isEmpty
                          ? SliverFillRemaining(hasScrollBody: false, child: Center(child: Text(strings.noPublishedProducts)))
                          : SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 16, childAspectRatio: 0.68,
                              ),
                              delegate: SliverChildBuilderDelegate((context, index) {
                                final product = _products[index];
                                return ProductCard(product: product, onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
                                ));
                              }, childCount: _products.length),
                            ),
                    ),
                  ]),
                ),
    );
  }
}
