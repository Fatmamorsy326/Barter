// ============================================
// FILE: lib/features/add_item/add_item_screen.dart
// ============================================

import 'dart:io';
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/services/image_upload_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadItemData();
    }
  }

  void _loadItemData() {
    final item = widget.itemToEdit!;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _preferredExchangeController.text = item.preferredExchange ?? '';
    _locationController.text = item.location;
    _selectedCategory = item.category;
    _selectedCondition = item.condition;
    _existingImageUrls = List.from(item.imageUrls);
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
      appBar: AppBar(
        title: Text(
          _isEditing
              ? AppLocalizations.of(context)!.edit_item
              : AppLocalizations.of(context)!.add_item,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: REdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              SizedBox(height: 24.h),
              _buildTitleField(),
              SizedBox(height: 16.h),
              _buildDescriptionField(),
              SizedBox(height: 16.h),
              _buildCategoryDropdown(),
              SizedBox(height: 16.h),
              _buildConditionDropdown(),
              SizedBox(height: 16.h),
              _buildLocationField(),
              SizedBox(height: 16.h),
              _buildPreferredExchangeField(),
              SizedBox(height: 32.h),
              _buildSubmitButton(),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== IMAGE PICKER ====================

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.photos,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4.h),
        Text(
          'Add up to 5 photos of your item',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 110.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (_existingImageUrls.length + _newImages.length < 5)
                _buildAddPhotoButton(),
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
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 100.w,
        height: 100.h,
        margin: REdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(color: ColorsManager.purple, width: 2),
          borderRadius: BorderRadius.circular(12.r),
          color: ColorsManager.purple.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: ColorsManager.purple, size: 32.sp),
            SizedBox(height: 4.h),
            Text(
              AppLocalizations.of(context)!.add_photo,
              style: TextStyle(
                color: ColorsManager.purple,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
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
            borderRadius: BorderRadius.circular(12.r),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 16,
          child: GestureDetector(
            onTap: () => setState(() => _existingImageUrls.removeAt(index)),
            child: Container(
              padding: REdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16.sp, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImagePreview(int index, File file) {
    return Stack(
      children: [
        Container(
          width: 100.w,
          height: 100.h,
          margin: REdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 16,
          child: GestureDetector(
            onTap: () => setState(() => _newImages.removeAt(index)),
            child: Container(
              padding: REdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16.sp, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
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
              ListTile(
                leading: const Icon(Icons.camera_alt, color: ColorsManager.purple),
                title: Text(AppLocalizations.of(context)!.camera),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: ColorsManager.purple),
                title: Text(AppLocalizations.of(context)!.gallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
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
    return TextFormField(
      controller: _titleController,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
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
        labelText: AppLocalizations.of(context)!.item_title,
        hintText: AppLocalizations.of(context)!.enter_title,
        prefixIcon: const Icon(Icons.title),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
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
        hintText: AppLocalizations.of(context)!.enter_description,
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ItemCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.category,
        prefixIcon: const Icon(Icons.category_outlined),
      ),
      items: ItemCategory.values.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text(cat.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
    );
  }

  Widget _buildConditionDropdown() {
    return DropdownButtonFormField<ItemCondition>(
      value: _selectedCondition,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.condition,
        prefixIcon: const Icon(Icons.star_outline),
      ),
      items: ItemCondition.values.map((cond) {
        return DropdownMenuItem(
          value: cond,
          child: Text(cond.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCondition = value);
        }
      },
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Location is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.location,
        hintText: AppLocalizations.of(context)!.enter_location,
        prefixIcon: const Icon(Icons.location_on_outlined),
      ),
    );
  }

  Widget _buildPreferredExchangeField() {
    return TextFormField(
      controller: _preferredExchangeController,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.preferred_exchange,
        hintText: AppLocalizations.of(context)!.what_looking_for,
        prefixIcon: const Icon(Icons.swap_horiz),
        alignLabelWithHint: true,
      ),
    );
  }

  // ==================== SUBMIT BUTTON ====================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitItem,
        child: _isLoading
            ? SizedBox(
          height: 20.h,
          width: 20.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          _isEditing
              ? AppLocalizations.of(context)!.save_changes
              : AppLocalizations.of(context)!.publish,
        ),
      ),
    );
  }

  // ==================== SUBMIT LOGIC ====================

  Future<void> _submitItem() async {
    print('=== Starting submit ===');

    // Validate form
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    // Check for images
    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      UiUtils.showToastMessage(
        AppLocalizations.of(context)!.add_at_least_one_photo,
        Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);
    print('Loading started');

    try {
      final user = FirebaseService.currentUser;
      if (user == null) {
        print('User is null');
        UiUtils.showToastMessage('Please login first', Colors.red);
        setState(() => _isLoading = false);
        return;
      }
      print('User ID: ${user.uid}');

      // Get owner name
      String ownerName = user.displayName ?? user.email?.split('@').first ?? 'User';
      print('Owner name: $ownerName');

      // Upload new images using ImgBB instead of Firebase Storage
      List<String> allImageUrls = List.from(_existingImageUrls);
      print('Existing images: ${_existingImageUrls.length}');
      print('New images to upload: ${_newImages.length}');

      if (_newImages.isNotEmpty) {
        print('Starting image upload to ImgBB...');
        try {
          final newUrls = await ImageUploadService.uploadMultipleImages(_newImages);
          allImageUrls.addAll(newUrls);
          print('Uploaded ${newUrls.length} images successfully');
        } catch (e) {
          print('Error uploading images: $e');
          UiUtils.showToastMessage('Failed to upload images', Colors.red);
          setState(() => _isLoading = false);
          return;
        }
      }

      print('Total images after upload: ${allImageUrls.length}');

      // If no images were uploaded successfully, show error
      if (allImageUrls.isEmpty) {
        UiUtils.showToastMessage('Failed to upload images', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // Create item data as Map (simpler approach)
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
        'location': _locationController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'isAvailable': true,
      };

      print('Item data created: $itemData');

      // Save to Firestore
      if (_isEditing) {
        print('Updating existing item: ${widget.itemToEdit!.id}');
        await FirebaseService.updateItemDirect(widget.itemToEdit!.id, itemData);
        print('Item updated successfully');
        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.item_updated,
          Colors.green,
        );
      } else {
        print('Adding new item...');
        final docId = await FirebaseService.addItemDirect(itemData);
        print('Item added with ID: $docId');
        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.item_published,
          Colors.green,
        );
      }

      // Go back
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      print('=== ERROR in submitItem ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      UiUtils.showToastMessage(
        _isEditing
            ? AppLocalizations.of(context)!.failed_to_update
            : AppLocalizations.of(context)!.failed_to_publish,
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Loading finished');
      }
    }
  }
}