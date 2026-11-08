import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settingsTitle),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            _buildSectionHeader('الحساب'),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'تعديل الملف الشخصي',
              onTap: () => context.push('/edit-profile'),
            ),
            _buildSettingsTile(
              icon: Icons.security,
              title: 'تغيير كلمة المرور',
              onTap: () => context.push('/forgot-password'),
            ),
            _buildSettingsTile(
              icon: Icons.email_outlined,
              title: 'تغيير البريد الإلكتروني',
              onTap: () => _showUnavailableFeature('تغيير البريد الإلكتروني'),
            ),
            const Divider(),

            // Notification preferences are read-only until server persistence exists.
            _buildSectionHeader('الإشعارات'),
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'تفضيلات الإشعارات',
              trailing: Text(AppLocalizations.of(context).notAvailable),
            ),
            const Divider(),

            // Privacy Section
            _buildSectionHeader('الخصوصية والأمان'),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'سياسة الخصوصية',
              onTap: () => context.push('/policies'),
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'شروط الخدمة',
              onTap: () => context.push('/policies'),
            ),
            _buildSettingsTile(
              icon: Icons.block_outlined,
              title: 'المستخدمون المحظورون',
              onTap: () => _showUnavailableFeature('قائمة المستخدمين المحظورين'),
            ),
            const Divider(),

            // App Section
            _buildSectionHeader('التطبيق'),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'حول التطبيق',
              trailing: Text(AppLocalizations.of(context).appVersion),
            ),
            _buildSettingsTile(
              icon: Icons.rate_review_outlined,
              title: 'قيم التطبيق',
              onTap: () => _showRatingDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.feedback_outlined,
              title: 'أرسل لنا رأيك',
              onTap: () => _showUnavailableFeature('إرسال الملاحظات'),
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'المساعدة والدعم',
              onTap: () => _showUnavailableFeature('المساعدة والدعم'),
            ),
            const Divider(),

            // Danger Zone
            _buildSectionHeader('منطقة الخطر', color: Colors.red),
            _buildSettingsTile(
              icon: Icons.delete_outline,
              title: 'حذف الحساب',
              titleColor: Colors.red,
              onTap: () => _showDeleteAccountDialog(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = const Color(0xFF0F172A)}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppTheme.primaryColor),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: titleColor,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  void _showRatingDialog() {
    _showUnavailableFeature('تقييم التطبيق');
  }

  void _showUnavailableFeature(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature ${AppLocalizations.of(context).featureUnavailable}')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).accountDeactivateDelete),
        content: Text(
          AppLocalizations.of(context).accountDeletionUnavailable,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }
}
