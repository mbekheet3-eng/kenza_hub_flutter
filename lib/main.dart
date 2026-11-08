import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kenza_hub_flutter/config/app_routes.dart';
import 'package:kenza_hub_flutter/config/app_theme.dart';
import 'package:kenza_hub_flutter/config/supabase_config.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:kenza_hub_flutter/providers/home_provider.dart';
import 'package:kenza_hub_flutter/providers/auth_provider.dart';
import 'package:kenza_hub_flutter/providers/product_details_provider.dart';
import 'package:kenza_hub_flutter/providers/product_provider.dart';
import 'package:kenza_hub_flutter/providers/cart_provider.dart';
import 'package:kenza_hub_flutter/providers/checkout_provider.dart';
import 'package:kenza_hub_flutter/providers/order_tracking_provider.dart';

// ✅ FIXED D1: Initialize Supabase before runApp
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppLocalizations.initialize();
  } catch (e) {
    debugPrint('Could not restore saved language: $e');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.publishableKey,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
    runApp(SupabaseInitializationErrorApp(message: e.toString()));
    return;
  }

  runApp(const MyApp());
}

class SupabaseInitializationErrorApp extends StatelessWidget {
  final String message;

  const SupabaseInitializationErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: AppLocalizations.currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 52),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).initializationError,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).initializationRetryHint,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
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
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(
          create: (_) => CartProvider(
            authUserChanges: Supabase.instance.client.auth.onAuthStateChange
                .map((authState) => authState.session?.user.id),
            initialUserId: Supabase.instance.client.auth.currentUser?.id,
          ),
        ),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => OrderTrackingProvider()),
      ],
      child: ValueListenableBuilder<Locale>(
        valueListenable: AppLocalizations.localeNotifier,
        builder: (context, locale, child) {
          return MaterialApp.router(
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
            theme: AppTheme.lightTheme,
            routerConfig: goRouter,
          );
        },
      ),
    );
  }
}
