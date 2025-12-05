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
      backgroundColor: ColorsManager.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.purple),
              ),
            )
          : _user == null
              ? _buildErrorState()
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Form(
                        key: _formKey,
                        child: Padding(
                          padding: REdgeInsets.fromLTRB(16, 16, 16, 100),
                          child: Column(
                            children: [
                              _buildSectionTitle('Personal Information', Icons.person_rounded),
                              SizedBox(height: 12.h),
                              _buildFormCard([
                                _buildNameField(),
                                _buildDivider(),
                                _buildEmailField(),
                              ]),
                              SizedBox(height: 24.h),
                              _buildSectionTitle('Contact Details', Icons.contact_phone_rounded),
                              SizedBox(height: 12.h),
                              _buildFormCard([
                                _buildPhoneField(),
                                _buildDivider(),
                                _buildLocationField(),
                              ]),
                              SizedBox(height: 32.h),
                              _buildSaveButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 220.h,
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
          background: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40.h),
                _buildPhotoSection(),
                SizedBox(height: 12.h),
                Text(
                  'Tap photo to change',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Stack(
        children: [
          Container(
            width: 110.w,
            height: 110.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: _getProfileWidget(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF0F0F0)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 20.sp,
                color: ColorsManager.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getProfileWidget() {
    if (_newPhoto != null) {
      return Image.file(_newPhoto!, fit: BoxFit.cover);
    }
    if (_user?.photoUrl != null && _user!.photoUrl!.isNotEmpty) {
      return Image.network(
        _user!.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
      );
    }
    return _buildAvatarPlaceholder();
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 44.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
            color: ColorsManager.black,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.white,
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
      child: Divider(height: 1, color: ColorsManager.greyUltraLight),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ColorsManager.white,
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
                  'Update Profile Photo',
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
                        _pickPhoto(ImageSource.camera);
                      },
                    ),
                    _buildPhotoOption(
                      icon: Icons.photo_library_rounded,
                      label: AppLocalizations.of(context)!.gallery,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickPhoto(ImageSource.gallery);
                      },
                    ),
                    if (_newPhoto != null ||
                        (_user?.photoUrl != null && _user!.photoUrl!.isNotEmpty))
                      _buildPhotoOption(
                        icon: Icons.delete_rounded,
                        label: AppLocalizations.of(context)!.remove_photo,
                        color: Colors.red,
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
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: REdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? ColorsManager.purple).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? ColorsManager.purple, size: 28.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color ?? ColorsManager.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    return Padding(
      padding: REdgeInsets.all(16),
      child: TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        style: TextStyle(fontSize: 15.sp),
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
          prefixIcon: Icon(Icons.person_rounded, color: ColorsManager.purple),
          border: InputBorder.none,
          contentPadding: REdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: TextFormField(
        initialValue: _user?.email ?? '',
        enabled: false,
        style: TextStyle(fontSize: 15.sp, color: ColorsManager.grey),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.email,
          labelStyle: TextStyle(color: ColorsManager.grey),
          prefixIcon: Icon(Icons.email_rounded, color: ColorsManager.grey),
          border: InputBorder.none,
          contentPadding: REdgeInsets.symmetric(vertical: 8),
          suffixIcon: Container(
            margin: REdgeInsets.only(right: 8),
            padding: REdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ColorsManager.greyUltraLight,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 12.sp, color: ColorsManager.grey),
                SizedBox(width: 4.w),
                Text(
                  'Verified',
                  style: TextStyle(fontSize: 11.sp, color: ColorsManager.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        style: TextStyle(fontSize: 15.sp),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.phone,
          hintText: '+20 123 456 7890',
          hintStyle: TextStyle(color: ColorsManager.grey.withOpacity(0.5)),
          prefixIcon: Icon(Icons.phone_rounded, color: ColorsManager.purple),
          border: InputBorder.none,
          contentPadding: REdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Padding(
      padding: REdgeInsets.all(16),
      child: TextFormField(
        controller: _locationController,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        style: TextStyle(fontSize: 15.sp),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.location,
          hintText: 'Alexandria, Egypt',
          hintStyle: TextStyle(color: ColorsManager.grey.withOpacity(0.5)),
          prefixIcon: Icon(Icons.location_on_rounded, color: ColorsManager.purple),
          border: InputBorder.none,
          contentPadding: REdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _saveProfile,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: _isSaving
              ? null
              : const LinearGradient(
                  colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                ),
          color: _isSaving ? ColorsManager.greyLight : null,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: _isSaving
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
          child: _isSaving
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
                    Icon(Icons.save_rounded, color: Colors.white, size: 22.sp),
                    SizedBox(width: 10.w),
                    Text(
                      AppLocalizations.of(context)!.save_changes,
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, size: 56.sp, color: Colors.red),
          ),
          SizedBox(height: 24.h),
          Text(
            'Failed to load profile',
            style: TextStyle(fontSize: 16.sp, color: ColorsManager.grey),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _loadUserData,
            child: Container(
              padding: REdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorsManager.gradientStart, ColorsManager.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                AppLocalizations.of(context)!.try_again,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? photoUrl = _user!.photoUrl;

      if (_newPhoto != null) {
        try {
          photoUrl = await ImageUploadService.uploadImage(_newPhoto!);
        } catch (e) {
          print('Failed to upload photo: $e');
          UiUtils.showToastMessage('Failed to upload photo', Colors.orange);
        }
      }

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

      try {
        await FirebaseService.updateUser(updatedUser);
      } catch (e) {
        print('Firestore update failed, trying to create document: $e');
        await FirebaseService.ensureUserDocument();
        await FirebaseService.updateUser(updatedUser);
      }

      try {
        await FirebaseService.currentUser?.updateDisplayName(
          _nameController.text.trim(),
        );
      } catch (e) {
        print('Failed to update display name: $e');
      }

      UiUtils.showToastMessage('Profile updated successfully', Colors.green);

      if (mounted) {
        Navigator.pop(context, true);
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