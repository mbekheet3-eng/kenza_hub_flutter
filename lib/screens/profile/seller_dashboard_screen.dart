import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../services/seller_dashboard_service.dart';
import '../../providers/auth_provider.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final SellerDashboardService _service = SellerDashboardService();
  late Future<SellerDashboardData?> _dashboardFuture;
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = Future.value(null);
  }

  Future<void> _refresh() async {
    if (!mounted || _loadedUserId == null) return;
    final future = _service.load();
    setState(() => _dashboardFuture = future);
    await future;
  }

  String _sellerTypeLabel(String? type) {
    switch (type) {
      case 'pro_seller':
        return AppLocalizations.of(context).proSellerLabel;
      case 'seller':
        return AppLocalizations.of(context).sellerLabel;
      default:
        return type ?? AppLocalizations.of(context).sellerLabel;
    }
  }

  String _verificationLabel(String? status) {
    switch (status) {
      case 'verified':
        return AppLocalizations.of(context).verified;
      case 'pending':
        return AppLocalizations.of(context).pendingReview;
      case 'rejected':
        return AppLocalizations.of(context).notVerified;
      default:
        return AppLocalizations.of(context).unspecified;
    }
  }

  String _requestStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return AppLocalizations.of(context).upgradeRequestPending;
      case 'approved':
        return AppLocalizations.of(context).requestApproved;
      case 'rejected':
        return AppLocalizations.of(context).requestRejected;
      default:
        return AppLocalizations.of(context).noUpgradeRequest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.userId != _loadedUserId) {
      _loadedUserId = authProvider.userId;
      _dashboardFuture = authProvider.isSignedIn
          ? _service.load()
          : Future.value(null);
    }

    if (!authProvider.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).sellerDashboard)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).loginToViewSellerDashboard),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: Text(AppLocalizations.of(context).login),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).sellerDashboard)),
      body: FutureBuilder<SellerDashboardData?>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _message(
              icon: Icons.error_outline,
              message: AppLocalizations.of(context).storeDataLoadError,
              actionLabel: AppLocalizations.of(context).retry,
              onAction: _refresh,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return _message(
              icon: Icons.storefront_outlined,
              message:
                  AppLocalizations.of(context).sellerProfileNotCreated,
              actionLabel: AppLocalizations.of(context).backToHome,
              onAction: () => context.go('/home'),
            );
          }

          final profile = data.profile;
          final sellerType = profile['seller_type'] as String?;
          final businessType = profile['business_type'] as String?;
          final request = data.latestUpgradeRequest;
          final isOwner = data.memberRole == 'owner';
          final isAgency = businessType == 'agency';
          final isOnlineStore = businessType == 'online_store';
          final storeId = profile['id'].toString();
          final storeType = isAgency ? 'agency' : 'online_store';

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.storefront_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                profile['display_name'] as String? ??
                                    AppLocalizations.of(context).myStore,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(_sellerTypeLabel(sellerType)),
                        const SizedBox(height: 6),
                        Text(
                          '${AppLocalizations.of(context).verificationStatus}: ${_verificationLabel(profile['verification_status'] as String?)}',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile['is_active'] == true
                              ? AppLocalizations.of(context).storeStatusActive
                              : AppLocalizations.of(context).storeStatusInactive,
                        ),
                        const SizedBox(height: 6),
                        Text(isOwner ? AppLocalizations.of(context).storeRoleOwner : AppLocalizations.of(context).storeRoleTeamMember),
                      ],
                    ),
                  ),
                ),
                if (isAgency || isOnlineStore) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAgency ? AppLocalizations.of(context).agencyCorner : 'Online Store',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAgency
                                ? AppLocalizations.of(context).storefrontSetupHelp
                                : AppLocalizations.of(context).onlineStoreSetupHelp,
                          ),
                          const SizedBox(height: 12),
                          if (isOwner)
                            OutlinedButton.icon(
                              onPressed: () => context.push('/seller-store-settings'),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(AppLocalizations.of(context).storeAppearanceSettings),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => context.push(
                              '/store/$storeId?type=$storeType',
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: Text(AppLocalizations.of(context).previewStorePage),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        AppLocalizations.of(context).productsLabel,
                        data.productCount.toString(),
                        Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        AppLocalizations.of(context).totalSales,
                        (profile['total_sales'] as num? ?? 0).toString(),
                        Icons.shopping_bag_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).upgradeProSeller,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _requestStatusLabel(request?['status'] as String?),
                        ),
                        if (request != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${AppLocalizations.of(context).businessTypeRequested}: ${request['requested_business_type'] ?? 'غير محدد'}',
                          ),
                          if (request['review_note'] != null) ...[
                            const SizedBox(height: 6),
                            Text('${AppLocalizations.of(context).reviewNote}: ${request['review_note']}'),
                          ],
                        ],
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context).upgradeApprovalUnavailable,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).teamManagement,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOwner
                              ? AppLocalizations.of(context).teamPermissionsPending
                              : AppLocalizations.of(context).teamMemberWriteRestricted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/my-products'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(AppLocalizations.of(context).manageMyProducts),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
