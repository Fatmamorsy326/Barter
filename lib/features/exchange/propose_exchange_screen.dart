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
              onPressed: () => Navigator.pop(context),
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
                  _selectedItem,
                  'Your Item',
                  'Select below',
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
                  widget.requestedItem,
                  'Their Item',
                  widget.requestedItem.title,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemPreview(ItemModel? item, String label, String placeholder) {
    return Column(
      children: [
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: item != null ? ColorsManager.purpleFor(context) : ColorsManager.dividerFor(context),
              width: item != null ? 2 : 1,
            ),
            color: ColorsManager.backgroundFor(context),
          ),
          child: item != null && item.imageUrls.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Image.network(
              item.imageUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  Icons.image_not_supported_rounded,
                  size: 32.sp,
                  color: ColorsManager.textSecondaryFor(context),
                ),
              ),
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
          item?.title ?? placeholder,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: item != null ? FontWeight.bold : FontWeight.normal,
            color: item != null ? ColorsManager.textFor(context) : ColorsManager.textSecondaryFor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildItemSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: REdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Select Your Item to Offer',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.textFor(context),
            ),
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
            final isSelected = _selectedItem?.id == item.id;

            return GestureDetector(
              onTap: () => setState(() => _selectedItem = item),
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
                            item.condition.displayName,
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
        onPressed: _selectedItem == null ? null : _proposeExchange,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.purpleFor(context),
          foregroundColor: Colors.white,
          padding: REdgeInsets.symmetric(vertical: 18),
          elevation: 8,
          shadowColor: ColorsManager.purpleFor(context).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        ),
        child: Text(
          'Send Proposal',
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