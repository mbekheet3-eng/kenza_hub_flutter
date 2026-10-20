import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  String _language = 'ar'; // Arabic by default
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
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
              onTap: () => context.push('/change-password'),
            ),
            _buildSettingsTile(
              icon: Icons.email_outlined,
              title: 'تغيير البريد الإلكتروني',
              onTap: () => context.push('/change-email'),
            ),
            const Divider(),

            // Notifications Section
            _buildSectionHeader('الإشعارات'),
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'تفعيل الإشعارات',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
            if (_notificationsEnabled) ...[
              _buildSwitchTile(
                icon: Icons.mail_outline,
                title: 'إشعارات البريد الإلكتروني',
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'الإشعارات الفورية',
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                },
              ),
            ],
            const Divider(),

            // Privacy Section
            _buildSectionHeader('الخصوصية والأمان'),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'سياسة الخصوصية',
              onTap: () => context.push('/privacy-policy'),
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'شروط الخدمة',
              onTap: () => context.push('/terms-of-service'),
            ),
            _buildSettingsTile(
              icon: Icons.block_outlined,
              title: 'المستخدمون المحظورون',
              onTap: () => context.push('/blocked-users'),
            ),
            const Divider(),

            // App Section
            _buildSectionHeader('التطبيق'),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'حول التطبيق',
              trailing: const Text('الإصدار 1.0.0'),
            ),
            _buildSettingsTile(
              icon: Icons.rate_review_outlined,
              title: 'قيم التطبيق',
              onTap: () => _showRatingDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.feedback_outlined,
              title: 'أرسل لنا رأيك',
              onTap: () => context.push('/feedback'),
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'المساعدة والدعم',
              onTap: () => context.push('/help'),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قيم التطبيق'),
        content: const Text('هل تستمتع بتطبيق كنزة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRatingStars();
            },
            child: const Text('نعم'),
          ),
        ],
      ),
    );
  }

  void _showRatingStars() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قيم التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: const Icon(Icons.star),
                  color: Colors.amber,
                  iconSize: 32,
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('شكراً لتقييمك!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('سيتم حذف حسابك قريباً'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
