import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/screens/welcome/welcome_screen.dart';
import 'package:kenza_hub_flutter/screens/auth/login_screen.dart';
import 'package:kenza_hub_flutter/screens/auth/signup_screen.dart';
import 'package:kenza_hub_flutter/screens/home/home_screen_new.dart';
import 'package:kenza_hub_flutter/screens/product/product_details_screen.dart';
import 'package:kenza_hub_flutter/screens/cart/cart_screen.dart';
import 'package:kenza_hub_flutter/screens/checkout/checkout_screen.dart';
import 'package:kenza_hub_flutter/screens/checkout/order_confirmation_screen.dart';

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

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case productDetails:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(productId: productId),
        );

      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());

      case orderConfirmation:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(orderId: orderId),
        );

      case orderTracking:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderTrackingPlaceholder(orderId: orderId),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('خطأ')),
            body: Center(
              child: Text('الصفحة "${settings.name}" غير موجودة'),
            ),
          ),
        );
    }
  }
}

// Placeholder for OrderTracking (سيتم إنشاؤه لاحقاً)
class OrderTrackingPlaceholder extends StatelessWidget {
  final String orderId;

  const OrderTrackingPlaceholder({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الطلب'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Order ID: $orderId'),
            const SizedBox(height: 16),
            const Text('سيتم بناء هذه الشاشة قريباً'),
          ],
        ),
      ),
    );
  }
}
