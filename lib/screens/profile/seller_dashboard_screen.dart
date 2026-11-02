import 'package:flutter/material.dart';
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
        return 'بائع محترف Pro Seller';
      case 'seller':
        return 'بائع';
      default:
        return type ?? 'بائع';
    }
  }

  String _verificationLabel(String? status) {
    switch (status) {
      case 'verified':
        return 'تم التحقق';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'لم يتم التحقق';
      default:
        return 'غير محدد';
    }
  }

  String _requestStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'طلب الترقية قيد المراجعة';
      case 'approved':
        return 'تمت الموافقة على الطلب';
      case 'rejected':
        return 'تم رفض الطلب';
      default:
        return 'لا يوجد طلب ترقية';
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
        appBar: AppBar(title: const Text('لوحة البائع')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('سجّل الدخول لعرض لوحة البائع'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة البائع')),
      body: FutureBuilder<SellerDashboardData?>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _message(
              icon: Icons.error_outline,
              message: 'تعذر تحميل بيانات المتجر',
              actionLabel: 'إعادة المحاولة',
              onAction: _refresh,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return _message(
              icon: Icons.storefront_outlined,
              message:
                  'لم يتم إنشاء ملف بائع لهذا الحساب بعد. ينشأ تلقائيًا عند أول نشر، لكن نشر المنتجات متوقف حاليًا لحين تحديد منطقة الحساب ومراجعة نطاق الشحن المعتمد.',
              actionLabel: 'العودة إلى الرئيسية',
              onAction: () => context.go('/home'),
            );
          }

          final profile = data.profile;
          final sellerType = profile['seller_type'] as String?;
          final request = data.latestUpgradeRequest;
          final isOwner = data.memberRole == 'owner';

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
                                    'متجري',
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
                          'حالة التحقق: ${_verificationLabel(profile['verification_status'] as String?)}',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile['is_active'] == true
                              ? 'حالة المتجر: نشط'
                              : 'حالة المتجر: غير نشط',
                        ),
                        const SizedBox(height: 6),
                        Text(isOwner ? 'صلاحية الحساب: مالك المتجر' : 'صلاحية الحساب: عضو فريق'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'المنتجات',
                        data.productCount.toString(),
                        Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        'إجمالي المبيعات',
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
                          'ترقية Pro Seller',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _requestStatusLabel(request?['status'] as String?),
                        ),
                        if (request != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'نوع النشاط المطلوب: ${request['requested_business_type'] ?? 'غير محدد'}',
                          ),
                          if (request['review_note'] != null) ...[
                            const SizedBox(height: 6),
                            Text('ملاحظة المراجعة: ${request['review_note']}'),
                          ],
                        ],
                        const SizedBox(height: 10),
                        const Text(
                          'تقديم طلبات الترقية واعتمادها غير متاحين من التطبيق حتى اكتمال مسار الاعتماد الإداري وحفظ نوع النشاط المعتمد.',
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
                          'إدارة الفريق',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOwner
                              ? 'إدارة الموظفين وتعديل صلاحياتهم ستظهر بعد اكتمال فرض الصلاحيات على مستوى قاعدة البيانات.'
                              : 'حسابك عضو فريق. بعض عمليات الكتابة مقفولة مؤقتًا حتى تكتمل صلاحيات الموظفين المعتمدة.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/my-products'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('إدارة منتجاتي'),
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
