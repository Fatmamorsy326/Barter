import 'dart:io';

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/core/widgets/login_required_sheet.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  if (widget.item.latitude != null && widget.item.longitude != null) ...[
                    SizedBox(height: 16.h),
                    _buildLocationMap(context),
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
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: widget.item.isExchanged ? Colors.grey : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: widget.item.isExchanged ? Colors.grey : Colors.red,
                      ),
                    ),
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
              const Icon(Icons.swap_horiz),
              SizedBox(width: 8.w),
              Text(
                widget.item.isAvailable
                    ? 'Make Offer'
                    : 'Item Not Available',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ============================================
// REPLACE _buildOwnerBottomBar in item_detail_screen.dart
// ============================================


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
      LoginRequiredSheet.show(context, 'Favorite Items');
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
      LoginRequiredSheet.show(context, 'Proposing Exchanges');
      return;
    }

    // Show options: Chat or Propose Exchange
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: REdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: REdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: REdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsManager.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: ColorsManager.purple,
                  ),
                ),
                title: const Text('Propose Exchange'),
                subtitle: const Text('Offer one of your items'),
                onTap: () => Navigator.pop(ctx, 'exchange'),
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: Container(
                  padding: REdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.blue,
                  ),
                ),
                title: const Text('Send Message'),
                subtitle: const Text('Chat with the owner'),
                onTap: () => Navigator.pop(ctx, 'chat'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'exchange') {
      // Navigate to propose exchange screen
      Navigator.pushNamed(
        context,
        Routes.proposeExchange,
        arguments: widget.item,
      );
    } else if (choice == 'chat') {
      // Original chat functionality
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


  Future<void> _deleteItem() async {
    if (widget.item.isExchanged) {
      _showLockedDialog();
      return;
    }

    // Async check for old data
    UiUtils.showLoading(context, false);
    final isLocked = await _checkIfInActiveExchange();
    UiUtils.hideDialog(context);

    if (isLocked) {
      _showLockedDialog();
      return;
    }

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

  Widget _buildLocationMap(BuildContext context) {
    final position = LatLng(widget.item.latitude!, widget.item.longitude!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            height: 200.h,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('item_location'),
                  position: position,
                  infoWindow: InfoWindow(title: widget.item.title),
                ),
              },
              liteModeEnabled: true, // Optimized for detail screens
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              onTap: (_) => _openInMaps(),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _openInMaps,
            icon: const Icon(Icons.directions, color: ColorsManager.purple),
            label: const Text(
              'Open in Maps',
              style: TextStyle(color: ColorsManager.purple, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              padding: REdgeInsets.symmetric(vertical: 12),
              backgroundColor: ColorsManager.purple.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openInMaps() async {
    final lat = widget.item.latitude;
    final lng = widget.item.longitude;

    if (lat == null || lng == null) return;

    try {
      final Uri mapsUri;

      if (Platform.isIOS) {
        // Try Apple Maps first (native iOS app)
        mapsUri = Uri.parse('maps://?q=$lat,$lng');

        if (await canLaunchUrl(mapsUri)) {
          await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
          return;
        }

        // Fallback to web URL
        final webUri = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        // Android: Try geo scheme first
        mapsUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

        if (await canLaunchUrl(mapsUri)) {
          await launchUrl(mapsUri, mode: LaunchMode.externalNonBrowserApplication);
          return;
        }

        // Fallback to Google Maps web URL
        final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error launching maps: $e');
      if (mounted) {
        UiUtils.showToastMessage('Could not open maps', Colors.red);
      }
    }
  }
//   -----------------------------------------------------------------------


// ============================================
// ADD THESE METHODS TO item_detail_screen.dart
// Place them with your other methods (after _deleteItem or before _formatDate)
// ============================================

  Future<bool> _checkIfInActiveExchange() async {
    try {
      // Get all exchanges for this item
      final exchanges = await FirebaseService.getItemExchanges(widget.item.id);

      // Check if any exchange is active (accepted but not completed)
      final hasActiveExchange = exchanges.any((exchange) =>
          exchange.status == 1 || exchange.status == 2 // Accepted or Completed
      );

      print('Item ${widget.item.id} has active exchange: $hasActiveExchange');
      return hasActiveExchange;
    } catch (e) {
      print('Error checking active exchanges: $e');
      return false;
    }
  }

  void _showCannotMakeAvailableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8.w),
            const Text('Item in Active Exchange'),
          ],
        ),
        content: const Text(
          'This item is currently in an active exchange and cannot be made available.\n\n'
              'You can make it available again after the exchange is completed or cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToExchanges();
            },
            child: const Text('View Exchanges'),
          ),
        ],
      ),
    );
  }

  void _navigateToExchanges() {
    Navigator.pushNamed(context, Routes.exchangesList);
  }

  // REPLACE your existing _toggleAvailability method with this:
  Future<void> _toggleAvailability() async {
    // Check if item is in an active exchange
    if (!widget.item.isAvailable) {
      final isInActiveExchange = await _checkIfInActiveExchange();

      if (isInActiveExchange) {
        _showCannotMakeAvailableDialog();
        return;
      }
    }

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

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.orange),
            SizedBox(width: 8.w),
            const Text('Cannot Delete Item'),
          ],
        ),
        content: const Text(
          'This item is part of a completed or active exchange and cannot be deleted to maintain exchange history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // REPLACE your existing _buildOwnerBottomBar method with this:
  Widget _buildOwnerBottomBar(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkIfInActiveExchange(),
      builder: (context, snapshot) {
        final isInActiveExchange = snapshot.data ?? false;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show warning if in active exchange
                if (isInActiveExchange) ...[
                  Container(
                    padding: REdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: REdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          color: Colors.orange,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'This item is in an active exchange',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToExchanges,
                          style: TextButton.styleFrom(
                            padding: REdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
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
                        onPressed: isInActiveExchange && !widget.item.isAvailable
                            ? null // Disable if in active exchange and unavailable
                            : _toggleAvailability,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.item.isAvailable
                              ? Colors.orange
                              : (isInActiveExchange ? Colors.grey : Colors.green),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isInActiveExchange && !widget.item.isAvailable
                                  ? Icons.lock
                                  : (widget.item.isAvailable
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              isInActiveExchange && !widget.item.isAvailable
                                  ? 'Locked'
                                  : (widget.item.isAvailable ? 'Hide' : 'Show'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}