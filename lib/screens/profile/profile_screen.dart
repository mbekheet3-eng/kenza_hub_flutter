import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/supabase_service.dart';
import '../../config/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _userProfile;
  bool _isLoadingProfile = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    try {
      setState(() => _isLoadingProfile = true);

      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoadingProfile = false;
        });
        return;
      }

      // Load custom User model from database
      final user = await SupabaseService().getUser(userId);
      await context.read<ProductProvider>().loadUserProducts(userId);

      if (mounted) {
        setState(() {
          _userProfile = user;
          _isLoadingProfile = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل الملف الشخصي: $e';
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _openEditProfile() async {
    await context.push('/edit-profile');
    if (mounted) await _loadUserData();
  }

  Future<void> _handleLogout() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signOut();

      if (!mounted) return;
      if (authProvider.isSignedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? 'تعذر تسجيل الخروج. حاول مرة أخرى.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.go('/welcome');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Check if user is logged in
    if (authProvider.userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).profileTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).pleaseLogin,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).profileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (_error != null || _userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).profileTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'فشل تحميل البيانات',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _userProfile!;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(context, user),
              const SizedBox(height: 24),

              // User Stats
              _buildUserStats(context, user),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context, user),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(AppLocalizations.of(context).ordersHistory),
                        subtitle: Text(AppLocalizations.of(context).ordersSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/orders'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.storefront_outlined),
                        title: Text(AppLocalizations.of(context).sellerDashboard),
                        subtitle: Text(AppLocalizations.of(context).sellerDashboardSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/seller-dashboard'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // About Section
              if (user.bio != null && user.bio!.isNotEmpty)
                _buildAboutSection(context, user),

              const SizedBox(height: 24),

              // My Products Section
              _buildMyProductsSection(context),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: Color(0xFFC62828),
                        ),
                        title: Text(AppLocalizations.of(context).aboutKenza),
                        subtitle: Text(AppLocalizations.of(context).aboutKenzaSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/about-kenza'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(
                          Icons.policy_outlined,
                          color: Color(0xFFC62828),
                        ),
                        title: Text(AppLocalizations.of(context).policiesTerms),
                        subtitle: Text(AppLocalizations.of(context).policiesSubtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/policies'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                    ),
                    child: Text(
                      AppLocalizations.of(context).logout,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC85A32),
                  width: 2,
                ),
                image: user.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(user.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[300],
              ),
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? AppLocalizations.of(context).userFallback,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                // Rating
                if (user.rating > 0 && user.totalReviews > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${user.rating.toStringAsFixed(1)} (${user.totalReviews})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openEditProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, user.productsCount.toString(), 'منتجاتي'),
          _buildStatItem(context, user.followersCount.toString(), AppLocalizations.of(context).followers),
          _buildStatItem(context, user.totalReviews.toString(), AppLocalizations.of(context).ratings),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFC85A32),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/my-products'),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('منتجاتي'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/edit-profile'),
              icon: const Icon(Icons.edit),
              label: Text(AppLocalizations.of(context).edit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).aboutMe,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              user.bio ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProductsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'منتجاتي',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => context.push('/my-products'),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              final products = productProvider.products.take(3).toList();

              if (products.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد منتجات',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return GestureDetector(
                    onTap: () => context.push('/product/${product.id}'),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product.price} ج.م',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFFC85A32),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
