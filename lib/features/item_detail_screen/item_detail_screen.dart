// ============================================
// FILE: lib/features/home/item_detail_screen.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ItemDetailScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseService.currentUser?.uid == item.ownerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: REdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(context),
                  SizedBox(height: 16.h),
                  _buildOwnerInfo(context),
                  SizedBox(height: 16.h),
                  _buildDetails(context),
                  SizedBox(height: 16.h),
                  _buildDescription(context),
                  if (item.preferredExchange != null) ...[
                    SizedBox(height: 16.h),
                    _buildPreferredExchange(context),
                  ],
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: isOwner ? null : _buildBottomBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: item.imageUrls.isNotEmpty
            ? PageView.builder(
          itemCount: item.imageUrls.length,
          itemBuilder: (_, index) => Image.network(
            item.imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, size: 80.sp),
            ),
          ),
        )
            : Container(
          color: Colors.grey[200],
          child: Icon(Icons.image, size: 80.sp, color: Colors.grey),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // Save to favorites
          },
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _buildTag(item.category.displayName, ColorsManager.purple),
            SizedBox(width: 8.w),
            _buildTag(item.condition.displayName, item.condition.color),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: REdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildOwnerInfo(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: FirebaseService.getUserById(item.ownerId),
      builder: (context, snapshot) {
        final owner = snapshot.data;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 24.r,
            backgroundColor: ColorsManager.purple.withOpacity(0.1),
            backgroundImage: owner?.photoUrl != null
                ? NetworkImage(owner!.photoUrl!)
                : null,
            child: owner?.photoUrl == null
                ? Text(
              owner?.name.isNotEmpty == true
                  ? owner!.name[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                color: ColorsManager.purple,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            )
                : null,
          ),
          title: Text(
            owner?.name ?? 'Loading...',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.location_on, size: 14.sp, color: Colors.grey),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  item.location,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.info_outline, color: ColorsManager.purple),
            onPressed: () {
              // View owner profile
            },
          ),
        );
      },
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Card(
      child: Padding(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.details,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            _buildDetailRow(
              AppLocalizations.of(context)!.category,
              item.category.displayName,
            ),
            _buildDetailRow(
              AppLocalizations.of(context)!.condition,
              item.condition.displayName,
            ),
            _buildDetailRow(
              AppLocalizations.of(context)!.posted,
              _formatDate(item.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.description,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Text(
          item.description,
          style: TextStyle(height: 1.5, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildPreferredExchange(BuildContext context) {
    return Card(
      color: ColorsManager.purple.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: REdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: REdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorsManager.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.swap_horiz, color: ColorsManager.purple),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.looking_for,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: ColorsManager.purple,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    item.preferredExchange!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => _startChat(context),
          style: ElevatedButton.styleFrom(
            padding: REdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.propose_exchange,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startChat(BuildContext context) async {
    try {
      UiUtils.showLoading(context, false);

      final chatId = await FirebaseService.createOrGetChat(
        item.ownerId,
        item.id,
        item.title,
      );

      UiUtils.hideDialog(context);
      Navigator.pushNamed(context, Routes.chatDetail, arguments: chatId);
    } catch (e) {
      UiUtils.hideDialog(context);
      UiUtils.showToastMessage('Failed to start chat', Colors.red);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}