// Create this new screen: lib/features/auth/email_verification_screen.dart

import 'dart:async';
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isResending = false;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPeriodicCheck() {
    // Check verification status every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await FirebaseService.reloadUser();

      if (FirebaseService.isEmailVerified) {
        _timer?.cancel();

        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.mainLayout);
        }
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_countdown > 0) return;

    setState(() => _isResending = true);

    try {
      await FirebaseService.sendEmailVerification();

      setState(() {
        _countdown = 60; // 60 second cooldown
        _isResending = false;
      });

      // Start countdown timer
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown > 0) {
          setState(() => _countdown--);
        } else {
          timer.cancel();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isResending = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkManually() async {
    await FirebaseService.reloadUser();

    if (FirebaseService.isEmailVerified) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.mainLayout);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: ColorsManager.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, Routes.login);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: REdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 40.h),

            // Email icon animation
            Container(
              padding: REdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorsManager.gradientStart.withOpacity(0.2),
                    ColorsManager.gradientEnd.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_rounded,
                size: 80.sp,
                color: ColorsManager.purple,
              ),
            ),

            SizedBox(height: 32.h),

            Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              'We sent a verification link to:',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 12.h),

            Container(
              padding: REdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorsManager.purpleSoft,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: ColorsManager.purple),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            Container(
              padding: REdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 24.sp),
                  SizedBox(height: 12.h),
                  Text(
                    'Click the link in your email to verify your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This page will automatically redirect once verified',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkManually,
                icon: Icon(Icons.refresh, size: 20.sp),
                label: const Text('I\'ve Verified - Check Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.purple,
                  padding: REdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _countdown > 0 || _isResending ? null : _resendEmail,
                icon: _isResending
                    ? SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(Icons.send, size: 20.sp),
                label: Text(
                  _countdown > 0
                      ? 'Resend in $_countdown s'
                      : 'Resend Verification Email',
                ),
                style: OutlinedButton.styleFrom(
                  padding: REdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: ColorsManager.purple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 32.h),

            Container(
              padding: REdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Icon(Icons.email_outlined, color: Colors.orange, size: 24.sp),
                  SizedBox(height: 8.h),
                  Text(
                    'Didn\'t receive the email?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '• Check your spam/junk folder\n• Make sure the email is correct\n• Wait a few minutes and try again',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}