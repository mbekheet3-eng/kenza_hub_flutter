import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kenza_hub_flutter/config/env_config.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:kenza_hub_flutter/screens/welcome/welcome_screen.dart';
import 'package:kenza_hub_flutter/screens/home/home_screen.dart';
import 'package:kenza_hub_flutter/screens/product/product_details_screen.dart';
import 'package:kenza_hub_flutter/screens/auth/signup_screen.dart';
import 'package:kenza_hub_flutter/screens/auth/login_screen.dart';
import 'package:kenza_hub_flutter/services/supabase_service.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Print config in debug mode
  EnvConfig.debugPrint();
  
  // Validate configuration
  if (!EnvConfig.isConfigured()) {
    print('⚠️ WARNING: Supabase configuration is missing!');
    print('Please fill in your .env file with valid credentials.');
  } else {
    // Initialize Supabase if configured
    try {
      await SupabaseService.initialize();
    } catch (e) {
      print('⚠️ WARNING: Supabase initialization failed: $e');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocalizations.localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          locale: locale,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return supportedLocales.firstWhere(
              (supportedLocale) =>
                  supportedLocale.languageCode == locale.languageCode,
              orElse: () => const Locale('ar'),
            );
          },
          title: 'كنزة هب',
          debugShowCheckedModeBanner: false,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate, // ✅ الصح
            GlobalWidgetsLocalizations.delegate, // ✅ الصح
            GlobalCupertinoLocalizations.delegate, // ✅ إضافة مهمة
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC62828),
              secondary: Color(0xFF0F172A),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const WelcomeScreen(),
            '/home': (context) => const HomeScreen(),
            '/product-details': (context) {
              final productId = ModalRoute.of(context)?.settings.arguments as String?;
              if (productId == null) {
                return const Scaffold(
                  body: Center(child: Text('خطأ: معرف المنتج مفقود')),
                );
              }
              return ProductDetailsScreen(productId: productId);
            },
            '/signup': (context) => const SignUpScreen(),
            '/login': (context) => const LoginScreen(),
            '/cart': (context) => const Scaffold(
                  body: Center(
                    child: Text('السلة - قيد التطوير'),
                  ),
                ),
            '/checkout': (context) => const Scaffold(
                  body: Center(
                    child: Text('الدفع - قيد التطوير'),
                  ),
                ),
            '/profile': (context) => const Scaffold(
                  body: Center(
                    child: Text('الملف الشخصي - قيد التطوير'),
                  ),
                ),
            '/guest_home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
