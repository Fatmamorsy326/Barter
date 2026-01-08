
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:barter/model/notification_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: FirebaseService.getUserNotificationsStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.bell_fill,
                    size: 64.sp,
                    color: ColorsManager.textSecondaryFor(context),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: ColorsManager.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: REdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationItem(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await FirebaseService.markNotificationAsRead(notification.id);
        }
        
        if (notification.relatedId != null && 
            (notification.type == NotificationType.exchangeRequest || 
             notification.type == NotificationType.exchangeAccepted ||
             notification.type == NotificationType.exchangeCancelled ||
             notification.type == NotificationType.exchangeCompleted)) {
             
             // Navigate to exchange detail with ID
             if (context.mounted) {
               Navigator.pushNamed(
                 context, 
                 Routes.exchangeDetail, 
                 arguments: notification.relatedId
               );
             }
        }
      },
      child: Container(
        padding: REdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? ColorsManager.cardFor(context) 
              : ColorsManager.purpleSoftFor(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: notification.isRead 
                ? Colors.transparent 
                : ColorsManager.purpleFor(context).withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: REdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(notification.type),
                color: _getIconColor(notification.type),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: ColorsManager.textFor(context),
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: ColorsManager.textSecondaryFor(context),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: ColorsManager.textFor(context).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: REdgeInsets.only(left: 8),
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: ColorsManager.purpleFor(context),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.exchangeRequest:
        return Icons.swap_horiz_rounded;
      case NotificationType.exchangeAccepted:
        return Icons.check_circle_outline_rounded;
      case NotificationType.exchangeCancelled:
        return Icons.cancel_outlined;
      case NotificationType.exchangeCompleted:
        return Icons.task_alt_rounded;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.exchangeRequest:
        return Colors.blue;
      case NotificationType.exchangeAccepted:
        return Colors.green;
      case NotificationType.exchangeCancelled:
        return Colors.red;
      case NotificationType.exchangeCompleted:
        return Colors.purple;
      case NotificationType.newMessage:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(date);
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.Md().format(date);
    }
  }
}
