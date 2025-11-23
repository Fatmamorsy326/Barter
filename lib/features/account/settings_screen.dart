// ============================================
// FILE: lib/features/account/settings_screen.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/providers/local_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      print('Error loading version: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(
        padding: REdgeInsets.all(16),
        children: [
          _buildSectionTitle('General Settings'),
          SizedBox(height: 8.h),
          _buildLanguageTile(),
          SizedBox(height: 8.h),
          _buildNotificationsTile(),

          SizedBox(height: 24.h),
          _buildSectionTitle('App Information'),
          SizedBox(height: 8.h),
          _buildInfoTile(
            icon: Icons.privacy_tip_outlined,
            title: AppLocalizations.of(context)!.privacy_policy,
            onTap: () => _showInfoDialog(
              'Privacy Policy',
              'Your privacy is important to us. We collect minimal data necessary for the app to function.',
            ),
          ),
          SizedBox(height: 8.h),
          _buildInfoTile(
            icon: Icons.description_outlined,
            title: AppLocalizations.of(context)!.terms_of_service,
            onTap: () => _showInfoDialog(
              'Terms of Service',
              'By using this app, you agree to our terms and conditions.',
            ),
          ),
          SizedBox(height: 8.h),
          _buildInfoTile(
            icon: Icons.info_outline,
            title: AppLocalizations.of(context)!.about,
            subtitle: 'Version $_appVersion',
            onTap: () => _showAboutDialog(),
          ),

          SizedBox(height: 24.h),
          _buildSectionTitle('Support'),
          SizedBox(height: 8.h),
          _buildInfoTile(
            icon: Icons.help_outline,
            title: AppLocalizations.of(context)!.help_support,
            onTap: () => _showInfoDialog(
              'Help & Support',
              'Need help? Contact us at support@barterapp.com',
            ),
          ),
          SizedBox(height: 8.h),
          _buildInfoTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            onTap: () => _showInfoDialog(
              'Report a Bug',
              'Found a bug? Please email us at bugs@barterapp.com with details.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: REdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: ColorsManager.purple,
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLanguage = localeProvider.locale.languageCode;

    return Card(
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.language, color: ColorsManager.purple),
        title: Text(AppLocalizations.of(context)!.language),
        trailing: DropdownButton<String>(
          value: currentLanguage,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(
              value: 'en',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇬🇧'),
                  SizedBox(width: 8),
                  Text('English'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'ar',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇪🇬'),
                  SizedBox(width: 8),
                  Text('العربية'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              _changeLanguage(context, value);
            }
          },
        ),
      ),
    );
  }

  Future<void> _changeLanguage(BuildContext context, String languageCode) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Change locale
    await localeProvider.setLocale(Locale(languageCode));

    // Small delay to show the change
    await Future.delayed(const Duration(milliseconds: 500));

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageCode == 'en'
                ? 'Language changed to English'
                : 'تم تغيير اللغة إلى العربية',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: ColorsManager.purple,
        ),
      );
    }
  }

  Widget _buildNotificationsTile() {
    return Card(
      elevation: 1,
      child: SwitchListTile(
        secondary: const Icon(Icons.notifications_outlined, color: ColorsManager.purple),
        title: Text(AppLocalizations.of(context)!.notifications),
        subtitle: Text(
          _notificationsEnabled ? 'Enabled' : 'Disabled',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        value: _notificationsEnabled,
        activeColor: ColorsManager.purple,
        onChanged: (value) {
          setState(() => _notificationsEnabled = value);
          // TODO: Implement notification settings
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value
                    ? 'Notifications enabled'
                    : 'Notifications disabled',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: ColorsManager.purple),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Barter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: $_appVersion'),
            SizedBox(height: 8.h),
            const Text('Barter is a peer-to-peer exchange platform that allows users to trade items without money.'),
            SizedBox(height: 8.h),
            const Text('© 2024 Barter App. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}