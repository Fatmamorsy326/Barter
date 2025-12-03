// ============================================
// FILE: lib/features/my_listings/my_listings_screen.dart (UPDATED)
// ============================================

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context)!.my_listing),
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: FirebaseService.getUserItemsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    AppLocalizations.of(context)!.no_listings_yet,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, Routes.addItem),
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.add_item),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: REdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return MyListingCard(
                item: items[index],
                onEdit: () => Navigator.pushNamed(
                  context,
                  Routes.editItem,
                  arguments: items[index],
                ),
                onDelete: () => _deleteItem(context, items[index]),
                onToggleAvailability: () => _toggleAvailability(context, items[index]),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context, ItemModel item) async {
    // Check if item is in active exchange before allowing delete
    final isInExchange = await _checkIfInExchange(item.id);

    if (isInExchange['active'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.orange, size: 24.sp),
              SizedBox(width: 8.w),
              const Text('Cannot Delete'),
            ],
          ),
          content: const Text(
            'This item is in an active exchange and cannot be deleted.\n\n'
                'Please complete or cancel the exchange first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, Routes.exchangesList);
              },
              child: const Text('View Exchanges'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete_item),
        content: Text(AppLocalizations.of(context)!.confirm_delete),
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
      await FirebaseService.deleteItem(item.id);
      UiUtils.showToastMessage(
        AppLocalizations.of(context)!.item_deleted,
        Colors.green,
      );
    }
  }

  Future<void> _toggleAvailability(BuildContext context, ItemModel item) async {
    // If trying to make item available, check if it's in an exchange
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

    // Proceed with toggle
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

      return {
        'active': hasActive,
        'completed': hasCompleted,
      };
    } catch (e) {
      print('Error checking exchanges: $e');
      return {
        'active': false,
        'completed': false,
      };
    }
  }

  void _showCannotToggleDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Cannot Change Status'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, Routes.exchangesList);
            },
            child: const Text('View Exchanges'),
          ),
        ],
      ),
    );
  }
}

class MyListingCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      margin: REdgeInsets.only(bottom: 12),
      child: Padding(
        padding: REdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: item.imageUrls.isNotEmpty
                  ? Image.network(
                item.imageUrls.first,
                width: 80.w,
                height: 80.h,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
                  : _buildPlaceholder(),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Status badge with exchange info
                  FutureBuilder<List<ExchangeModel>>(
                    future: FirebaseService.getItemExchanges(item.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return _buildStatusBadge(context,item, null);
                      }
                      return _buildStatusBadge(context,item, snapshot.data);
                    },
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'toggle':
                    onToggleAvailability();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(AppLocalizations.of(context)!.edit),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    item.isAvailable
                        ? AppLocalizations.of(context)!.mark_unavailable
                        : AppLocalizations.of(context)!.mark_available,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    AppLocalizations.of(context)!.delete,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context,ItemModel item, List<ExchangeModel>? exchanges) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (item.isAvailable) {
      bgColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      label = AppLocalizations.of(context)!.available;
      icon = Icons.check_circle;
    } else if (exchanges != null) {
      final hasActive = exchanges.any((e) => e.status == ExchangeStatus.accepted);
      final hasCompleted = exchanges.any((e) => e.status == ExchangeStatus.completed);

      if (hasActive) {
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'In Exchange';
        icon = Icons.swap_horiz;
      } else if (hasCompleted) {
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        label = 'Exchanged';
        icon = Icons.check_circle;
      } else {
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = AppLocalizations.of(context)!.unavailable;
        icon = Icons.visibility_off;
      }
    } else {
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      label = AppLocalizations.of(context)!.unavailable;
      icon = Icons.visibility_off;
    }

    return Container(
      padding: REdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: textColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80.w,
      height: 80.h,
      color: Colors.grey[200],
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}