// ============================================
// FILE: lib/model/chat_model.dart (UPDATE)
// Add unreadCount field
// ============================================

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String itemId;
  final String itemTitle;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastSenderId;
  final int unreadCount; // ADD THIS FIELD

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.itemId,
    required this.itemTitle,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastSenderId,
    this.unreadCount = 0, // ADD THIS
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chatId'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      itemId: json['itemId'] ?? '',
      itemTitle: json['itemTitle'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : DateTime.now(),
      lastSenderId: json['lastSenderId'] ?? '',
      unreadCount: json['unreadCount'] ?? 0, // ADD THIS
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'participants': participants,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount, // ADD THIS
    };
  }
}

enum MessageType {
  text,
  photo;

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.photo:
        return 'photo';
    }
  }

  static MessageType fromString(String value) {
    switch (value) {
      case 'photo':
        return MessageType.photo;
      default:
        return MessageType.text;
    }
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType messageType;
  final String? photoUrl;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.messageType = MessageType.text,
    this.photoUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      messageType: MessageType.fromString(json['messageType'] ?? 'text'),
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'messageType': messageType.value,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}