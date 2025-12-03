// ============================================
// FILE: lib/widgets/unread_messages_badge.dart
// CREATE THIS NEW FILE
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/model/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UnreadMessagesBadge extends StatelessWidget {
  final Widget child;

  const UnreadMessagesBadge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseService.currentUser?.uid;

    if (currentUserId == null) {
      return child;
    }

    return StreamBuilder<int>(
      stream: FirebaseService.getTotalUnreadCountStream(currentUserId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        if (unreadCount == 0) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: EdgeInsets.all(unreadCount > 9 ? 4.w : 6.w),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                constraints: BoxConstraints(
                  minWidth: 18.w,
                  minHeight: 18.h,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
// USAGE IN YOUR BOTTOM NAVIGATION BAR
// ============================================

/*
// In your main navigation screen (e.g., main_screen.dart or home_wrapper.dart):

BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: (index) => setState(() => _currentIndex = index),
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      // Wrap the chat icon with UnreadMessagesBadge
      icon: UnreadMessagesBadge(
        child: Icon(Icons.chat_bubble_outline),
      ),
      label: 'Chat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline),
      label: 'Add',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.list_alt),
      label: 'My Items',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Account',
    ),
  ],
)
*/