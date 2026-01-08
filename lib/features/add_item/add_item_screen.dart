import 'dart:io';
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/features/add_item/enhanced_location_picker.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/services/image_upload_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barter/features/add_item/location_picker_screen.dart';

class AddItemScreen extends StatefulWidget {
  final ItemModel? itemToEdit;

  const AddItemScreen({super.key, this.itemToEdit});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _preferredExchangeController = TextEditingController();
  final _locationController = TextEditingController();

  ItemCategory _selectedCategory = ItemCategory.other;
  ItemCondition _selectedCondition = ItemCondition.good;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;

  bool get _isEditing => widget.itemToEdit != null;
  double? _latitude;
  double? _longitude;
  String? _detailedAddress;
  bool _dynamicExchangedStatus = false;
  ItemType _itemType = ItemType.product;
  bool _isRemote = false;

  bool get _isEditable =>
      _isEditing ? (!widget.itemToEdit!.isExchanged && !_dynamicExchangedStatus) : true;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadItemData();
      _checkExchangeStatus();
    }
  }



  Future<void> _checkExchangeStatus() async {
    try {
      final exchanges = await FirebaseService.getItemExchanges(widget.itemToEdit!.id);
      // Check for Accepted (1) or Completed (2) status
      final isLocked = exchanges.any((e) => e.status == 1 || e.status == 2);
      
      if (mounted && isLocked != _dynamicExchangedStatus) {
        setState(() => _dynamicExchangedStatus = isLocked);
      }
    } catch (e) {
      print('Error checking exchange status: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _preferredExchangeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: REdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isEditable)
                      Container(
                        width: double.infinity,
                        margin: REdgeInsets.only(bottom: 24),
                        padding: REdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.orange.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_rounded, color: Colors.orange),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'This item is currently part of an active exchange and cannot be edited or deleted.',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildTypeToggle(),
                    SizedBox(height: 24.h),
                    _buildImagePicker(),
                    SizedBox(height: 24.h),
                    _buildSectionTitle('Basic Information', Icons.info_outline_rounded),
                    SizedBox(height: 12.h),
                    _buildFormCard([
                      _buildTitleField(),
                      _buildDivider(),
                      _buildDescriptionField(),
                    ]),
                    if (_itemType == ItemType.product) ...[
                      SizedBox(height: 24.h),
                      _buildSectionTitle('Details', Icons.category_rounded),
                      SizedBox(height: 12.h),
                      _buildFormCard([
                        _buildCategoryDropdown(),
                        _buildDivider(),
                        _buildConditionDropdown(),
                        _buildDivider(),
                        _buildLocationField(),
                      ]),
                    ] else ...[
                      SizedBox(height: 24.h),
                      _buildSectionTitle('Service Details', Icons.settings_suggest_rounded),
                      SizedBox(height: 12.h),
                      _buildFormCard([
                        _buildRemoteToggle(),
                        if (!_isRemote) ...[
                          _buildDivider(),
                          _buildLocationField(),
                        ],
                      ]),
                    ],
                    SizedBox(height: 24.h),
                    _buildSectionTitle('Exchange Preferences', Icons.swap_horiz_rounded),
                    SizedBox(height: 12.h),
                    _buildFormCard([
                      _buildPreferredExchangeField(),
                    ]),
                    SizedBox(height: 32.h),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 80.h,
      leading: IconButton(
        icon: Container(
          padding: REdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18.sp),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsManager.gradientStart,
              ColorsManager.gradientEnd,
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: REdgeInsets.only(left: 60, bottom: 16),
          title: Row(
            children: [
              Icon(
                _isEditing ? Icons.edit_rounded : Icons.add_box_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Text(
                _isEditing
                    ? AppLocalizations.of(context)!.edit_item
                    : AppLocalizations.of(context)!.add_item,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: ColorsManager.purple, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: ColorsManager.textFor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.cardFor(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: ColorsManager.dividerFor(context)),
    );
  }

  // ==================== TYPE TOGGLE ====================

  Widget _buildTypeToggle() {
    if (!_isEditable) return const SizedBox.shrink();

    return Container(
      padding: REdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ColorsManager.cardFor(context),
        borderRadius: BorderRadius.circular(20.r),
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
          _buildTypeOption(ItemType.product, 'Product', Icons.shopping_bag_rounded),
          _buildTypeOption(ItemType.service, 'Service', Icons.handshake_rounded),
        ],
      ),
    );
  }

  Widget _buildTypeOption(ItemType type, String label, IconData icon) {
    bool isSelected = _itemType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _itemType = type;
            if (type == ItemType.service) {
              _selectedCategory = ItemCategory.service;
            } else {
              if (_selectedCategory == ItemCategory.service) {
                _selectedCategory = ItemCategory.other;
              }
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: REdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : ColorsManager.grey,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : ColorsManager.grey,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteToggle() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.language_rounded, color: ColorsManager.purple, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remote Service',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Can this be done online?',
                  style: TextStyle(fontSize: 12.sp, color: ColorsManager.grey),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isRemote,
            activeColor: ColorsManager.purple,
            onChanged: _isEditable ? (val) => setState(() => _isRemote = val) : null,
          ),
        ],
      ),
    );
  }

  // ==================== IMAGE PICKER ====================

  Widget _buildImagePicker() {
    final totalImages = _existingImageUrls.length + _newImages.length;

    return Container(
      padding: REdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_rounded, color: ColorsManager.purple, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)!.photos,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: REdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorsManager.purpleSoft,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '$totalImages/5',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ColorsManager.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            _itemType == ItemType.product
                ? 'Add up to 5 photos of your item'
                : 'Add work samples or portfolio images',
            style: TextStyle(fontSize: 12.sp, color: ColorsManager.grey),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 110.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (totalImages < 5) _buildAddPhotoButton(),
                ..._existingImageUrls.asMap().entries.map(
                      (entry) => _buildExistingImagePreview(entry.key, entry.value),
                ),
                ..._newImages.asMap().entries.map(
                      (entry) => _buildNewImagePreview(entry.key, entry.value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    if (!_isEditable) return SizedBox();
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 100.w,
        height: 100.h,
        margin: REdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsManager.purpleSoft,
              ColorsManager.purpleSoft.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: ColorsManager.purple.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: REdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorsManager.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_a_photo_rounded, color: ColorsManager.purple, size: 24.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              AppLocalizations.of(context)!.add_photo,
              style: TextStyle(
                color: ColorsManager.purple,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingImagePreview(int index, String url) {
    return Stack(
      children: [
        Container(
          width: 100.w,
          height: 100.h,
          margin: REdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.shadowFor(context),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.network(url, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 18,
          child: _isEditable
              ? GestureDetector(
                  onTap: () => setState(() => _existingImageUrls.removeAt(index)),
            child: Container(
              padding: REdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(Icons.close_rounded, size: 14.sp, color: Colors.white),
            ),
          ) : const SizedBox(),
        ),
        if (index == 0)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: REdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Main',
                style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewImagePreview(int index, File file) {
    final isMain = _existingImageUrls.isEmpty && index == 0;

    return Stack(
      children: [
        Container(
          width: 100.w,
          height: 100.h,
          margin: REdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.shadowFor(context),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 18,
          child: _isEditable
              ? GestureDetector(
                  onTap: () => setState(() => _newImages.removeAt(index)),
            child: Container(
              padding: REdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(Icons.close_rounded, size: 14.sp, color: Colors.white),
            ),
          ) : const SizedBox(),
        ),
        if (isMain)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: REdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Main',
                style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ColorsManager.cardFor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Padding(
            padding: REdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: ColorsManager.greyLight,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Add Photo',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPhotoOption(
                      icon: Icons.camera_alt_rounded,
                      label: AppLocalizations.of(context)!.camera,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildPhotoOption(
                      icon: Icons.photo_library_rounded,
                      label: AppLocalizations.of(context)!.gallery,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: REdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ColorsManager.purpleSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ColorsManager.purple, size: 28.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _newImages.add(File(image.path)));
      }
    } catch (e) {
      print('Error picking image: $e');
      UiUtils.showToastMessage('Failed to pick image', Colors.red);
    }
  }

  // ==================== FORM FIELDS ====================

  Widget _buildTitleField() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: TextFormField(
        controller: _titleController,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        readOnly: !_isEditable,
        style: TextStyle(fontSize: 15.sp),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Title is required';
          }
          if (value.trim().length < 3) {
            return 'Title must be at least 3 characters';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: _itemType == ItemType.product
              ? AppLocalizations.of(context)!.item_title
              : 'Service Title',
          hintText: _itemType == ItemType.product
              ? AppLocalizations.of(context)!.enter_title
              : 'Enter service name',
          prefixIcon: Icon(Icons.title_rounded, color: ColorsManager.purple),
          border: InputBorder.none,
          contentPadding: REdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        readOnly: !_isEditable,
        style: TextStyle(fontSize: 15.sp),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Description is required';
          }
          if (value.trim().length < 10) {
            return 'Description must be at least 10 characters';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.description,
          hintText: _itemType == ItemType.product
              ? AppLocalizations.of(context)!.enter_description
              : 'Describe the service you provide',
          prefixIcon: Padding(
            padding: REdgeInsets.only(bottom: 60),
            child: Icon(Icons.description_rounded, color: ColorsManager.purple),
          ),
          border: InputBorder.none,
          alignLabelWithHint: true,
          contentPadding: REdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: DropdownButtonFormField<ItemCategory>(
        value: _selectedCategory,
        style: TextStyle(fontSize: 15.sp, color: ColorsManager.textFor(context)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: ColorsManager.grey),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.category,
          prefixIcon: Icon(Icons.category_rounded, color: ColorsManager.purple),
          border: InputBorder.none,
          contentPadding: REdgeInsets.symmetric(vertical: 8),
        ),
        items: ItemCategory.values.where((cat) {
          if (_itemType == ItemType.product) {
            return cat != ItemCategory.service;
          }
          return true;
        }).map((cat) {
          return DropdownMenuItem(
            value: cat,
            child: Text(cat.displayName),
          );
        }).toList(),
        onChanged: _isEditable
            ? (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              }
            : null,
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: DropdownButtonFormField<ItemCondition>(
        value: _selectedCondition,
        style: TextStyle(fontSize: 15.sp, color: ColorsManager.textFor(context)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: ColorsManager.grey),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.condition,
          prefixIcon: Icon(Icons.star_rounded, color: ColorsManager.purple),
          border: InputBorder.none,
          contentPadding: REdgeInsets.symmetric(vertical: 8),
        ),
        items: ItemCondition.values.map((cond) {
          return DropdownMenuItem(
            value: cond,
            child: Text(cond.displayName),
          );
        }).toList(),
        onChanged: _isEditable
            ? (value) {
                if (value != null) {
                  setState(() => _selectedCondition = value);
                }
              }
            : null,
      ),
    );
  }





// Update the _buildLocationField method:

  Widget _buildLocationField() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _locationController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: 15.sp),
            readOnly: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Location is required';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: _itemType == ItemType.product
                  ? AppLocalizations.of(context)!.location
                  : 'Service Area / Location',
              hintText: _isRemote ? 'Available Remote (Optional location)' : 'Tap map icon to select',
              prefixIcon: Icon(Icons.location_on_rounded, color: ColorsManager.purple),
              suffixIcon: IconButton(
                icon: Container(
                  padding: REdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorsManager.purpleSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.map_rounded, color: ColorsManager.purple, size: 18.sp),
                ),
                onPressed: _isEditable ? _pickLocationFromMap : null,
              ),
              border: InputBorder.none,
              contentPadding: REdgeInsets.symmetric(vertical: 8),
            ),
          ),
          if (_detailedAddress != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14.sp, color: ColorsManager.grey),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    _detailedAddress!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: ColorsManager.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (_latitude != null && _longitude != null) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.my_location, size: 12.sp, color: ColorsManager.purple),
                SizedBox(width: 6.w),
                Text(
                  'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: ColorsManager.grey,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

// Update the _pickLocationFromMap method:

  void _pickLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedLocationPickerScreen(
          initialLocation: _latitude != null && _longitude != null
              ? LatLng(_latitude!, _longitude!)
              : null,
          initialAddress: _locationController.text.isNotEmpty
              ? _locationController.text
              : null,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _locationController.text = result['address'] ?? '';
        _detailedAddress = result['detailedAddress'];
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

// Update the _loadItemData method to include coordinates:

  void _loadItemData() {
    final item = widget.itemToEdit!;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _preferredExchangeController.text = item.preferredExchange ?? '';
    _locationController.text = item.location;
    _selectedCategory = item.category;
    _selectedCondition = item.condition;
    _existingImageUrls = List.from(item.imageUrls);

    // Load coordinates if available
    if (item.latitude != null) _latitude = item.latitude;
    if (item.longitude != null) _longitude = item.longitude;
    if (item.detailedAddress != null) _detailedAddress = item.detailedAddress;
    _itemType = item.itemType;
    _isRemote = item.isRemote;
  }

// Update the itemData in _submitItem to include coordinates:





  Widget _buildPreferredExchangeField() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: TextFormField(
        controller: _preferredExchangeController,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        maxLines: 2,
        readOnly: !_isEditable,
        style: TextStyle(fontSize: 15.sp),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.preferred_exchange,
          hintText: AppLocalizations.of(context)!.what_looking_for,
          prefixIcon: Padding(
            padding: REdgeInsets.only(bottom: 24),
            child: Icon(Icons.swap_horiz_rounded, color: ColorsManager.purple),
          ),
          border: InputBorder.none,
          alignLabelWithHint: true,
          contentPadding: REdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  // ==================== SUBMIT BUTTON ====================

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading || !_isEditable ? null : _submitItem,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: _isLoading || !_isEditable
              ? null
              : const LinearGradient(
                  colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                ),
          color: _isLoading || !_isEditable ? ColorsManager.greyLight : null,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: _isLoading || !_isEditable
              ? null
              : [
                  BoxShadow(
                    color: ColorsManager.purple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  height: 24.h,
                  width: 24.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: ColorsManager.purple,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isEditing ? Icons.save_rounded : Icons.publish_rounded,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      _isEditing
                          ? AppLocalizations.of(context)!.save_changes
                          : AppLocalizations.of(context)!.publish,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ==================== SUBMIT LOGIC ====================

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      UiUtils.showToastMessage(
        AppLocalizations.of(context)!.add_at_least_one_photo,
        Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseService.currentUser;
      if (user == null) {
        UiUtils.showToastMessage('Please login first', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      String ownerName = user.displayName ?? user.email?.split('@').first ?? 'User';

      List<String> allImageUrls = List.from(_existingImageUrls);

      if (_newImages.isNotEmpty) {
        try {
          final newUrls = await ImageUploadService.uploadMultipleImages(_newImages);
          allImageUrls.addAll(newUrls);
        } catch (e) {
          print('Error uploading images: $e');
          UiUtils.showToastMessage('Failed to upload images', Colors.red);
          setState(() => _isLoading = false);
          return;
        }
      }

      if (allImageUrls.isEmpty) {
        UiUtils.showToastMessage('Failed to upload images', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final itemData = {
        'ownerId': user.uid,
        'ownerName': ownerName,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrls': allImageUrls,
        'category': _selectedCategory.index,
        'condition': _selectedCondition.index,
        'preferredExchange': _preferredExchangeController.text.trim().isEmpty
            ? null
            : _preferredExchangeController.text.trim(),
        'location': _itemType == ItemType.service && _isRemote
            ? 'Remote'
            : _locationController.text.trim(),
        'latitude': _itemType == ItemType.service && _isRemote ? null : _latitude,
        'longitude': _itemType == ItemType.service && _isRemote ? null : _longitude,
        'detailedAddress': _itemType == ItemType.service && _isRemote ? null : _detailedAddress,
        'createdAt': DateTime.now().toIso8601String(),
        'isAvailable': true,
        'itemType': _itemType.index,
        'isRemote': _isRemote,
      };

      if (_isEditing) {
        await FirebaseService.updateItemDirect(widget.itemToEdit!.id, itemData);
        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.item_updated,
          Colors.green,
        );
      } else {
        await FirebaseService.addItemDirect(itemData);
        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.item_published,
          Colors.green,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error in submitItem: $e');
      UiUtils.showToastMessage(
        _isEditing
            ? AppLocalizations.of(context)!.failed_to_update
            : AppLocalizations.of(context)!.failed_to_publish,
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}