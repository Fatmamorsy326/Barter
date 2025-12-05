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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: ColorsManager.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: REdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Appearance', Icons.palette_rounded),
                  SizedBox(height: 12.h),
                  _buildSettingsCard([
                    _buildThemeTile(themeProvider, isDark),
                  ]),
                  SizedBox(height: 24.h),
                  _buildSectionTitle('Preferences', Icons.tune_rounded),
                  SizedBox(height: 12.h),
                  _buildSettingsCard([
                    _buildLanguageTile(),
                    _buildDivider(),
                    _buildNotificationsTile(),
                  ]),
                  SizedBox(height: 24.h),
                  _buildSectionTitle('Information', Icons.info_outline_rounded),
                  SizedBox(height: 12.h),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      title: AppLocalizations.of(context)!.privacy_policy,
                      onTap: () => _showInfoDialog(
                        'Privacy Policy',
                        'Your privacy is important to us. We collect minimal data necessary for the app to function.',
                        Icons.privacy_tip_rounded,
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.description_rounded,
                      title: AppLocalizations.of(context)!.terms_of_service,
                      onTap: () => _showInfoDialog(
                        'Terms of Service',
                        'By using this app, you agree to our terms and conditions.',
                        Icons.description_rounded,
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.info_rounded,
                      title: AppLocalizations.of(context)!.about,
                      subtitle: 'Version $_appVersion',
                      onTap: _showAboutDialog,
                    ),
                  ]),
                  SizedBox(height: 24.h),
                  _buildSectionTitle('Support', Icons.support_agent_rounded),
                  SizedBox(height: 12.h),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.help_rounded,
                      title: AppLocalizations.of(context)!.help_support,
                      onTap: () => _showInfoDialog(
                        'Help & Support',
                        'Need help? Contact us at support@barterapp.com',
                        Icons.help_rounded,
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.bug_report_rounded,
                      title: 'Report a Bug',
                      onTap: () => _showInfoDialog(
                        'Report a Bug',
                        'Found a bug? Please email us at bugs@barterapp.com with details.',
                        Icons.bug_report_rounded,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 80.h,
      leading: IconButton(
        icon: Container(
          padding: REdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18.sp),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsManager.gradientStart,
              ColorsManager.gradientEnd,
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: REdgeInsets.only(left: 60, bottom: 16),
          title: Row(
            children: [
              Icon(Icons.settings_rounded, color: Colors.white, size: 20.sp),
              SizedBox(width: 10.w),
              Text(
                AppLocalizations.of(context)!.settings,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ColorsManager.purple, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: ColorsManager.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: ColorsManager.greyUltraLight),
    );
  }

  Widget _buildThemeTile(ThemeProvider themeProvider, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => themeProvider.toggleTheme(),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: REdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: REdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFFFF9800),
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorsManager.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isDark ? 'Easier on the eyes' : 'Bright and clear',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ColorsManager.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: ColorsManager.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile() {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLanguage = localeProvider.locale.languageCode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLanguageBottomSheet(),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: REdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: REdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorsManager.purpleSoft,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.language_rounded, color: ColorsManager.purple, size: 22.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.language,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorsManager.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      currentLanguage == 'en' ? 'English' : 'العربية',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ColorsManager.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: REdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorsManager.greyUltraLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLanguage == 'en' ? '🇬🇧' : '🇪🇬',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp, color: ColorsManager.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ColorsManager.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Padding(
            padding: REdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: ColorsManager.greyLight,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Select Language',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24.h),
                _buildLanguageOption('en', '🇬🇧', 'English', ctx),
                SizedBox(height: 12.h),
                _buildLanguageOption('ar', '🇪🇬', 'العربية', ctx),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String flag, String name, BuildContext ctx) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isSelected = localeProvider.locale.languageCode == code;

    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        _changeLanguage(context, code);
      },
      child: Container(
        padding: REdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ColorsManager.purpleSoft : ColorsManager.greyUltraLight,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected ? Border.all(color: ColorsManager.purple, width: 2) : null,
        ),
        child: Row(
          children: [
            Text(flag, style: TextStyle(fontSize: 28.sp)),
            SizedBox(width: 16.w),
            Text(
              name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? ColorsManager.purple : ColorsManager.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: ColorsManager.purple, size: 24.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(BuildContext context, String languageCode) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: REdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ColorsManager.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.purple),
          ),
        ),
      ),
    );

    await localeProvider.setLocale(Locale(languageCode));
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageCode == 'en'
                ? 'Language changed to English'
                : 'تم تغيير اللغة إلى العربية',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: ColorsManager.purple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    }
  }

  Widget _buildNotificationsTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _notificationsEnabled = !_notificationsEnabled);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _notificationsEnabled
                    ? 'Notifications enabled'
                    : 'Notifications disabled',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: REdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: REdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _notificationsEnabled
                      ? Colors.green.withOpacity(0.1)
                      : ColorsManager.greyUltraLight,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _notificationsEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: _notificationsEnabled ? Colors.green : ColorsManager.grey,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notifications,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorsManager.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _notificationsEnabled ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ColorsManager.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Notifications enabled' : 'Notifications disabled',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  );
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: REdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: REdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorsManager.purpleSoft,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: ColorsManager.purple, size: 22.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorsManager.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: ColorsManager.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ColorsManager.grey,
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String content, IconData icon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              padding: REdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsManager.purpleSoft,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: ColorsManager.purple, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(content, style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: ColorsManager.purple)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: REdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.swap_horizontal_circle_rounded, size: 48.sp, color: Colors.white),
              ),
              SizedBox(height: 16.h),
              Text(
                'Barter',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.purple,
                ),
              ),
              Text('Version $_appVersion', style: TextStyle(color: ColorsManager.grey)),
              SizedBox(height: 16.h),
              Text(
                'A peer-to-peer exchange platform that allows users to trade items without money.',
                style: TextStyle(height: 1.5, color: ColorsManager.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                '© 2024 Barter. All rights reserved.',
                style: TextStyle(fontSize: 11.sp, color: ColorsManager.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: ColorsManager.purple)),
          ),
        ],
      ),
    );
  }
}