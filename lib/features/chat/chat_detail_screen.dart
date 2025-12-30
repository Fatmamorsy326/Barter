import 'dart:io';
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/chat_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _markChatAsRead();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendButtonAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOut),
    );
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  Future<void> _markChatAsRead() async {
    try {
      final currentUserId = FirebaseService.currentUser?.uid;
      if (currentUserId == null) return;
      await FirebaseService.markChatAsRead(widget.chatId, currentUserId);
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
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
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<List<ChatModel>>(
          stream: FirebaseService.getUserChatsStream(),
          builder: (context, snapshot) {
            final chats = snapshot.data ?? [];
            final chat = chats.where((c) => c.chatId == widget.chatId).firstOrNull;

            String userName = AppLocalizations.of(context)!.chat;
            String itemTitle = '';
            String? photoUrl;

            if (chat != null) {
              final otherUserId = chat.participants
                  .firstWhere((id) => id != FirebaseService.currentUser!.uid);
              itemTitle = chat.itemTitle;

              return FutureBuilder<UserModel?>(
                future: FirebaseService.getUserById(otherUserId),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  userName = user?.name ?? AppLocalizations.of(context)!.loading;
                  photoUrl = user?.photoUrl;

                  return _buildAppBarContent(userName, itemTitle, photoUrl);
                },
              );
            }

            return _buildAppBarContent(userName, itemTitle, photoUrl);
          },
        ),
      ),
    );
  }

  Widget _buildAppBarContent(String userName, String itemTitle, String? photoUrl) {
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: photoUrl != null && photoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(userName),
                    ),
                  )
                : _buildAvatarPlaceholder(userName),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (itemTitle.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white70,
                        size: 12.sp,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          itemTitle,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<MessageModel>>(
      stream: FirebaseService.getMessagesStream(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.purple),
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: REdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == FirebaseService.currentUser!.uid;
            final showDate = index == 0 ||
                !_isSameDay(messages[index - 1].timestamp, message.timestamp);

            return Column(
              children: [
                if (showDate) _buildDateDivider(message.timestamp),
                MessageBubble(message: message, isMe: isMe),
              ],
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    String text;

    if (_isSameDay(date, now)) {
      text = 'Today';
    } else if (diff.inDays == 1) {
      text = 'Yesterday';
    } else if (diff.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      text = days[date.weekday - 1];
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: REdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: ColorsManager.grey.withOpacity(0.3))),
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              style: TextStyle(
                color: ColorsManager.grey,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: ColorsManager.grey.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorsManager.purpleSoft,
                  ColorsManager.purpleSoft.withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48.sp,
              color: ColorsManager.purple,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            AppLocalizations.of(context)!.start_the_conversation,
            style: TextStyle(
              color: ColorsManager.grey,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Say hello! 👋',
            style: TextStyle(
              color: ColorsManager.grey.withOpacity(0.7),
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: REdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: ColorsManager.white,
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadow,
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                width: 44.w,
                height: 44.h,
                margin: REdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: ColorsManager.purpleSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.attach_file_rounded,
                  color: ColorsManager.purple,
                  size: 20.sp,
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ColorsManager.greyUltraLight,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.type_message,
                    hintStyle: TextStyle(
                      color: ColorsManager.grey,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: REdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            AnimatedBuilder(
              animation: _sendButtonAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _hasText ? _sendButtonAnimation.value : 0.8,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _hasText ? _sendMessage : null,
                child: Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    gradient: _hasText
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ColorsManager.gradientStart,
                              ColorsManager.gradientEnd,
                            ],
                          )
                        : null,
                    color: _hasText ? null : ColorsManager.greyLight,
                    shape: BoxShape.circle,
                    boxShadow: _hasText
                        ? [
                            BoxShadow(
                              color: ColorsManager.purple.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _hasText ? Colors.white : ColorsManager.grey,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
                  'Send Photo',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPhotoOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickPhoto(ImageSource.camera);
                      },
                    ),
                    _buildPhotoOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickPhoto(ImageSource.gallery);
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: REdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ColorsManager.purpleSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ColorsManager.purple, size: 28.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        print('Photo picked: ${image.path}');
        UiUtils.showLoading(context, false);
        
        try {
          final photoFile = File(image.path);
          print('File exists: ${await photoFile.exists()}');
          print('File size: ${await photoFile.length()} bytes');
          
          await FirebaseService.sendPhotoMessage(widget.chatId, photoFile);
          if (mounted) {
            UiUtils.hideDialog(context);
            UiUtils.showToastMessage('Photo sent!', Colors.green);
          }
        } catch (uploadError) {
          print('Upload error details: $uploadError');
          if (mounted) {
            UiUtils.hideDialog(context);
            UiUtils.showToastMessage('Upload failed: ${uploadError.toString()}', Colors.red);
          }
        }
      }
    } catch (e) {
      print('Error picking photo: $e');
      if (mounted) {
        UiUtils.showToastMessage('Failed to pick photo', Colors.red);
      }
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    FirebaseService.sendMessage(widget.chatId, text);
    _messageController.clear();
  }
}

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isPhoto = message.messageType == MessageType.photo;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: REdgeInsets.only(
          bottom: 8,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: isPhoto ? REdgeInsets.all(4) : REdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorsManager.gradientStart,
                    ColorsManager.gradientEnd,
                  ],
                )
              : null,
          color: isMe ? null : ColorsManager.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: isMe ? Radius.circular(20.r) : Radius.circular(4.r),
            bottomRight: isMe ? Radius.circular(4.r) : Radius.circular(20.r),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? ColorsManager.purple.withOpacity(0.2)
                  : ColorsManager.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isPhoto && message.photoUrl != null)
              GestureDetector(
                onTap: () => _showPhotoViewer(context, message.photoUrl!),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 200.w,
                    maxHeight: 250.h,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.network(
                      message.photoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 200.w,
                          height: 200.h,
                          color: isMe ? Colors.white.withOpacity(0.1) : ColorsManager.greyUltraLight,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                              color: isMe ? Colors.white : ColorsManager.purple,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: 200.w,
                        height: 200.h,
                        color: isMe ? Colors.white.withOpacity(0.1) : ColorsManager.greyUltraLight,
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: isMe ? Colors.white60 : ColorsManager.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : ColorsManager.black,
                  fontSize: 14.sp,
                  height: 1.4,
                ),
              ),
            SizedBox(height: 4.h),
            Padding(
              padding: isPhoto ? REdgeInsets.symmetric(horizontal: 8) : EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isMe ? Colors.white60 : ColorsManager.grey,
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 4.w),
                    Icon(
                      message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14.sp,
                      color: message.isRead ? Colors.white : Colors.white60,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoViewer(BuildContext context, String photoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(photoUrl),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}