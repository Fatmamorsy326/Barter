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

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context),
        ],
        body: StreamBuilder<List<ChatModel>>(
          stream: FirebaseService.getUserChatsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerList();
            }

            final chats = snapshot.data ?? [];

            if (chats.isEmpty) {
              return _buildEmptyState(context);
            }

            // Remove duplicate chats (same participants)
            final uniqueChats = _removeDuplicateChats(chats);

            return ListView.builder(
              padding: REdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: uniqueChats.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: REdgeInsets.only(bottom: 12),
                  child: ChatListTile(
                    chat: uniqueChats[index],
                    onTap: () => Navigator.pushNamed(
                      context,
                      Routes.chatDetail,
                      arguments: uniqueChats[index].chatId,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      expandedHeight: 80.h,
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
          titlePadding: REdgeInsets.only(left: 20, bottom: 16),
          title: Row(
            children: [
              Container(
                padding: REdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                AppLocalizations.of(context)!.chat,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: REdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: REdgeInsets.only(bottom: 12),
        child: _ShimmerChatTile(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorsManager.purpleSoftFor(context),
                  ColorsManager.purpleSoftFor(context).withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56.sp,
              color: ColorsManager.purpleFor(context),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            AppLocalizations.of(context)!.no_chats_yet,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.textFor(context),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start a conversation about an item',
            style: TextStyle(
              fontSize: 14.sp,
              color: ColorsManager.textSecondaryFor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<ChatModel> _removeDuplicateChats(List<ChatModel> chats) {
    final Map<String, ChatModel> uniqueChatsMap = {};
    final currentUserId = FirebaseService.currentUser!.uid;

    for (var chat in chats) {
      final otherUserId = chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) continue;

      if (!uniqueChatsMap.containsKey(otherUserId) ||
          chat.lastMessageTime.isAfter(uniqueChatsMap[otherUserId]!.lastMessageTime)) {
        uniqueChatsMap[otherUserId] = chat;
      }
    }

    return uniqueChatsMap.values.toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }
}

class _ShimmerChatTile extends StatefulWidget {
  @override
  State<_ShimmerChatTile> createState() => _ShimmerChatTileState();
}

class _ShimmerChatTileState extends State<_ShimmerChatTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: REdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorsManager.cardFor(context),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: ColorsManager.shadowFor(context),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _shimmerBox(50.w, 50.h, 25.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(100.w, 14.h, 4.r),
                    SizedBox(height: 8.h),
                    _shimmerBox(150.w, 12.h, 4.r),
                    SizedBox(height: 4.h),
                    _shimmerBox(80.w, 10.h, 4.r),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _shimmerBox(40.w, 10.h, 4.r),
                  SizedBox(height: 8.h),
                  _shimmerBox(20.w, 20.h, 10.r),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: [
            ColorsManager.shimmerBaseFor(context),
            ColorsManager.shimmerHighlightFor(context),
            ColorsManager.shimmerBaseFor(context),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class ChatListTile extends StatefulWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatListTile({super.key, required this.chat, required this.onTap});

  @override
  State<ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<ChatListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseService.currentUser!.uid;
    final otherUserId = widget.chat.participants.firstWhere(
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
        final hasUnread = widget.chat.unreadCount > 0;

        return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _controller.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _controller.reverse();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _controller.reverse();
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: REdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasUnread 
                    ? ColorsManager.purpleSoftFor(context).withOpacity(0.5) 
                    : ColorsManager.cardFor(context),
                borderRadius: BorderRadius.circular(16.r),
                border: hasUnread
                    ? Border.all(
                        color: ColorsManager.purple.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: _isPressed 
                        ? ColorsManager.shadowFor(context) 
                        : ColorsManager.shadowFor(context),
                    blurRadius: _isPressed ? 15 : 10,
                    offset: Offset(0, _isPressed ? 6 : 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar with online indicator
                  Stack(
                    children: [
                      Container(
                        width: 54.w,
                        height: 54.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: otherUser?.photoUrl == null || otherUser!.photoUrl!.isEmpty
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ColorsManager.gradientStart,
                                    ColorsManager.gradientEnd,
                                  ],
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: ColorsManager.purple.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: otherUser?.photoUrl != null && otherUser!.photoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  otherUser.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(otherUser),
                                ),
                              )
                            : _buildAvatarPlaceholder(otherUser),
                      ),
                    ],
                  ),
                  SizedBox(width: 14.w),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                otherUser?.name ?? AppLocalizations.of(context)!.loading,
                                style: TextStyle(
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 15.sp,
                                  color: ColorsManager.textFor(context).withOpacity(widget.chat.blockedBy.isNotEmpty ? 0.6 : 1.0),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.chat.blockedBy.isNotEmpty)
                              Container(
                                margin: REdgeInsets.only(right: 8),
                                padding: REdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Blocked',
                                  style: TextStyle(color: Colors.red, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                ),
                              ),
                            Text(
                              _formatTime(widget.chat.lastMessageTime),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: hasUnread ? ColorsManager.purple : ColorsManager.textSecondaryFor(context),
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        if (widget.chat.itemTitle.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Container(
                            padding: REdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  ColorsManager.gradientStart,
                                  ColorsManager.gradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 10.sp,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    widget.chat.itemTitle,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.chat.lastMessage.isEmpty
                                    ? AppLocalizations.of(context)!.start_the_conversation
                                    : widget.chat.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasUnread 
                                      ? ColorsManager.textFor(context).withOpacity(0.8) 
                                      : ColorsManager.textSecondaryFor(context),
                                  fontSize: 13.sp,
                                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: REdgeInsets.only(left: 8),
                                padding: REdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      ColorsManager.gradientStart,
                                      ColorsManager.gradientEnd,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ColorsManager.purple.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  widget.chat.unreadCount > 99 
                                      ? '99+' 
                                      : widget.chat.unreadCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarPlaceholder(UserModel? user) {
    return Center(
      child: Text(
        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20.sp,
        ),
      ),
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