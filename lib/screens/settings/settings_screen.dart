import 'package:flutter/material.dart';
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
              onTap: () => context.push('/forgot-password'),
            ),
            _buildSettingsTile(
              icon: Icons.email_outlined,
              title: 'تغيير البريد الإلكتروني',
              onTap: () => _showUnavailableFeature('تغيير البريد الإلكتروني'),
            ),
            const Divider(),

            // Notifications Section
            _buildSectionHeader('الإشعارات'),
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'تفعيل الإشعارات',
              value: _notificationsEnabled,
              onChanged: (value) =>
                  _showUnavailableFeature('تفعيل الإشعارات'),
            ),
            if (_notificationsEnabled) ...[
              _buildSwitchTile(
                icon: Icons.mail_outline,
                title: 'إشعارات البريد الإلكتروني',
                value: _emailNotifications,
                onChanged: (value) =>
                    _showUnavailableFeature('إشعارات البريد الإلكتروني'),
              ),
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'الإشعارات الفورية',
                value: _pushNotifications,
                onChanged: (value) =>
                    _showUnavailableFeature('الإشعارات الفورية'),
              ),
            ],
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

  void _showUnavailableFeature(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature غير متاح حالياً وسيتم تفعيله بعد اكتمال تنفيذه.')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إيقاف أو حذف الحساب'),
        content: const Text(
          'إدارة إيقاف الحساب وحذفه غير متاحة حالياً. لن يتم تنفيذ أي حذف من هذه الشاشة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
