import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen_new.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/order_confirmation_screen.dart';
import '../screens/orders/order_tracking_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/my_products_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/sell/sell_wizard_screen.dart';

// GoRouter configuration
final goRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final productId = state.pathParameters['id'] ?? '';
        return ProductDetailScreen(productId: productId);
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/order-confirmation/:id',
      builder: (context, state) {
        final orderId = state.pathParameters['id'] ?? '';
        return OrderConfirmationScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/order-tracking/:id',
      builder: (context, state) {
        final orderId = state.pathParameters['id'] ?? '';
        return OrderTrackingScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/my-products',
      builder: (context, state) => const MyProductsScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/sell-wizard',
      builder: (context, state) => const SellWizardScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('خطأ')),
    body: Center(
      child: Text('الصفحة "${state.uri.path}" غير موجودة'),
    ),
  ),
);

// Legacy AppRoutes for backward compatibility
class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/sign-up';
  static const String home = '/home';
  static const String productDetails = '/product-details';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  static const String orderTracking = '/order-tracking';
  static const String orderHistory = '/orders';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String myProducts = '/my-products';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String sellWizard = '/sell-wizard';
}
