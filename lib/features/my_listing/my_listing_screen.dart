import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseService.currentUser?.uid;

    if (userId == null) {
      return Center(child: Text(AppLocalizations.of(context)!.login));
    }

    return Scaffold(

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context),
        ],
        body: StreamBuilder<List<ItemModel>>(
          stream: FirebaseService.getUserItemsStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerList();
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: REdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: REdgeInsets.only(bottom: 12),
                  child: MyListingCard(
                    item: items[index],
                    onEdit: () => Navigator.pushNamed(
                      context,
                      Routes.editItem,
                      arguments: items[index],
                    ),
                    onDelete: () => _deleteItem(context, items[index]),
                    onToggleAvailability: () => _toggleAvailability(context, items[index]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      expandedHeight: 80.h,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: ColorsManager.gradientFor(context),
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: REdgeInsets.only(left: 20, bottom: 16),
          title: Row(
            children: [
              Container(
                padding: REdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                AppLocalizations.of(context)!.my_listing,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: REdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: REdgeInsets.only(bottom: 12),
        child: _ShimmerListingCard(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorsManager.purpleSoftFor(context),
                  ColorsManager.purpleSoftFor(context).withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 56.sp,
              color: ColorsManager.purpleFor(context),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            AppLocalizations.of(context)!.no_listings_yet,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.textFor(context),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add your first item to start trading',
            style: TextStyle(
              fontSize: 14.sp,
              color: ColorsManager.textSecondaryFor(context),
            ),
          ),
          SizedBox(height: 24.h),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.addItem),
            child: Container(
              padding: REdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: ColorsManager.gradientFor(context),
                ),
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: ColorsManager.purple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    AppLocalizations.of(context)!.add_item,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context, ItemModel item) async {
    final isInExchange = await _checkIfInExchange(item.id);

    if (isInExchange['active'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ColorsManager.cardFor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Container(
                padding: REdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_rounded, color: Colors.orange, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text('Cannot Delete', style: TextStyle(color: ColorsManager.textFor(context))),
            ],
          ),
          content: Text(
            'This item is in an active exchange and cannot be deleted.\n\n'
            'Please complete or cancel the exchange first.',
            style: TextStyle(color: ColorsManager.textSecondaryFor(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: TextStyle(color: ColorsManager.purpleFor(context))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, Routes.exchangesList);
              },
              child: Text('View Exchanges', style: TextStyle(color: ColorsManager.purpleFor(context))),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorsManager.cardFor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(AppLocalizations.of(context)!.delete_item, style: TextStyle(color: ColorsManager.textFor(context))),
        content: Text(AppLocalizations.of(context)!.confirm_delete, style: TextStyle(color: ColorsManager.textSecondaryFor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: ColorsManager.textSecondaryFor(context))),
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
      await FirebaseService.deleteItem(item.id);
      UiUtils.showToastMessage(
        AppLocalizations.of(context)!.item_deleted,
        Colors.green,
      );
    }
  }

  Future<void> _toggleAvailability(BuildContext context, ItemModel item) async {
    if (!item.isAvailable) {
      final exchangeStatus = await _checkIfInExchange(item.id);

      if (exchangeStatus['active'] == true) {
        _showCannotToggleDialog(
          context,
          'This item is in an active exchange and cannot be made available.\n\n'
          'Please complete or cancel the exchange first.',
        );
        return;
      }

      if (exchangeStatus['completed'] == true) {
        _showCannotToggleDialog(
          context,
          'This item has been exchanged and cannot be made available again.\n\n'
          'You can delete this item or keep it as a record of your past exchange.',
        );
        return;
      }
    }

    try {
      final updated = item.copyWith(isAvailable: !item.isAvailable);
      await FirebaseService.updateItem(updated);

      UiUtils.showToastMessage(
        updated.isAvailable ? 'Item is now visible' : 'Item is now hidden',
        Colors.green,
      );
    } catch (e) {
      print('Error toggling availability: $e');
      UiUtils.showToastMessage('Failed to update item', Colors.red);
    }
  }

  Future<Map<String, bool>> _checkIfInExchange(String itemId) async {
    try {
      final exchanges = await FirebaseService.getItemExchanges(itemId);
      final hasActive = exchanges.any((e) => e.status == ExchangeStatus.accepted);
      final hasCompleted = exchanges.any((e) => e.status == ExchangeStatus.completed);

      return {'active': hasActive, 'completed': hasCompleted};
    } catch (e) {
      print('Error checking exchanges: $e');
      return {'active': false, 'completed': false};
    }
  }

  void _showCannotToggleDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorsManager.cardFor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: REdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_rounded, color: Colors.orange, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Text('Cannot Change', style: TextStyle(color: ColorsManager.textFor(context))),
          ],
        ),
        content: Text(message, style: TextStyle(color: ColorsManager.textSecondaryFor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: ColorsManager.purpleFor(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, Routes.exchangesList);
            },
            child: Text('View Exchanges', style: TextStyle(color: ColorsManager.purpleFor(context))),
          ),
        ],
      ),
    );
  }
}

class _ShimmerListingCard extends StatefulWidget {
  @override
  State<_ShimmerListingCard> createState() => _ShimmerListingCardState();
}

class _ShimmerListingCardState extends State<_ShimmerListingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: REdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorsManager.cardFor(context),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.shadowFor(context),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _shimmerBox(80.w, 80.h, 12.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(150.w, 16.h, 4.r),
                    SizedBox(height: 8.h),
                    _shimmerBox(80.w, 20.h, 10.r),
                  ],
                ),
              ),
              _shimmerBox(32.w, 32.h, 16.r),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: [
            ColorsManager.shimmerBaseFor(context),
            ColorsManager.shimmerHighlightFor(context),
            ColorsManager.shimmerBaseFor(context),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class MyListingCard extends StatefulWidget {
  final ItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const MyListingCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  State<MyListingCard> createState() => _MyListingCardState();
}

class _MyListingCardState extends State<MyListingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: REdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.item.isAvailable ? ColorsManager.cardFor(context) : ColorsManager.backgroundFor(context),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: _isPressed ? ColorsManager.shadowFor(context) : ColorsManager.shadowFor(context),
                blurRadius: _isPressed ? 15 : 10,
                offset: Offset(0, _isPressed ? 6 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Item image
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: ColorsManager.shadowFor(context),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.item.imageUrls.isNotEmpty
                          ? Image.network(
                              widget.item.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                      if (!widget.item.isAvailable)
                        Container(
                          color: Colors.black.withOpacity(0.4),
                          child: Center(
                            child: Icon(
                              Icons.visibility_off_rounded,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: widget.item.isAvailable ? ColorsManager.textFor(context) : ColorsManager.textSecondaryFor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      widget.item.category.displayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ColorsManager.textSecondaryFor(context),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    FutureBuilder<List<ExchangeModel>>(
                      future: FirebaseService.getItemExchanges(widget.item.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return _buildStatusBadge(context, widget.item, null);
                        }
                        return _buildStatusBadge(context, widget.item, snapshot.data);
                      },
                    ),
                  ],
                ),
              ),
              // Menu button
              Container(
                decoration: BoxDecoration(
                  color: ColorsManager.dividerFor(context),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: PopupMenuButton<String>(
                  color: ColorsManager.cardFor(context),
                  icon: Icon(Icons.more_vert_rounded, color: ColorsManager.textSecondaryFor(context), size: 22.sp),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        widget.onEdit();
                        break;
                      case 'toggle':
                        widget.onToggleAvailability();
                        break;
                      case 'delete':
                        widget.onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18.sp, color: ColorsManager.purpleFor(context)),
                          SizedBox(width: 10.w),
                          Text(AppLocalizations.of(context)!.edit, style: TextStyle(color: ColorsManager.textFor(context))),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            widget.item.isAvailable ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 18.sp,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            widget.item.isAvailable
                                ? AppLocalizations.of(context)!.mark_unavailable
                                : AppLocalizations.of(context)!.mark_available,
                            style: TextStyle(color: ColorsManager.textFor(context)),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 18.sp, color: Colors.red),
                          SizedBox(width: 10.w),
                          Text(
                            AppLocalizations.of(context)!.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
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

  Widget _buildStatusBadge(BuildContext context, ItemModel item, List<ExchangeModel>? exchanges) {
    Color startColor;
    Color endColor;
    String label;
    IconData icon;

    if (item.isAvailable) {
      startColor = const Color(0xFF4CAF50);
      endColor = const Color(0xFF66BB6A);
      label = AppLocalizations.of(context)!.available;
      icon = Icons.check_circle_rounded;
    } else if (exchanges != null) {
      final hasActive = exchanges.any((e) => e.status == ExchangeStatus.accepted);
      final hasCompleted = exchanges.any((e) => e.status == ExchangeStatus.completed);

      if (hasActive) {
        startColor = Colors.orange;
        endColor = Colors.orangeAccent;
        label = 'In Exchange';
        icon = Icons.swap_horiz_rounded;
      } else if (hasCompleted) {
        startColor = const Color(0xFF2196F3);
        endColor = const Color(0xFF42A5F5);
        label = 'Exchanged';
        icon = Icons.check_circle_rounded;
      } else {
        startColor = Colors.grey;
        endColor = Colors.grey.shade400;
        label = AppLocalizations.of(context)!.unavailable;
        icon = Icons.visibility_off_rounded;
      }
    } else {
      startColor = Colors.grey;
      endColor = Colors.grey.shade400;
      label = AppLocalizations.of(context)!.unavailable;
      icon = Icons.visibility_off_rounded;
    }

    return Container(
      padding: REdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [startColor, endColor]),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.dividerFor(context),
            ColorsManager.backgroundFor(context),
          ],
        ),
      ),
      child: Icon(Icons.image_rounded, color: ColorsManager.textSecondaryFor(context), size: 32.sp),
    );
  }
}