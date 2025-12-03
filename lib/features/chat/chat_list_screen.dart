// ============================================
// FILE: lib/features/chat/chat_list_screen.dart (UPDATED)
// ============================================

import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/chat_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppLocalizations.of(context)!.chat),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: FirebaseService.getUserChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    AppLocalizations.of(context)!.no_chats_yet,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Start a conversation about an item',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Remove duplicate chats (same participants)
          final uniqueChats = _removeDuplicateChats(chats);

          print('Total chats: ${chats.length}');
          print('Unique chats: ${uniqueChats.length}');

          return ListView.separated(
            itemCount: uniqueChats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ChatListTile(
                chat: uniqueChats[index],
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.chatDetail,
                  arguments: uniqueChats[index].chatId,
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<ChatModel> _removeDuplicateChats(List<ChatModel> chats) {
    final Map<String, ChatModel> uniqueChatsMap = {};
    final currentUserId = FirebaseService.currentUser!.uid;

    for (var chat in chats) {
      // Get the other user's ID
      final otherUserId = chat.participants.firstWhere(
            (id) => id != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) continue;

      // Use other user ID as key to group chats
      // Keep only the most recent chat
      if (!uniqueChatsMap.containsKey(otherUserId) ||
          chat.lastMessageTime.isAfter(uniqueChatsMap[otherUserId]!.lastMessageTime)) {
        uniqueChatsMap[otherUserId] = chat;
      }
    }

    return uniqueChatsMap.values.toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }
}

class ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatListTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseService.currentUser!.uid;
    final otherUserId = chat.participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<UserModel?>(
      future: FirebaseService.getUserById(otherUserId),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;

        return ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: ColorsManager.purple.withOpacity(0.1),
            backgroundImage: otherUser?.photoUrl != null && otherUser!.photoUrl!.isNotEmpty
                ? NetworkImage(otherUser.photoUrl!)
                : null,
            child: otherUser?.photoUrl == null || otherUser!.photoUrl!.isEmpty
                ? Text(
              otherUser?.name.isNotEmpty == true
                  ? otherUser!.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: ColorsManager.purple,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          title: Text(
            otherUser?.name ?? AppLocalizations.of(context)!.loading,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chat.itemTitle.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 12.sp,
                      color: ColorsManager.purple,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        chat.itemTitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: ColorsManager.purple,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 2.h),
              Text(
                chat.lastMessage.isEmpty
                    ? AppLocalizations.of(context)!.start_the_conversation
                    : chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(chat.lastMessageTime),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
              if (chat.lastSenderId.isNotEmpty &&
                  chat.lastSenderId != currentUserId)
                Container(
                  margin: REdgeInsets.only(top: 4),
                  padding: REdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorsManager.purple,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          isThreeLine: true,
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${time.day}/${time.month}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return 'Now';
  }
}