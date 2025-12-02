// ============================================
// FILE: lib/features/exchange/propose_exchange_screen.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/model/item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProposeExchangeScreen extends StatefulWidget {
  final ItemModel requestedItem; // Item they want

  const ProposeExchangeScreen({super.key, required this.requestedItem});

  @override
  State<ProposeExchangeScreen> createState() => _ProposeExchangeScreenState();
}

class _ProposeExchangeScreenState extends State<ProposeExchangeScreen> {
  final _notesController = TextEditingController();
  ItemModel? _selectedItem;
  List<ItemModel> _myItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyItems();
  }

  Future<void> _loadMyItems() async {
    final userId = FirebaseService.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Listen to user's available items
      FirebaseService.getUserItemsStream(userId).listen((items) {
        if (mounted) {
          setState(() {
            // Filter: only show available items that are not the requested item
            _myItems = items.where((item) =>
            item.isAvailable &&
                item.id != widget.requestedItem.id
            ).toList();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading items: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propose Exchange'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myItems.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExchangePreview(),
            SizedBox(height: 24.h),
            _buildItemSelection(),
            SizedBox(height: 24.h),
            _buildNotesField(),
            SizedBox(height: 32.h),
            _buildProposeButton(),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: REdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Items Available',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You need to add items to your inventory before proposing an exchange',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangePreview() {
    return Card(
      child: Padding(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exchange Preview',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildItemPreview(
                    _selectedItem,
                    'Your Item',
                    'Select an item to offer',
                  ),
                ),
                Padding(
                  padding: REdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.swap_horiz,
                    size: 32.sp,
                    color: ColorsManager.purple,
                  ),
                ),
                Expanded(
                  child: _buildItemPreview(
                    widget.requestedItem,
                    'Their Item',
                    widget.requestedItem.title,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemPreview(ItemModel? item, String label, String placeholder) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: item != null ? ColorsManager.purple : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: item != null && item.imageUrls.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.network(
              item.imageUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 40.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          )
              : Center(
            child: Icon(
              Icons.image,
              size: 40.sp,
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          item?.title ?? placeholder,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: item != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildItemSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Item to Offer',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: _myItems.length,
          itemBuilder: (context, index) {
            final item = _myItems[index];
            final isSelected = _selectedItem?.id == item.id;

            return GestureDetector(
              onTap: () => setState(() => _selectedItem = item),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? ColorsManager.purple : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(11.r),
                            ),
                            child: item.imageUrls.isNotEmpty
                                ? Image.network(
                              item.imageUrls.first,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 40.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                                : Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 40.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: REdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: ColorsManager.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
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
                              fontSize: 13.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            item.condition.displayName,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: 'Message (Optional)',
        hintText: 'Add a note to your exchange proposal...',
        alignLabelWithHint: true,
        prefixIcon: const Icon(Icons.message_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildProposeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedItem == null ? null : _proposeExchange,
        style: ElevatedButton.styleFrom(
          padding: REdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          'Propose Exchange',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _proposeExchange() async {
    if (_selectedItem == null) return;

    try {
      UiUtils.showLoading(context, false);

      await FirebaseService.createExchange(
        proposedTo: widget.requestedItem.ownerId,
        itemOfferedId: _selectedItem!.id,
        itemOfferedTitle: _selectedItem!.title,
        itemOfferedImage: _selectedItem!.imageUrls.first,
        itemRequestedId: widget.requestedItem.id,
        itemRequestedTitle: widget.requestedItem.title,
        itemRequestedImage: widget.requestedItem.imageUrls.first,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      UiUtils.hideDialog(context);
      UiUtils.showToastMessage(
        'Exchange proposal sent!',
        Colors.green,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      UiUtils.hideDialog(context);
      print('Error proposing exchange: $e');
      UiUtils.showToastMessage(
        'Failed to send proposal',
        Colors.red,
      );
    }
  }
}