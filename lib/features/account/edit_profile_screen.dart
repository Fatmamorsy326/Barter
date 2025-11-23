// ============================================
// FILE: lib/features/account/edit_profile_screen.dart
// ============================================

import 'dart:io';
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/services/image_upload_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  UserModel? _user;
  File? _newPhoto;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      UserModel? user = await FirebaseService.getUserById(currentUser.uid);

      // If no Firestore document, create from Auth data
      if (user == null) {
        user = UserModel(
          uid: currentUser.uid,
          name: currentUser.displayName ??
              currentUser.email?.split('@').first ??
              'User',
          email: currentUser.email ?? '',
          photoUrl: currentUser.photoURL,
          createdAt: currentUser.metadata.creationTime ?? DateTime.now(),
        );
      }

      setState(() {
        _user = user;
        _nameController.text = user!.name;
        _phoneController.text = user.phone ?? '';
        _locationController.text = user.location ?? '';
      });
    } catch (e) {
      print('Error loading user: $e');

      // Fallback to Auth data
      final currentUser = FirebaseService.currentUser;
      if (currentUser != null) {
        setState(() {
          _user = UserModel(
            uid: currentUser.uid,
            name: currentUser.displayName ??
                currentUser.email?.split('@').first ??
                'User',
            email: currentUser.email ?? '',
            photoUrl: currentUser.photoURL,
            createdAt: currentUser.metadata.creationTime ?? DateTime.now(),
          );
          _nameController.text = _user!.name;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.edit_profile),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text('Failed to load profile'),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadUserData,
              child: Text(AppLocalizations.of(context)!.try_again),
            ),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: REdgeInsets.all(16),
          child: Column(
            children: [
              _buildPhotoSection(),
              SizedBox(height: 32.h),
              _buildNameField(),
              SizedBox(height: 16.h),
              _buildEmailField(),
              SizedBox(height: 16.h),
              _buildPhoneField(),
              SizedBox(height: 16.h),
              _buildLocationField(),
              SizedBox(height: 32.h),
              _buildSaveButton(),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60.r,
            backgroundColor: ColorsManager.purple.withOpacity(0.1),
            backgroundImage: _getProfileImage(),
            child: _getProfileImage() == null
                ? Text(
              _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 48.sp,
                color: ColorsManager.purple,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: ColorsManager.purple,
              child: IconButton(
                icon: Icon(Icons.camera_alt, size: 20.sp, color: Colors.white),
                onPressed: _showPhotoOptions,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_newPhoto != null) {
      return FileImage(_newPhoto!);
    }
    if (_user?.photoUrl != null && _user!.photoUrl!.isNotEmpty) {
      return NetworkImage(_user!.photoUrl!);
    }
    return null;
  }

  void _showPhotoOptions() {
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
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: ColorsManager.purple),
                title: Text(AppLocalizations.of(context)!.gallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_newPhoto != null ||
                  (_user?.photoUrl != null && _user!.photoUrl!.isNotEmpty))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(context)!.remove_photo,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _newPhoto = null;
                      if (_user != null) {
                        _user = _user!.copyWith(photoUrl: '');
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _newPhoto = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      UiUtils.showToastMessage('Failed to pick image', Colors.red);
    }
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Name is required';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.name,
        prefixIcon: const Icon(Icons.person_outline),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      initialValue: _user?.email ?? '',
      enabled: false,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.email,
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      style: TextStyle(color: Colors.grey[600]),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.phone,
        prefixIcon: const Icon(Icons.phone_outlined),
        hintText: '+20 123 456 7890',
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.location,
        prefixIcon: const Icon(Icons.location_on_outlined),
        hintText: 'Alexandria, Egypt',
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        child: _isSaving
            ? SizedBox(
          height: 20.h,
          width: 20.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(AppLocalizations.of(context)!.save_changes),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      print('Saving profile...');
      String? photoUrl = _user!.photoUrl;

      // Upload new photo if selected
      if (_newPhoto != null) {
        print('Uploading new profile photo...');
        try {
          photoUrl = await ImageUploadService.uploadImage(_newPhoto!);
          print('Photo uploaded: $photoUrl');
        } catch (e) {
          print('Failed to upload photo: $e');
          UiUtils.showToastMessage('Failed to upload photo', Colors.orange);
          // Continue saving other data
        }
      }

      // Create updated user model
      final updatedUser = UserModel(
        uid: _user!.uid,
        name: _nameController.text.trim(),
        email: _user!.email,
        photoUrl: photoUrl,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        createdAt: _user!.createdAt,
      );

      print('Saving to Firestore...');

      // Try to update Firestore
      try {
        await FirebaseService.updateUser(updatedUser);
        print('Firestore updated');
      } catch (e) {
        print('Firestore update failed, trying to create document: $e');
        // If update fails, try to create the document
        await FirebaseService.ensureUserDocument();
        await FirebaseService.updateUser(updatedUser);
      }

      // Update Firebase Auth display name
      try {
        await FirebaseService.currentUser?.updateDisplayName(
          _nameController.text.trim(),
        );
        print('Auth display name updated');
      } catch (e) {
        print('Failed to update display name: $e');
      }

      UiUtils.showToastMessage('Profile updated successfully', Colors.green);

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh account screen
      }
    } catch (e) {
      print('Error saving profile: $e');
      UiUtils.showToastMessage('Failed to update profile', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}