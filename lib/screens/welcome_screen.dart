import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/config/app_colors.dart';
import 'package:kenza_hub_flutter/config/app_spacing.dart';
import 'package:kenza_hub_flutter/config/app_radius.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth > 600;
                final double heroHeight = isWide
                    ? constraints.maxHeight * 0.45
                    : constraints.maxHeight * 0.35;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top: language selector + logo
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Language selector (simple, not wired)
                              OutlinedButton(
                                onPressed: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    builder: (_) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              title: const Text('العربية'),
                                              onTap: () => Navigator.pop(context),
                                            ),
                                            ListTile(
                                              title: const Text('English'),
                                              onTap: () => Navigator.pop(context),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: const Text('العربية'),
                              ),

                              // Logo
                              Image.asset(
                                'assets/images/logo.png',
                                height: isWide ? 56 : 42,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),

                        // Hero visual
                        Center(
                          child: ClipRRect(
                            borderRadius: AppRadius.large,
                            child: Container(
                              height: heroHeight,
                              width: constraints.maxWidth * 0.85,
                              color: Theme.of(context).colorScheme.surface,
                              child: Image.asset(
                                'assets/images/welcome_1.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Title and subtitle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'مرحبًا بك في كينزا هب',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'السوق الأفضل لبيع وشراء احتياجاتك بسهولة وأمان',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        // Buttons
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FilledButton(
                                onPressed: () {},
                                child: const Text('إنشاء حساب'),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton(
                                onPressed: () {},
                                child: const Text('تسجيل الدخول'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
