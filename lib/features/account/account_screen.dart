import 'dart:io';
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:barter/services/image_upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

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

      UserModel? user = await FirebaseService.getUserById(currentUser.uid);

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
      backgroundColor: ColorsManager.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.purple),
        ),
      );
    }

    if (_error != null && _user == null) {
      return _buildErrorState();
    }

    if (_user == null) {
      return _buildLoginState();
    }

    return RefreshIndicator(
      color: ColorsManager.purple,
      onRefresh: _loadUserData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverHeader(context, _user!),
          SliverToBoxAdapter(
            child: Padding(
              padding: REdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                children: [
                  SizedBox(height: 24.h),
                  _buildStatsCard(context),
                  SizedBox(height: 24.h),
                  _buildMenuSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, UserModel user) {
    return SliverToBoxAdapter(
      child: Container(
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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top bar with settings
              Padding(
                padding: REdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.settings_outlined, color: Colors.white, size: 22.sp),
                        onPressed: () => Navigator.pushNamed(context, Routes.settings),
                      ),
                    ),
                  ],
                ),
              ),
              // Profile info
              Padding(
                padding: REdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    // Avatar with camera button
                    Stack(
                      children: [
                        Container(
                          width: 100.w,
                          height: 100.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? Image.network(
                                    user.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(user),
                                  )
                                : _buildAvatarPlaceholder(user),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _updateProfilePhoto,
                            child: Container(
                              width: 36.w,
                              height: 36.h,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFFFFF), Color(0xFFF0F0F0)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 18.sp,
                                color: ColorsManager.purple,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
                    ),
                    if (user.location != null && user.location!.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded, size: 16.sp, color: Colors.white70),
                          SizedBox(width: 4.w),
                          Text(
                            user.location!,
                            style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 16.h),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.pushNamed(context, Routes.editProfile);
                        if (result == true) {
                          _loadUserData();
                        }
                      },
                      child: Container(
                        padding: REdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, color: Colors.white, size: 16.sp),
                            SizedBox(width: 8.w),
                            Text(
                              AppLocalizations.of(context)!.edit_profile,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 40.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final userId = FirebaseService.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: REdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsManager.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: StreamBuilder<List<ItemModel>>(
        stream: FirebaseService.getUserItemsStream(userId),
        builder: (context, itemsSnapshot) {
          final items = itemsSnapshot.data ?? [];
          final activeItems = items.where((i) => i.isAvailable).length;

          return StreamBuilder<List<ExchangeModel>>(
            stream: FirebaseService.getUserExchangesStream(userId),
            builder: (context, exchangesSnapshot) {
              final exchanges = exchangesSnapshot.data ?? [];
              final completedExchanges = exchanges
                  .where((e) => e.status == ExchangeStatus.completed)
                  .length;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.inventory_2_rounded,
                    value: items.length.toString(),
                    label: AppLocalizations.of(context)!.total_listings,
                    color: ColorsManager.purple,
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    icon: Icons.check_circle_rounded,
                    value: activeItems.toString(),
                    label: AppLocalizations.of(context)!.active,
                    color: Colors.green,
                  ),
                  _buildStatDivider(),
                  _buildStatItem(
                    icon: Icons.swap_horiz_rounded,
                    value: completedExchanges.toString(),
                    label: AppLocalizations.of(context)!.exchanges,
                    color: Colors.orange,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: REdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22.sp),
        ),
        SizedBox(height: 10.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: ColorsManager.black,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: ColorsManager.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 60.h,
      width: 1,
      color: ColorsManager.greyLight,
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuCard(
          children: [
            _buildMenuItem(
              icon: Icons.swap_horiz_rounded,
              title: AppLocalizations.of(context)!.exchange_history,
              subtitle: 'View your exchange history',
              onTap: () => Navigator.pushNamed(context, Routes.exchangesList),
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              icon: Icons.favorite_rounded,
              title: AppLocalizations.of(context)!.saved_items,
              subtitle: 'Items you saved',
              iconColor: Colors.red,
              onTap: () => Navigator.pushNamed(context, Routes.savedItems),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _buildMenuCard(
          children: [
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: AppLocalizations.of(context)!.help_support,
              subtitle: 'Get help or contact us',
              onTap: () => _showHelpDialog(context),
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              icon: Icons.info_outline_rounded,
              title: AppLocalizations.of(context)!.about,
              subtitle: 'About Barter app',
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _buildMenuCard(
          children: [
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: AppLocalizations.of(context)!.logout,
              subtitle: 'Sign out of your account',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
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
                  color: (iconColor ?? ColorsManager.purple).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? ColorsManager.purple,
                  size: 22.sp,
                ),
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
                        color: textColor ?? ColorsManager.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ColorsManager.grey,
                      ),
                    ),
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

  Widget _buildMenuDivider() {
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: ColorsManager.greyUltraLight),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, size: 56.sp, color: Colors.red),
          ),
          SizedBox(height: 24.h),
          Text(
            _error!,
            style: TextStyle(fontSize: 16.sp, color: ColorsManager.grey),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _loadUserData,
            child: Container(
              padding: REdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                AppLocalizations.of(context)!.try_again,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorsManager.purpleSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_off_outlined, size: 56.sp, color: ColorsManager.purple),
          ),
          SizedBox(height: 24.h),
          Text(
            'Please login to view your account',
            style: TextStyle(fontSize: 16.sp, color: ColorsManager.grey),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, Routes.login),
            child: Container(
              padding: REdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                AppLocalizations.of(context)!.login,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PHOTO UPLOAD ====================

  Future<void> _updateProfilePhoto() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
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
                  'Update Profile Photo',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPhotoOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    ),
                    _buildPhotoOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    ),
                    if (_user?.photoUrl != null && _user!.photoUrl!.isNotEmpty)
                      _buildPhotoOption(
                        icon: Icons.delete_rounded,
                        label: 'Remove',
                        color: Colors.red,
                        onTap: () => Navigator.pop(ctx, null),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );

    if (source == null && _user?.photoUrl != null) {
      await _removeProfilePhoto();
      return;
    }

    if (source != null) {
      await _pickAndUploadPhoto(source);
    }
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: REdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? ColorsManager.purple).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? ColorsManager.purple, size: 28.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: color ?? ColorsManager.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showHelpDialog(BuildContext context) {
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
              child: Icon(Icons.help_outline_rounded, color: ColorsManager.purple, size: 20.sp),
            ),
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
              SizedBox(height: 16.h),
              _buildHelpItem(Icons.email_rounded, 'Email Support', 'support@barterapp.com'),
              SizedBox(height: 12.h),
              _buildHelpItem(Icons.phone_rounded, 'Phone Support', '+20 123 456 7890'),
              SizedBox(height: 12.h),
              _buildHelpItem(Icons.language_rounded, 'Website', 'www.barterapp.com'),
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

  Widget _buildHelpItem(IconData icon, String label, String value) {
    return Container(
      padding: REdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorsManager.greyUltraLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: ColorsManager.purple),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.sp, color: ColorsManager.grey)),
                Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
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
              Text('Version 1.0.0', style: TextStyle(color: ColorsManager.grey)),
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

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
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

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      UiUtils.showLoading(context, false);

      final File imageFile = File(image.path);
      final imageUrl = await ImageUploadService.uploadImage(imageFile);

      if (imageUrl == null || imageUrl.isEmpty) {
        if (!mounted) return;
        UiUtils.hideDialog(context);
        UiUtils.showToastMessage('Failed to upload photo', Colors.red);
        return;
      }

      final userId = FirebaseService.currentUser?.uid;
      if (userId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'photoUrl': imageUrl});
        } catch (e) {
          print('Firestore update warning: $e');
        }
      }

      try {
        await FirebaseService.currentUser?.updatePhotoURL(imageUrl);
      } catch (e) {
        print('Firebase Auth update warning: $e');
      }

      if (!mounted) return;
      UiUtils.hideDialog(context);
      UiUtils.showToastMessage('Profile photo updated!', Colors.green);

      await _loadUserData();
    } catch (e) {
      if (!mounted) return;

      try {
        UiUtils.hideDialog(context);
      } catch (_) {}

      UiUtils.showToastMessage('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _removeProfilePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (!mounted) return;
        UiUtils.showLoading(context, false);

        final userId = FirebaseService.currentUser?.uid;
        if (userId != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({'photoUrl': ''});
          } catch (e) {
            print('Firestore update warning: $e');
          }
        }

        try {
          await FirebaseService.currentUser?.updatePhotoURL(null);
        } catch (e) {
          print('Firebase Auth update warning: $e');
        }

        if (!mounted) return;
        UiUtils.hideDialog(context);
        UiUtils.showToastMessage('Profile photo removed', Colors.green);

        await _loadUserData();
      } catch (e) {
        if (!mounted) return;

        try {
          UiUtils.hideDialog(context);
        } catch (_) {}

        UiUtils.showToastMessage('Error: ${e.toString()}', Colors.red);
      }
    }
  }
}