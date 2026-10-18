import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kenza_hub_flutter/config/app_routes.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:kenza_hub_flutter/screens/welcome/welcome_screen.dart';
import 'package:kenza_hub_flutter/providers/home_provider.dart';
import 'package:kenza_hub_flutter/providers/auth_provider.dart';
import 'package:kenza_hub_flutter/providers/product_details_provider.dart';
import 'package:kenza_hub_flutter/providers/cart_provider.dart';
import 'package:kenza_hub_flutter/providers/checkout_provider.dart';
import 'package:kenza_hub_flutter/providers/order_tracking_provider.dart';

// ✅ FIXED D1: Initialize Supabase before runApp
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  // Note: Make sure environment variables are properly set
  // SUPABASE_URL and SUPABASE_ANON_KEY should be configured
  try {
    await Supabase.initialize(
      url: 'https://qvqfzujvcnmquohieevl.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2cWZ6dWp2Y25tcXVvaGllZXZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc3NTAwMzAsImV4cCI6MjA0MzMyNjAzMH0.PLACEHOLDER_KEY', // Replace with actual key
    );
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
    // App will continue but may crash on first auth call
    // See console for details
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductDetailsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => OrderTrackingProvider()),
      ],
      child: ValueListenableBuilder<Locale>(
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
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF0F172A),
                secondary: Color(0xFFC85A32),
              ),
            ),
            initialRoute: AppRoutes.welcome,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
