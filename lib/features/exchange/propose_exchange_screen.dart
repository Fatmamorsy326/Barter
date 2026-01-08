import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:barter/model/item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProposeExchangeScreen extends StatefulWidget {
  final ItemModel requestedItem; // The initial item they want

  const ProposeExchangeScreen({super.key, required this.requestedItem});

  @override
  State<ProposeExchangeScreen> createState() => _ProposeExchangeScreenState();
}

class _ProposeExchangeScreenState extends State<ProposeExchangeScreen> {
  final _notesController = TextEditingController();
  
  // Items I am offering
  final List<ItemModel> _selectedItems = [];
  List<ItemModel> _myItems = [];
  
  // Items I am requesting (starts with the one passed in)
  late List<ItemModel> _requestedItems;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestedItems = [widget.requestedItem];
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
            // Filter: only show available items that are not the requested item (just in case)
            _myItems = items.where((item) => item.isAvailable).toList();
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
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.purpleFor(context))))
          : _myItems.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: REdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExchangePreview(),
            SizedBox(height: 32.h),
            _buildItemSelection(),
            SizedBox(height: 32.h),
            _buildNotesField(),
            SizedBox(height: 40.h),
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
        padding: REdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: REdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorsManager.purpleFor(context).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64.sp,
                color: ColorsManager.purpleFor(context),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Items Available',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: ColorsManager.textFor(context),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'You need to add items to your inventory before proposing an exchange',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ColorsManager.textSecondaryFor(context),
                fontSize: 16.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, Routes.addItem).then((_) {
                  _loadMyItems();
                });
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                padding: REdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: REdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Exchange Preview',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.textFor(context),
            ),
          ),
        ),
        Container(
          padding: REdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ColorsManager.cardFor(context),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.shadowFor(context),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildItemPreview(
                  _selectedItems,
                  'Your Offer',
                  'Select items',
                  isMySide: true,
                ),
              ),
              Padding(
                padding: REdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      width: 1,
                      height: 40.h,
                      color: ColorsManager.dividerFor(context),
                    ),
                    Padding(
                      padding: REdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        padding: REdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorsManager.purpleFor(context).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          size: 24.sp,
                          color: ColorsManager.purpleFor(context),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40.h,
                      color: ColorsManager.dividerFor(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildItemPreview(
                  _requestedItems,
                  'Their Item',
                  'Select items',
                  isMySide: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemPreview(List<ItemModel> items, String label, String placeholder, {required bool isMySide}) {
    final hasItems = items.isNotEmpty;
    final firstItem = hasItems ? items.first : null;
    final count = items.length;

    return GestureDetector(
      onTap: !isMySide ? _showOtherUserItems : null, // Allow adding more items on "Their" side
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: hasItems ? ColorsManager.purpleFor(context) : ColorsManager.dividerFor(context),
                    width: hasItems ? 2 : 1,
                  ),
                  color: ColorsManager.backgroundFor(context),
                ),
                child: hasItems && firstItem!.imageUrls.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        firstItem.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            size: 32.sp,
                            color: ColorsManager.textSecondaryFor(context),
                          ),
                        ),
                      ),
                      if (count > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: REdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorsManager.purpleFor(context),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '+${count - 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    : Center(
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 32.sp,
                    color: ColorsManager.textSecondaryFor(context).withOpacity(0.5),
                  ),
                ),
              ),
              // Add button overlay for "Their Item" side
              if (!isMySide)
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: IconButton(
                    onPressed: _showOtherUserItems,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: ColorsManager.purpleFor(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 16.sp),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: ColorsManager.textSecondaryFor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            hasItems ? (count > 1 ? '${firstItem!.title} & ${count - 1} more' : firstItem!.title) : placeholder,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: hasItems ? FontWeight.bold : FontWeight.normal,
              color: hasItems ? ColorsManager.textFor(context) : ColorsManager.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showOtherUserItems() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: ColorsManager.backgroundFor(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: REdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: REdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Items to Request',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: ColorsManager.textFor(context),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ItemModel>>(
                    stream: FirebaseService.getUserItemsStream(widget.requestedItem.ownerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No items found', style: TextStyle(color: ColorsManager.textSecondaryFor(context))));
                      }

                      final items = snapshot.data!.where((item) => item.isAvailable).toList();

                      return ListView.builder(
                        controller: controller,
                        padding: REdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = _requestedItems.any((i) => i.id == item.id);

                          return ListTile(
                            onTap: () {
                              setSheetState(() {
                                if (isSelected) {
                                  _requestedItems.removeWhere((i) => i.id == item.id);
                                } else {
                                  _requestedItems.add(item);
                                }
                              });
                              // Also update parent state to reflect changes in preview immediately
                              setState(() {}); 
                            },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: item.imageUrls.isNotEmpty
                                  ? Image.network(
                                      item.imageUrls.first,
                                      width: 50.w,
                                      height: 50.w,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 50.w,
                                      height: 50.w,
                                      color: ColorsManager.shimmerBaseFor(context),
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                            title: Text(item.title, style: TextStyle(color: ColorsManager.textFor(context))),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: ColorsManager.purpleFor(context))
                                : Icon(Icons.circle_outlined, color: ColorsManager.textSecondaryFor(context)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => setState(() {})); // Refresh parent when closed
  }

  Widget _buildItemSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: REdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Items to Offer',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.textFor(context),
                ),
              ),
              if (_selectedItems.isNotEmpty)
                Text(
                  '${_selectedItems.length} selected',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: ColorsManager.purpleFor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
          ),
          itemCount: _myItems.length,
          itemBuilder: (context, index) {
            final item = _myItems[index];
            final isSelected = _selectedItems.any((i) => i.id == item.id);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedItems.removeWhere((i) => i.id == item.id);
                  } else {
                    _selectedItems.add(item);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: ColorsManager.cardFor(context),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? ColorsManager.purpleFor(context) : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? ColorsManager.purpleFor(context).withOpacity(0.3)
                          : ColorsManager.shadowFor(context),
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18.r),
                            ),
                            child: item.imageUrls.isNotEmpty
                                ? Image.network(
                              item.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: ColorsManager.shimmerBaseFor(context),
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: ColorsManager.textSecondaryFor(context),
                                ),
                              ),
                            )
                                : Container(
                              color: ColorsManager.shimmerBaseFor(context),
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: ColorsManager.textSecondaryFor(context),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                color: ColorsManager.purpleFor(context).withOpacity(0.2),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(18.r),
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: REdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: ColorsManager.purpleFor(context),
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: REdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: ColorsManager.textFor(context),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            item.itemType == ItemType.service
                                ? (item.isRemote ? 'Remote Service' : 'On-site Service')
                                : item.condition.displayName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: ColorsManager.textSecondaryFor(context),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: REdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Message (Optional)',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.textFor(context),
            ),
          ),
        ),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: ColorsManager.textFor(context)),
          decoration: InputDecoration(
            hintText: 'Add a note to your exchange proposal...',
            hintStyle: TextStyle(color: ColorsManager.textSecondaryFor(context).withOpacity(0.5)),
            filled: true,
            fillColor: ColorsManager.cardFor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide(color: ColorsManager.purpleFor(context), width: 1.5),
            ),
            contentPadding: REdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildProposeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedItems.isEmpty || _requestedItems.isEmpty ? null : _proposeExchange,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.purpleFor(context),
          foregroundColor: Colors.white,
          padding: REdgeInsets.symmetric(vertical: 18),
          elevation: 8,
          shadowColor: ColorsManager.purpleFor(context).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        ),
        child: Text(
          'Send Proposal (${_selectedItems.length} for ${_requestedItems.length})',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Future<void> _proposeExchange() async {
    if (_selectedItems.isEmpty || _requestedItems.isEmpty) return;

    try {
      UiUtils.showLoading(context, false);

      final itemsOffered = _selectedItems.map((item) => ExchangeItem(
        itemId: item.id,
        title: item.title,
        imageUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
      )).toList();

      final itemsRequested = _requestedItems.map((item) => ExchangeItem(
        itemId: item.id,
        title: item.title,
        imageUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
      )).toList();

      await FirebaseService.createExchange(
        proposedTo: widget.requestedItem.ownerId,
        itemsOffered: itemsOffered,
        itemsRequested: itemsRequested,
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
      
      // Extract clean message
      String message = e.toString().replaceFirst('Exception: ', '');
      
      UiUtils.showToastMessage(
        message,
        Colors.red,
      );
    }
  }
}