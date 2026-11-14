import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';

import '../widgets/member_avatar.dart';

import '../models/product.dart';
import '../models/category.dart';
import '../services/favorites_service.dart';
import '../services/marketplace_service.dart';
import 'product_form_screen.dart';
import 'conversation_screen.dart';
import '../services/marketplace_transaction_service.dart';
import 'login_screen.dart';
import 'seller_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _service = MarketplaceService();
  final _transactionService = MarketplaceTransactionService();
  final _favoritesService = FavoritesService();
  late Future<Product> _product;
  late Future<List<Category>> _categories;
  bool _isFavorite = false;
  bool _favoriteLoading = false;
  final Map<String, Future<Map<String, dynamic>?>> _publicMemberProfiles = {};

  AppStrings get _l10n => AppStrings.of(context)!;

  Future<Map<String, dynamic>?> _publicProfileFor(String memberId) {
    return _publicMemberProfiles.putIfAbsent(
      memberId,
      () => _service.getPublicMemberProfile(memberId),
    );
  }

  @override
  void initState() {
    super.initState();
    _product = _service.getProduct(widget.productId);
    _categories = _service.getCategories();
    _loadFavoriteStatus();
  }

  void _reload() => setState(() {
        _product = _service.getProduct(widget.productId);
        _categories = _service.getCategories();
      });

  Future<void> _loadFavoriteStatus() async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    try {
      final ids = await _favoritesService.getFavoriteProductIds();
      if (mounted) setState(() => _isFavorite = ids.contains(widget.productId));
    } catch (_) {
      // Favorite status is optional; product details remain available.
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    if (!await _ensureLogin() || !mounted || _favoriteLoading) return;
    setState(() => _favoriteLoading = true);
    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(product.id);
      } else {
        await _favoritesService.addFavorite(product.id);
      }
      if (!mounted) return;
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? _l10n.favoriteAddedToast : _l10n.favoriteRemoved),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.favoriteUpdateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  Future<void> _shareProduct(Product product) async {
    final text = '${product.title}\\n${product.price.toStringAsFixed(0)} ${_l10n.currency}\\nKenza';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _edit(Product product) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_l10n.deleteProductConfirmTitle),
        content: Text(_l10n.deleteProductConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_l10n.deleteLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteProduct(widget.productId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_l10n.deleteProductFailed}: $error')),
        );
      }
    }
  }


  Future<bool> _ensureLogin() async {
    if (Supabase.instance.client.auth.currentUser != null) return true;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    return mounted && Supabase.instance.client.auth.currentUser != null;
  }

  Future<void> _buy(Product product) async {
    if (!await _ensureLogin()) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.confirmPurchaseTitle),
        content: Text(_l10n.purchaseConfirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_l10n.backLabel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_l10n.sendOrderLabel)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _transactionService.createOrder(
        productId: product.id,
        sellerId: product.ownerId,
        price: product.price,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.orderSentWaiting)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_l10n.orderSendFailed}: $error')),
        );
      }
    }
  }

  Future<void> _makeOffer(Product product) async {
    if (!await _ensureLogin()) return;
    if (!mounted) return;
    final priceController = TextEditingController(text: product.price.toStringAsFixed(2));
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.offerDialogTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: _l10n.proposedPriceLabel),
                validator: (value) {
                  final price = double.tryParse((value ?? '').trim());
                  return price == null || price <= 0 ? _l10n.invalidPrice : null;
                },
              ),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(labelText: _l10n.sellerMessageOptional),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_l10n.cancelLabel)),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(_l10n.sendOfferLabel),
          ),
        ],
      ),
    );
    if (result == true) {
      try {
        await _transactionService.createOffer(
          productId: product.id,
          sellerId: product.ownerId,
          offeredPrice: double.parse(priceController.text.trim()),
          message: noteController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.offerSent)),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_l10n.offerSendFailed}: $error')),
          );
        }
      }
    }
    priceController.dispose();
    noteController.dispose();
  }

  Future<void> _contactSeller(Product product) async {
    if (!await _ensureLogin()) return;
    try {
      final conversationId = await _transactionService.getOrCreateConversation(
        productId: product.id,
        sellerId: product.ownerId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(conversationId: conversationId),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_l10n.conversationOpenFailed}: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: Text(_l10n.productDetailsTitle)),
      body: FutureBuilder<Product>(
        future: _product,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${_l10n.productLoadError}: ${snapshot.error ?? ''}'),
              ),
            );
          }

          final product = snapshot.data!;
          final isOwner = userId != null && userId == product.ownerId;

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (product.imageUrls.isNotEmpty)
                ProductImageCarousel(imageUrls: product.imageUrls)
              else
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.58,
                  child: const Center(child: Icon(Icons.image_outlined, size: 60)),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: Theme.of(context).textTheme.headlineSmall),
                    if (product.customCategoryName?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text('${_l10n.customCategoryLabel}: ${product.customCategoryName}'),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      '${product.price.toStringAsFixed(2)} ${_l10n.currency}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _favoriteLoading ? null : () => _toggleFavorite(product),
                          icon: _favoriteLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                          label: Text(_isFavorite ? _l10n.removeFavoriteTooltip : _l10n.addFavoriteTooltip),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _shareProduct(product),
                          icon: const Icon(Icons.share_outlined),
                          label: Text(_l10n.shareProduct),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _publicProfileFor(product.ownerId),
                      builder: (context, snapshot) {
                        final publicProfile = snapshot.data;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: MemberAvatar(
                            avatarUrl: publicProfile?['avatar_url'] as String?,
                            radius: 23,
                          ),
                          title: Text(
                            (publicProfile?['first_name'] as String?)?.isNotEmpty == true
                                ? publicProfile!['first_name'] as String
                                : _l10n.memberFallbackName,
                          ),
                          subtitle: Text(_l10n.seller),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SellerProfileScreen(sellerId: product.ownerId),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Category>>(
                      future: _categories,
                      builder: (context, categorySnapshot) {
                        if (!categorySnapshot.hasData) return const SizedBox.shrink();
                        Category? category;
                        for (final item in categorySnapshot.data!) {
                          if (item.id == product.categoryId) {
                            category = item;
                            break;
                          }
                        }
                        if (category == null) return const SizedBox.shrink();
                        return Chip(
                          avatar: const Icon(Icons.category_outlined, size: 18),
                          label: Text('${_l10n.categoryLabel}: ${category.nameFor(Localizations.localeOf(context).languageCode)}'),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      avatar: const Icon(Icons.groups_outlined, size: 18),
                      label: Text(product.audience == 'women_only'
                          ? _l10n.audienceWomenOnly
                          : product.audience == 'men_only'
                              ? _l10n.audienceMenOnly
                              : _l10n.audienceAll),
                    ),
                    const SizedBox(height: 20),
                    Text(_l10n.descriptionLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(product.description.isEmpty ? _l10n.noDescription : product.description),
                    const SizedBox(height: 18),
                    Text(
                      '${_l10n.publishedDateLabel}: ${MaterialLocalizations.of(context).formatMediumDate(product.createdAt.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    if (!isOwner) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _buy(product),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: Text(_l10n.buyNowLabel),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _makeOffer(product),
                              icon: const Icon(Icons.local_offer_outlined),
                              label: Text(_l10n.offerLabel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _contactSeller(product),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(_l10n.contactSellerLabel),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isOwner) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _edit(product),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(_l10n.editLabel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _delete,
                              icon: const Icon(Icons.delete_outline),
                              label: Text(_l10n.deleteLabel),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class ProductImageCarousel extends StatefulWidget {
  const ProductImageCarousel({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openFullScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenProductGallery(
          imageUrls: widget.imageUrls,
          initialIndex: _currentPage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final imageHeight = (screenHeight * 0.58).clamp(300.0, 620.0).toDouble();

    return SizedBox(
      height: imageHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openFullScreen,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      '${_currentPage + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: AppStrings.of(context)!.zoomImageLabel,
                onPressed: _openFullScreen,
                icon: const Icon(Icons.zoom_in, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenProductGallery extends StatefulWidget {
  const _FullScreenProductGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FullScreenProductGallery> createState() => _FullScreenProductGalleryState();
}

class _FullScreenProductGalleryState extends State<_FullScreenProductGallery> {
  late final PageController _pageController;
  late final List<TransformationController> _transformControllers;
  int _currentPage = 0;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformControllers = List.generate(
      widget.imageUrls.length,
      (_) => TransformationController(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateZoomState() {
    final scale = _transformControllers[_currentPage].value.getMaxScaleOnAxis();
    final zoomed = scale > 1.02;
    if (zoomed != _isZoomed && mounted) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_currentPage + 1} / ${widget.imageUrls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        physics: _isZoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        onPageChanged: (index) => setState(() {
          _currentPage = index;
          _isZoomed = _transformControllers[index].value.getMaxScaleOnAxis() > 1.02;
        }),
        itemBuilder: (context, index) => Center(
          child: InteractiveViewer(
            transformationController: _transformControllers[index],
            minScale: 1,
            maxScale: 5,
            panEnabled: true,
            scaleEnabled: true,
            onInteractionEnd: (_) => _updateZoomState(),
            child: Image.network(
              widget.imageUrls[index],
              fit: BoxFit.contain,
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
