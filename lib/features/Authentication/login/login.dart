// ============================================
// FILE: lib/features/Authentication/login/login.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/resources/images_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/core/widgets/custom_text_button.dart';
import 'package:barter/features/Authentication/validation.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/login_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isSecurePassword = true;
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool _isLoading = false;

  void togglePasswordVisibility() {
    setState(() {
      isSecurePassword = !isSecurePassword;
    });
  }

  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        padding: REdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 47.h,
        ),
        child: Form(
          key: loginFormKey,
          child: Column(
            children: [
              Image.asset(ImagesManager.bartrix, height: 180.h),
              Text(
                AppLocalizations.of(context)!.exchange_and_discover_easily,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 20.sp,
                  color: ColorsManager.grey,
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => login(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomTextButton(
                    text: AppLocalizations.of(context)!.forget_password,
                    onTap: () => _showForgotPasswordDialog(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  child: Text(AppLocalizations.of(context)!.login),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      endIndent: 16.w,
                      indent: 26.w,
                      thickness: 1.h,
                      color: ColorsManager.grey,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.or,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 20.sp,
                      color: ColorsManager.grey,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      endIndent: 26.w,
                      indent: 16.w,
                      thickness: 1.h,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: _isLoading ? null : _loginWithGoogle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(ImagesManager.google, width: 20.h),
                    SizedBox(width: 8.w),
                    Text(
                      AppLocalizations.of(context)!.login_with_google,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                        color: ColorsManager.purple,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              OutlinedButton(
                onPressed: _continueAsGuest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, color: ColorsManager.purple),
                    SizedBox(width: 8.w),
                    Text(
                      AppLocalizations.of(context)!.continue_as_guest,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                        color: ColorsManager.purple,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dont_have_account,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  CustomTextButton(
                    text: AppLocalizations.of(context)!.create_account,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, Routes.register);
                    },
                  ),
                ],
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

// Update your Login screen's login method:

  Future<void> login() async {
    if (loginFormKey.currentState?.validate() == false) {
      return;
    }

    UiUtils.showLoading(context, false);

    try {
      // Attempt login
      await FirebaseService.signIn(
        emailController.text.trim(),
        passwordController.text,
      );

      if (mounted) UiUtils.hideDialog(context);

      // Check if email is verified
      final user = FirebaseService.currentUser;

      if (user != null && !user.emailVerified) {
        // Email not verified - show warning
        await _showEmailNotVerifiedDialog();
        return;
      }

      // NEW: Check for MFA
      if (user != null) {
        final userModel = await FirebaseService.getUserById(user.uid);
        if (userModel != null && userModel.mfaEnabled) {
          // Trigger OTP
          await FirebaseService.generateAndSendOtp(user.uid);
          
          if (mounted) {
            Navigator.pushReplacementNamed(
              context, 
              Routes.otpVerification,
              arguments: {
                'uid': user.uid,
                'email': user.email ?? '',
              },
            );
          }
          return;
        }
      }

      // Email is verified or doesn't need verification
      UiUtils.showToastMessage(
        AppLocalizations.of(context)!.logged_in_successfully,
        Colors.green,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.mainLayout);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) UiUtils.hideDialog(context);

      String errorMessage = _getFirebaseErrorMessage(e.code);
      UiUtils.showToastMessage(errorMessage, Colors.red);
    } catch (e) {
      if (mounted) UiUtils.hideDialog(context);

      if (FirebaseService.currentUser != null) {
        // Check verification even in error case
        final user = FirebaseService.currentUser!;

        if (!user.emailVerified) {
          await _showEmailNotVerifiedDialog();
          return;
        }

        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.logged_in_successfully,
          Colors.green,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.mainLayout);
        }
      } else {
        print('Login error: $e');
        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.failed_to_login,
          Colors.red,
        );
      }
    }
  }

// Add this method to show email not verified dialog
  Future<void> _showEmailNotVerifiedDialog() async {
    final user = FirebaseService.currentUser;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              padding: REdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded, color: Colors.orange, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Email Not Verified',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please verify your email address before logging in.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: REdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorsManager.purpleSoft,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: ColorsManager.purple, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Haven\'t received the email?',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService.logout();
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // Resend verification email
                await user?.sendEmailVerification();

                if (mounted) {
                  Navigator.pop(ctx);
                  UiUtils.showToastMessage(
                    'Verification email sent! Please check your inbox.',
                    Colors.green,
                  );
                  await FirebaseService.logout();
                }
              } catch (e) {
                print('Error sending verification: $e');
                UiUtils.showToastMessage(
                  'Failed to send email. Please try again.',
                  Colors.red,
                );
              }
            },
            icon: Icon(Icons.send, size: 18.sp),
            label: const Text('Resend Email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    UiUtils.showLoading(context, false);
    try {
      final credential = await FirebaseService.signInWithGoogle();
      
      if (mounted) UiUtils.hideDialog(context);

      if (credential != null && credential.user != null) {
        final user = credential.user!;
        
        // NEW: Check for MFA
        final userModel = await FirebaseService.getUserById(user.uid);
        if (userModel != null && userModel.mfaEnabled) {
          // Trigger OTP
          await FirebaseService.generateAndSendOtp(user.uid);
          
          if (mounted) {
            Navigator.pushReplacementNamed(
              context, 
              Routes.otpVerification,
              arguments: {
                'uid': user.uid,
                'email': user.email ?? '',
              },
            );
          }
          return;
        }

        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.logged_in_successfully,
          Colors.green,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.mainLayout);
        }
      } else {
        // User cancelled or null credential
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) UiUtils.hideDialog(context);
      print('Google login error: $e');

      // Check if user is actually logged in despite the error
      if (FirebaseService.currentUser != null) {
        final user = FirebaseService.currentUser!;

        // NEW: Check for MFA in error case too
        final userModel = await FirebaseService.getUserById(user.uid);
        if (userModel != null && userModel.mfaEnabled) {
          await FirebaseService.generateAndSendOtp(user.uid);
          
          if (mounted) {
            Navigator.pushReplacementNamed(
              context, 
              Routes.otpVerification,
              arguments: {
                'uid': user.uid,
                'email': user.email ?? '',
              },
            );
          }
          return;
        }

        UiUtils.showToastMessage(
          AppLocalizations.of(context)!.logged_in_successfully,
          Colors.green,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.mainLayout);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        UiUtils.showToastMessage('Google Sign-In failed. Please try again.', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacementNamed(context, Routes.mainLayout);
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.forget_password),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: resetEmailController,
            validator: Validation.emailValidation,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.email,
              prefixIcon: const Icon(Icons.email),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx);
                await _sendPasswordResetEmail(resetEmailController.text.trim());
              }
            },
            child: Text(AppLocalizations.of(context)!.send),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    UiUtils.showLoading(context, false);

    try {
      await FirebaseService.resetPassword(email);
      if (mounted) UiUtils.hideDialog(context);
      UiUtils.showToastMessage(
        'Password reset email sent! Check your inbox.',
        Colors.green,
      );
    } catch (e) {
      if (mounted) UiUtils.hideDialog(context);
      UiUtils.showToastMessage(
        'Failed to send reset email. Please try again.',
        Colors.red,
      );
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}