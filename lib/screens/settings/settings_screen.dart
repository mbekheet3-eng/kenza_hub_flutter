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
            _buildSectionHeader(AppLocalizations.of(context).account),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'تعديل الملف الشخصي',
              onTap: () => context.push('/edit-profile'),
            ),
            _buildSettingsTile(
              icon: Icons.security,
              title: AppLocalizations.of(context).changePassword,
              onTap: () => context.push('/forgot-password'),
            ),
            _buildSettingsTile(
              icon: Icons.email_outlined,
              title: AppLocalizations.of(context).changeEmail,
              onTap: () => _showUnavailableFeature(AppLocalizations.of(context).changeEmail),
            ),
            const Divider(),

            // Notification preferences are read-only until server persistence exists.
            _buildSectionHeader(AppLocalizations.of(context).notificationsTooltip),
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: AppLocalizations.of(context).notificationPreferences,
              trailing: Text(AppLocalizations.of(context).notAvailable),
            ),
            const Divider(),

            // Privacy Section
            _buildSectionHeader(AppLocalizations.of(context).privacySecurity),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: AppLocalizations.of(context).privacyPolicy,
              onTap: () => context.push('/policies'),
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: AppLocalizations.of(context).termsOfService,
              onTap: () => context.push('/policies'),
            ),
            _buildSettingsTile(
              icon: Icons.block_outlined,
              title: AppLocalizations.of(context).blockedUsers,
              onTap: () => _showUnavailableFeature(AppLocalizations.of(context).blockedUsersList),
            ),
            const Divider(),

            // App Section
            _buildSectionHeader(AppLocalizations.of(context).appSection),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: AppLocalizations.of(context).aboutApp,
              trailing: Text(AppLocalizations.of(context).appVersion),
            ),
            _buildSettingsTile(
              icon: Icons.rate_review_outlined,
              title: AppLocalizations.of(context).rateApp,
              onTap: () => _showRatingDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.feedback_outlined,
              title: AppLocalizations.of(context).sendFeedback,
              onTap: () => _showUnavailableFeature(AppLocalizations.of(context).submitFeedback),
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: AppLocalizations.of(context).helpSupport,
              onTap: () => _showUnavailableFeature(AppLocalizations.of(context).helpSupport),
            ),
            const Divider(),

            // Danger Zone
            _buildSectionHeader(AppLocalizations.of(context).dangerZone, color: Colors.red),
            _buildSettingsTile(
              icon: Icons.delete_outline,
              title: AppLocalizations.of(context).deleteAccount,
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
    _showUnavailableFeature(AppLocalizations.of(context).rateTheApp);
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
