
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
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ChatListTile(
                chat: chats[index],
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.chatDetail,
                  arguments: chats[index].chatId,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatListTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseService.currentUser!.uid;
    final otherUserId = chat.participants.firstWhere((id) => id != currentUserId);

    return FutureBuilder<UserModel?>(
      future: FirebaseService.getUserById(otherUserId),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;

        return ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: ColorsManager.purple.withOpacity(0.1),
            backgroundImage: otherUser?.photoUrl != null
                ? NetworkImage(otherUser!.photoUrl!)
                : null,
            child: otherUser?.photoUrl == null
                ? Text(
              otherUser?.name.isNotEmpty == true
                  ? otherUser!.name[0].toUpperCase()
                  : '?',
              style: TextStyle(color: ColorsManager.purple),
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
              Text(
                chat.itemTitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: ColorsManager.purple,
                ),
              ),
              Text(
                chat.lastMessage.isEmpty
                    ? AppLocalizations.of(context)!.start_the_conversation
                    : chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Text(
            _formatTime(chat.lastMessageTime),
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
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
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return 'Now';
  }
}