// ============================================
// FILE: lib/features/my_listings/my_listings_screen.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/item_model.dart';
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
                onToggleAvailability: () => _toggleAvailability(items[index]),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context, ItemModel item) async {
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

  Future<void> _toggleAvailability(ItemModel item) async {
    final updated = item.copyWith(isAvailable: !item.isAvailable);
    await FirebaseService.updateItem(updated);
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
                  Container(
                    padding: REdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isAvailable
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      item.isAvailable
                          ? AppLocalizations.of(context)!.available
                          : AppLocalizations.of(context)!.unavailable,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: item.isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
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

  Widget _buildPlaceholder() {
    return Container(
      width: 80.w,
      height: 80.h,
      color: Colors.grey[200],
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}