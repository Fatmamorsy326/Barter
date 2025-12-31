// ============================================
// FILE: lib/features/Authentication/register/register.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/resources/images_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/core/widgets/custom_text_button.dart';
import 'package:barter/features/Authentication/validation.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/register_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool isSecurePassword = true;
  bool isSecureRePassword = true;
  GlobalKey<FormState> regFormKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController rePasswordController;

  void togglePasswordVisibility() {
    setState(() {
      isSecurePassword = !isSecurePassword;
    });
  }

  void toggleRePasswordVisibility() {
    setState(() {
      isSecureRePassword = !isSecureRePassword;
    });
  }

  @override
  void initState() {
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    rePasswordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    rePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        padding: REdgeInsets.only(
          top: 47.h,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: regFormKey,
          child: Column(
            children: [
              Image.asset(ImagesManager.barter, height: 180),
              Text(
                AppLocalizations.of(context)!.exchange_and_discover_easily,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 20.sp,
                  color: ColorsManager.grey,
                ),
              ),
              SizedBox(height: 24.h),
              TextFormField(
                controller: nameController,
                validator: Validation.nameValidation,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  labelText: AppLocalizations.of(context)!.name,
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: emailController,
                validator: Validation.emailValidation,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: AppLocalizations.of(context)!.email,
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: passwordController,
                validator: Validation.passwordValidation,
                obscureText: isSecurePassword,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: AppLocalizations.of(context)!.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isSecurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: togglePasswordVisibility,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                validator: (value) {
                  return Validation.rePasswordValidation(
                    rePasswordController.text,
                    passwordController.text,
                  );
                },
                controller: rePasswordController,
                keyboardType: TextInputType.visiblePassword,
                obscureText: isSecureRePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => createAccount(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: AppLocalizations.of(context)!.re_password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isSecureRePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: toggleRePasswordVisibility,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: createAccount,
                  child: Text(AppLocalizations.of(context)!.create_account),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.already_have_account,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  CustomTextButton(
                    text: AppLocalizations.of(context)!.login,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, Routes.login);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// In your register.dart, verify the createAccount method looks like this:

  // Update your createAccount method in register.dart:

  Future<void> createAccount() async {
    // Validate form first
    if (regFormKey.currentState?.validate() == false) {
      return;
    }

    // Get values BEFORE any async operations
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    print('🔵 REGISTER: Attempting to register');
    print('🔵 REGISTER: Name = $name');
    print('🔵 REGISTER: Email = $email');

    // Show loading
    UiUtils.showLoading(context, false);

    try {
      // Call signUp
      await FirebaseService.signUp(email, password, name);

      print('✅ REGISTER: SignUp successful');

      // Hide loading
      if (mounted) UiUtils.hideDialog(context);

      // Show success message
      UiUtils.showToastMessage(
        AppLocalizations.of(context)!.registered_successfully,
        Colors.green,
      );

      // Sign out and navigate to login
      await FirebaseService.logout();

      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    } on FirebaseAuthException catch (e) {
      print('❌ REGISTER: Firebase Auth Error: ${e.code}');

      // Hide loading
      if (mounted) UiUtils.hideDialog(context);

      // Show specific Firebase error
      String errorMessage = _getFirebaseErrorMessage(e.code);
      UiUtils.showToastMessage(errorMessage, Colors.red);

    } catch (e) {
      print('❌ REGISTER: General Error: $e');

      // Hide loading
      if (mounted) UiUtils.hideDialog(context);

      // Check if user was actually created
      final currentUser = FirebaseService.currentUser;

      if (currentUser != null) {
        print('✅ REGISTER: User account created despite error');

        // The account was created, so let's ensure the document exists
        try {
          // Force create the document with correct name
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'uid': currentUser.uid,
            'email': email,
            'name': name, // Use the original name variable
            'createdAt': DateTime.now().toIso8601String(),
          });

          print('✅ REGISTER: User document created with correct name');

          // Also update displayName
          await currentUser.updateDisplayName(name);
          print('✅ REGISTER: DisplayName updated');

        } catch (docError) {
          print('❌ REGISTER: Error creating document: $docError');
        }

        // Show success
        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.registered_successfully,
          Colors.green,
        );

        // Sign out and go to login
        await FirebaseService.logout();

        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.login);
        }
      } else {
        // Actual failure - no account created
        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.failed_to_register,
          Colors.red,
        );
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Registration failed. Please try again.';
    }
  }
}