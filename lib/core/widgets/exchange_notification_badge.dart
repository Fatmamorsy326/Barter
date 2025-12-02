// ============================================
// FILE: lib/widgets/exchange_notification_badge.dart
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget to show a notification badge for pending exchanges
/// Use this in your app bar or navigation
class ExchangeNotificationBadge extends StatelessWidget {
  final VoidCallback onTap;

  const ExchangeNotificationBadge({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: FirebaseService.getPendingExchangesStream(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: onTap,
              tooltip: 'Exchanges',
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: REdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.h,
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ============================================
// USAGE EXAMPLE: Add to your main app bar
// ============================================

/*
AppBar(
  title: const Text('Barter App'),
  actions: [
    ExchangeNotificationBadge(
      onTap: () {
        Navigator.pushNamed(context, Routes.exchangesList);
      },
    ),
    // ... other actions
  ],
)
*/