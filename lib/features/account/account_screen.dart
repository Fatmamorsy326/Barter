// ============================================
// FILE: lib/features/account/account_screen.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = FirebaseService.currentUser;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _error = 'Not logged in';
        });
        return;
      }

      // Try to get user from Firestore
      UserModel? user = await FirebaseService.getUserById(currentUser.uid);

      // If no Firestore document, create one from Auth data
      if (user == null) {
        user = UserModel(
          uid: currentUser.uid,
          name: currentUser.displayName ??
              currentUser.email?.split('@').first ??
              'User',
          email: currentUser.email ?? '',
          photoUrl: currentUser.photoURL,
          createdAt: currentUser.metadata.creationTime ?? DateTime.now(),
        );

        // Try to save to Firestore (don't fail if this doesn't work)
        try {
          await FirebaseService.ensureUserDocument();
        } catch (e) {
          print('Could not create user document: $e');
        }
      }

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');

      // Fallback to Firebase Auth data
      final currentUser = FirebaseService.currentUser;
      if (currentUser != null) {
        setState(() {
          _user = UserModel(
            uid: currentUser.uid,
            name: currentUser.displayName ??
                currentUser.email?.split('@').first ??
                'User',
            email: currentUser.email ?? '',
            photoUrl: currentUser.photoURL,
            createdAt: currentUser.metadata.creationTime ?? DateTime.now(),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load user data';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context)!.account),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadUserData,
              child: Text(AppLocalizations.of(context)!.try_again),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'Please login to view your account',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, Routes.login);
              },
              child: Text(AppLocalizations.of(context)!.login),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: REdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(context, _user!),
            SizedBox(height: 24.h),
            _buildStatsCard(context),
            SizedBox(height: 24.h),
            _buildMenuItems(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50.r,
              backgroundColor: ColorsManager.purple.withOpacity(0.1),
              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null || user.photoUrl!.isEmpty
                  ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 36.sp,
                  color: ColorsManager.purple,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 18.r,
                backgroundColor: ColorsManager.purple,
                child: IconButton(
                  icon: Icon(Icons.camera_alt, size: 18.sp, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement photo upload
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          user.name,
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(
          user.email,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
        if (user.location != null && user.location!.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16.sp, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(
                user.location!,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
            ],
          ),
        ],
        SizedBox(height: 16.h),
        OutlinedButton(
          onPressed: () async {
            final result = await Navigator.pushNamed(context, Routes.editProfile);
            if (result == true) {
              _loadUserData(); // Refresh data after editing
            }
          },
          child: Text(AppLocalizations.of(context)!.edit_profile),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final userId = FirebaseService.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: REdgeInsets.all(16),
        child: StreamBuilder<List<ItemModel>>(
          stream: FirebaseService.getUserItemsStream(userId),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            final activeItems = items.where((i) => i.isAvailable).length;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  AppLocalizations.of(context)!.total_listings,
                  items.length.toString(),
                ),
                _buildDivider(),
                _buildStatItem(
                  AppLocalizations.of(context)!.active,
                  activeItems.toString(),
                ),
                _buildDivider(),
                _buildStatItem(
                  AppLocalizations.of(context)!.exchanges,
                  '0',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: ColorsManager.purple,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40.h,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.history,
          title: AppLocalizations.of(context)!.exchange_history,
          onTap: () => _showComingSoon(context, 'Exchange History'),
        ),
        _buildMenuItem(
          icon: Icons.favorite_outline,
          title: AppLocalizations.of(context)!.saved_items,
          onTap: () => Navigator.pushNamed(context, Routes.savedItems),
        ),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: AppLocalizations.of(context)!.help_support,
          onTap: () => _showHelpDialog(context),
        ),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: AppLocalizations.of(context)!.about,
          onTap: () => _showAboutDialog(context),
        ),
        SizedBox(height: 16.h),
        _buildMenuItem(
          icon: Icons.logout,
          title: AppLocalizations.of(context)!.logout,
          onTap: () => _logout(context),
          isDestructive: true,
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(feature),
        content: Text('This feature is coming soon!\n\nStay tuned for updates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: ColorsManager.purple),
            SizedBox(width: 12.w),
            Text(AppLocalizations.of(context)!.help_support),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need Help?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),
              _buildHelpItem(
                Icons.email,
                'Email Support',
                'support@barterapp.com',
              ),
              SizedBox(height: 8.h),
              _buildHelpItem(
                Icons.phone,
                'Phone Support',
                '+20 123 456 7890',
              ),
              SizedBox(height: 8.h),
              _buildHelpItem(
                Icons.language,
                'Website',
                'www.barterapp.com',
              ),
              SizedBox(height: 16.h),
              Text(
                'FAQs',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
              SizedBox(height: 8.h),
              Text('• How do I create a listing?'),
              Text('• How do I propose an exchange?'),
              Text('• Is Barter free to use?'),
              Text('• How do I report inappropriate content?'),
              SizedBox(height: 8.h),
              Text(
                'Visit our website for detailed FAQs and guides.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              ),
            ],
          ),
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

  Widget _buildHelpItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: ColorsManager.purple),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: ColorsManager.purple),
            SizedBox(width: 12.w),
            Text(AppLocalizations.of(context)!.about),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: REdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorsManager.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horizontal_circle,
                    size: 64.sp,
                    color: ColorsManager.purple,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Center(
                child: Text(
                  'Barter',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: ColorsManager.purple,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'About Barter',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Barter is a peer-to-peer exchange platform that allows users to trade items without money. Built with Flutter and Firebase.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16.h),
              Divider(),
              SizedBox(height: 8.h),
              _buildAboutRow('Developer', 'Barter Team'),
              SizedBox(height: 8.h),
              _buildAboutRow('Release Date', 'December 2024'),
              SizedBox(height: 8.h),
              _buildAboutRow('Platform', 'Android • iOS • Web'),
              SizedBox(height: 16.h),
              Divider(),
              SizedBox(height: 8.h),
              Center(
                child: Text(
                  '© 2024 Barter. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : ColorsManager.purple,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? Colors.red : Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.confirm_logout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    }
  }
}