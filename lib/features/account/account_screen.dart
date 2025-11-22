
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

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.account),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: FirebaseService.getUserById(FirebaseService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return Center(child: Text(AppLocalizations.of(context)!.error_occurred));
          }

          return SingleChildScrollView(
            padding: REdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(context, user),
                SizedBox(height: 24.h),
                _buildStatsCard(context),
                SizedBox(height: 24.h),
                _buildMenuItems(context),
              ],
            ),
          );
        },
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
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 36.sp,
                  color: ColorsManager.purple,
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
                  onPressed: () {},
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
        if (user.location != null) ...[
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
          onPressed: () => Navigator.pushNamed(context, Routes.editProfile),
          child: Text(AppLocalizations.of(context)!.edit_profile),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: REdgeInsets.all(16),
        child: StreamBuilder<List<ItemModel>>(
          stream: FirebaseService.getUserItemsStream(
            FirebaseService.currentUser!.uid,
          ),
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
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.favorite_outline,
          title: AppLocalizations.of(context)!.saved_items,
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: AppLocalizations.of(context)!.help_support,
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: AppLocalizations.of(context)!.about,
          onTap: () {},
        ),
        SizedBox(height: 16.h),
        _buildMenuItem(
          icon: Icons.logout,
          title: AppLocalizations.of(context)!.logout,
          onTap: () => _logout(context),
          isDestructive: true,
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
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
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
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }
}