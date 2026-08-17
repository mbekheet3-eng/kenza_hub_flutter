import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_radius.dart';
import '../../config/app_spacing.dart';
import '../../config/app_text_styles.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            bottom: BorderSide(
              color: AppColors.outline,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.primary,
                          size: 32,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'كنزة هب',
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'الإشعارات',
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.pill,
              ),
              child: IconButton(
                tooltip: 'الملف الشخصي',
                onPressed: () => context.push('/profile'),
                icon: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
