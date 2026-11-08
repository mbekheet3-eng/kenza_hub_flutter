import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../services/seller_directory_service.dart';

class SellerDirectoryScreen extends StatefulWidget {
  const SellerDirectoryScreen({super.key, required this.agency});

  final bool agency;

  @override
  State<SellerDirectoryScreen> createState() => _SellerDirectoryScreenState();
}

class _SellerDirectoryScreenState extends State<SellerDirectoryScreen> {
  final SellerDirectoryService _service = SellerDirectoryService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadDirectory(agency: widget.agency);
  }

  Future<void> _refresh() async {
    final future = _service.loadDirectory(agency: widget.agency);
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.agency ? 'Wekala Corner' : 'Social Corner';
    final subtitle = widget.agency
        ? AppLocalizations.of(context).physicalShopsInWekala
        : AppLocalizations.of(context).socialStoresAndPages;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DirectoryMessage(
              icon: Icons.cloud_off_outlined,
              message: AppLocalizations.of(context).storesLoadError,
              action: AppLocalizations.of(context).retry,
              onPressed: _refresh,
            );
          }
          final stores = snapshot.data ?? const [];
          if (stores.isEmpty) {
            return _DirectoryMessage(
              icon: Icons.storefront_outlined,
              message: widget.agency
                  ? AppLocalizations.of(context).noPhysicalShops
                  : AppLocalizations.of(context).noOnlineStores,
              action: AppLocalizations.of(context).refresh,
              onPressed: _refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                const SizedBox(height: 14),
                ...stores.map((store) {
                  final storeId = store['id'].toString();
                  final storeType = widget.agency ? 'agency' : 'online_store';
                  return _StoreDirectoryCard(
                    store: store,
                    agency: widget.agency,
                    onTap: () => context.push('/store/$storeId?type=$storeType'),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StoreDirectoryCard extends StatelessWidget {
  const _StoreDirectoryCard({
    required this.store,
    required this.agency,
    required this.onTap,
  });

  final Map<String, dynamic> store;
  final bool agency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (store['business_name'] ?? store['display_name'] ?? AppLocalizations.of(context).storeLabel)
        .toString();
    final cover = store['cover_image_url'] as String?;
    final avatar = store['avatar_url'] as String?;
    final area = store['shop_area'] as String?;
    final canShowCover = !agency || store['show_storefront'] == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canShowCover && cover != null && cover.isNotEmpty)
              CachedNetworkImage(
                imageUrl: cover,
                height: 132,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(height: 8),
              )
            else
              Container(
                height: 82,
                color: const Color(0xFFF1F2F6),
                alignment: Alignment.center,
                child: Icon(
                  agency ? Icons.storefront_outlined : Icons.shopping_bag_outlined,
                  size: 36,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage:
                        avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar == null || avatar.isEmpty
                        ? const Icon(Icons.store_outlined)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (agency && area != null && area.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('${AppLocalizations.of(context).areaLabel}: $area',
                              style: const TextStyle(color: Colors.black54)),
                        ],
                        if (agency && store['show_storefront'] == true) ...[
                          const SizedBox(height: 4),
                          Text(AppLocalizations.of(context).storefrontDisplayed,
                              style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryMessage extends StatelessWidget {
  const _DirectoryMessage({
    required this.icon,
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.black38),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
