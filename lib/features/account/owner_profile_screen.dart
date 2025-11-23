// ============================================
// FILE: lib/features/account/owner_profile_screen.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OwnerProfileScreen extends StatefulWidget {
  final String ownerId;

  const OwnerProfileScreen({super.key, required this.ownerId});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  UserModel? _owner;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    setState(() => _isLoading = true);

    try {
      final owner = await FirebaseService.getUserById(widget.ownerId);
      setState(() {
        _owner = owner;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading owner: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _owner == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            const Text('Failed to load profile'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: REdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24.h),
            _buildStatsCard(),
            SizedBox(height: 24.h),
            _buildOwnerItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50.r,
          backgroundColor: ColorsManager.purple.withOpacity(0.1),
          backgroundImage: _owner!.photoUrl != null && _owner!.photoUrl!.isNotEmpty
              ? NetworkImage(_owner!.photoUrl!)
              : null,
          child: _owner!.photoUrl == null || _owner!.photoUrl!.isEmpty
              ? Text(
            _owner!.name.isNotEmpty ? _owner!.name[0].toUpperCase() : 'U',
            style: TextStyle(
              fontSize: 36.sp,
              color: ColorsManager.purple,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
        SizedBox(height: 16.h),
        Text(
          _owner!.name,
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(
          _owner!.email,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
        if (_owner!.location != null && _owner!.location!.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16.sp, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(
                _owner!.location!,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
            ],
          ),
        ],
        if (_owner!.phone != null && _owner!.phone!.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, size: 16.sp, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(
                _owner!.phone!,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: REdgeInsets.all(16),
        child: StreamBuilder<List<ItemModel>>(
          stream: FirebaseService.getUserItemsStream(widget.ownerId),
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
                  'Member Since',
                  _formatDate(_owner!.createdAt),
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
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: ColorsManager.purple,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
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

  Widget _buildOwnerItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        StreamBuilder<List<ItemModel>>(
          stream: FirebaseService.getUserItemsStream(widget.ownerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data?.where((i) => i.isAvailable).toList() ?? [];

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: REdgeInsets.all(32),
                  child: Text(
                    'No items available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.75,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to item detail
                    Navigator.pop(context);
                    // Will go back to item detail
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12.r),
                            ),
                            child: item.imageUrls.isNotEmpty
                                ? Image.network(
                              item.imageUrls.first,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                            )
                                : Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: REdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  item.condition.displayName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  item.category.displayName,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: ColorsManager.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}