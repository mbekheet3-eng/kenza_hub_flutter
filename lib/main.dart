import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:kenza_hub_flutter/config/env_config.dart';
import 'package:kenza_hub_flutter/config/app_routes.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:kenza_hub_flutter/screens/welcome/welcome_screen.dart';
import 'package:kenza_hub_flutter/providers/home_provider.dart';
import 'package:kenza_hub_flutter/providers/auth_provider.dart';
import 'package:kenza_hub_flutter/providers/product_details_provider.dart';
import 'package:kenza_hub_flutter/providers/cart_provider.dart';
import 'package:kenza_hub_flutter/providers/checkout_provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductDetailsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
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
