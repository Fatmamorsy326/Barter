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
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isFavorite = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final userId = FirebaseService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isFavorite = false);
      return;
    }

    try {
      final isSaved = await FirebaseService.isItemSaved(userId, widget.item.id);
      setState(() => _isFavorite = isSaved);
    } catch (e) {
      print('Error checking favorite: $e');
      setState(() => _isFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseService.currentUser?.uid == widget.item.ownerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isOwner),
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
                  if (widget.item.preferredExchange != null) ...[
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
      bottomSheet: isOwner ? _buildOwnerBottomBar(context) : _buildBottomBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isOwner) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: widget.item.imageUrls.isNotEmpty
            ? Stack(
          children: [
            PageView.builder(
              itemCount: widget.item.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (_, index) => Image.network(
                widget.item.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, size: 80.sp),
                ),
              ),
            ),
            // Image indicator dots
            if (widget.item.imageUrls.length > 1)
              Positioned(
                bottom: 16.h,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.item.imageUrls.length,
                        (index) => Container(
                      margin: REdgeInsets.symmetric(horizontal: 4),
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        )
            : Container(
          color: Colors.grey[200],
          child: Icon(Icons.image, size: 80.sp, color: Colors.grey),
        ),
      ),
      actions: [
        // Share button
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareItem(),
          tooltip: 'Share',
        ),
        // Favorite button
        if (!isOwner)
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () => _toggleFavorite(),
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        // More options for owner
        if (isOwner)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editItem();
                  break;
                case 'toggle':
                  _toggleAvailability();
                  break;
                case 'delete':
                  _deleteItem();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: ColorsManager.purple),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      widget.item.isAvailable ? Icons.visibility_off : Icons.visibility,
                      color: ColorsManager.purple,
                    ),
                    const SizedBox(width: 12),
                    Text(widget.item.isAvailable ? 'Mark Unavailable' : 'Mark Available'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.item.title,
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              ),
            ),
            if (!widget.item.isAvailable)
              Container(
                padding: REdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Unavailable',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _buildTag(widget.item.category.displayName, ColorsManager.purple),
            SizedBox(width: 8.w),
            _buildTag(widget.item.condition.displayName, widget.item.condition.color),
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
      future: FirebaseService.getUserById(widget.item.ownerId),
      builder: (context, snapshot) {
        final owner = snapshot.data;
        final isOwner = FirebaseService.currentUser?.uid == widget.item.ownerId;

        return Card(
          child: ListTile(
            contentPadding: REdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24.r,
              backgroundColor: ColorsManager.purple.withOpacity(0.1),
              backgroundImage: owner?.photoUrl != null && owner!.photoUrl!.isNotEmpty
                  ? NetworkImage(owner.photoUrl!)
                  : null,
              child: owner?.photoUrl == null || owner!.photoUrl!.isEmpty
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
                    widget.item.location,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: isOwner
                ? null
                : IconButton(
              icon: Icon(Icons.info_outline, color: ColorsManager.purple),
              onPressed: () => _showOwnerProfile(owner),
              tooltip: 'View profile',
            ),
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
              widget.item.category.displayName,
            ),
            _buildDetailRow(
              AppLocalizations.of(context)!.condition,
              widget.item.condition.displayName,
            ),
            _buildDetailRow(
              AppLocalizations.of(context)!.posted,
              _formatDate(widget.item.createdAt),
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
          widget.item.description,
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
                    widget.item.preferredExchange!,
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
          onPressed: widget.item.isAvailable ? () => _startChat(context) : null,
          style: ElevatedButton.styleFrom(
            padding: REdgeInsets.symmetric(vertical: 14),
            backgroundColor: widget.item.isAvailable ? null : Colors.grey,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline),
              SizedBox(width: 8.w),
              Text(
                widget.item.isAvailable
                    ? AppLocalizations.of(context)!.propose_exchange
                    : 'Item Not Available',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerBottomBar(BuildContext context) {
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _editItem,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit),
                    SizedBox(width: 8.w),
                    const Text('Edit'),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.item.isAvailable ? Colors.orange : Colors.green,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.item.isAvailable ? Icons.visibility_off : Icons.visibility),
                    SizedBox(width: 8.w),
                    Text(widget.item.isAvailable ? 'Hide' : 'Show'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _shareItem() async {
    try {
      final text = '''
Check out this item on Barter!

${widget.item.title}

${widget.item.description}

Category: ${widget.item.category.displayName}
Condition: ${widget.item.condition.displayName}
Location: ${widget.item.location}

#BarterApp #Exchange
      '''.trim();

      await Share.share(text);
    } catch (e) {
      print('Error sharing: $e');
      UiUtils.showToastMessage('Failed to share item', Colors.red);
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = FirebaseService.currentUser?.uid;

    if (userId == null) {
      UiUtils.showToastMessage('Please login first', Colors.red);
      Navigator.pushNamed(context, Routes.login);
      return;
    }

    try {
      final newState = await FirebaseService.toggleSavedItem(userId, widget.item.id);

      setState(() => _isFavorite = newState);

      UiUtils.showToastMessage(
        newState ? 'Added to saved items' : 'Removed from saved items',
        Colors.green,
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      UiUtils.showToastMessage('Failed to update saved items', Colors.red);
    }
  }

  void _showOwnerProfile(UserModel? owner) {
    if (owner == null) return;

    Navigator.pushNamed(
      context,
      Routes.ownerProfile,
      arguments: widget.item.ownerId,
    );
  }

  Future<void> _startChat(BuildContext context) async {
    final currentUser = FirebaseService.currentUser;

    if (currentUser == null) {
      UiUtils.showToastMessage('Please login first', Colors.red);
      Navigator.pushReplacementNamed(context, Routes.login);
      return;
    }

    try {
      UiUtils.showLoading(context, false);

      final chatId = await FirebaseService.createOrGetChat(
        widget.item.ownerId,
        widget.item.id,
        widget.item.title,
      );

      UiUtils.hideDialog(context);
      Navigator.pushNamed(context, Routes.chatDetail, arguments: chatId);
    } catch (e) {
      UiUtils.hideDialog(context);
      print('Error starting chat: $e');
      UiUtils.showToastMessage('Failed to start chat', Colors.red);
    }
  }

  void _editItem() {
    Navigator.pushNamed(
      context,
      Routes.editItem,
      arguments: widget.item,
    ).then((result) {
      if (result == true) {
        // Item was updated, refresh the screen
        Navigator.pop(context, true);
      }
    });
  }

  Future<void> _toggleAvailability() async {
    try {
      final updatedItem = widget.item.copyWith(
        isAvailable: !widget.item.isAvailable,
      );

      await FirebaseService.updateItem(updatedItem);

      UiUtils.showToastMessage(
        updatedItem.isAvailable ? 'Item is now visible' : 'Item is now hidden',
        Colors.green,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error toggling availability: $e');
      UiUtils.showToastMessage('Failed to update item', Colors.red);
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${widget.item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        UiUtils.showLoading(context, false);
        await FirebaseService.deleteItem(widget.item.id);
        UiUtils.hideDialog(context);
        UiUtils.showToastMessage('Item deleted successfully', Colors.green);

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        UiUtils.hideDialog(context);
        print('Error deleting item: $e');
        UiUtils.showToastMessage('Failed to delete item', Colors.red);
      }
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