import 'dart:io';

import 'package:barter/model/chat_model.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:barter/model/notification_model.dart';
import 'package:barter/services/image_upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static User? get currentUser => _auth.currentUser;

  // ==================== AUTH ====================

  static Future<UserCredential> signUp(String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _createUserDocument(credential.user!, name);
    return credential;
  }

  static Future<void> _createUserDocument(User user, String name) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: name,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toJson());
  }

  static Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Ensure user document exists
    await ensureUserDocument();

    return credential;
  }

  // Ensure user document exists
  static Future<void> ensureUserDocument() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _createUserDocument(
          user,
          user.displayName ?? user.email
              ?.split('@')
              .first ?? 'User',
        );
      }
    } catch (e) {
      print('Warning: ensureUserDocument failed: $e');
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ==================== USER ====================

  static Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  static Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toJson());
  }

  // ==================== ITEMS ====================

  static Future<String> addItem(ItemModel item) async {
    final docRef = await _firestore.collection('items').add(item.toJson());
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  // Add item using direct Map - simpler and more reliable
  static Future<String> addItemDirect(Map<String, dynamic> itemData) async {
    final docRef = await _firestore.collection('items').add(itemData);
    // Update with document ID
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  static Future<void> updateItem(ItemModel item) async {
    await _firestore.collection('items').doc(item.id).update(item.toJson());
  }

  // Update item using direct Map
  static Future<void> updateItemDirect(String itemId,
      Map<String, dynamic> itemData) async {
    await _firestore.collection('items').doc(itemId).update(itemData);
  }

  static Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }

  static Stream<List<ItemModel>> getItemsStream() {
    return _firestore
        .collection('items')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ItemModel.fromJson(data);
        }).toList())
        .handleError((e) {
      print('Error in getItemsStream: $e');
      return <ItemModel>[];
    });
  }

  static Stream<List<ItemModel>> getUserItemsStream(String userId) {
    return _firestore
        .collection('items')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ItemModel.fromJson(data);
        }).toList())
        .handleError((e) {
      print('Error in getUserItemsStream: $e');
      return <ItemModel>[];
    });
  }

  static Future<List<ItemModel>> searchItems(String query) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ItemModel.fromJson(data);
      })
          .where((item) =>
      item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching items: $e');
      return [];
    }
  }

  // ==================== CHAT ====================

  static Future<String> createOrGetChat(
      String otherUserId,
      String itemId,
      String itemTitle,
      ) async {
    final currentUserId = currentUser!.uid;

    try {
      print('=== Creating/Getting Chat ===');
      print('Current user: $currentUserId');
      print('Other user: $otherUserId');
      print('Item: $itemId - $itemTitle');

      // Check if chat already exists between these two users
      // We'll check both ways (currentUser->otherUser and otherUser->currentUser)
      final existingChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      print('Found ${existingChats.docs.length} chats for current user');

      // Look for a chat with both participants
      for (var doc in existingChats.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        // Check if this chat includes both users
        if (participants.contains(currentUserId) && participants.contains(otherUserId)) {
          print('✅ Found existing chat: ${doc.id}');

          // Update the item info in case they're discussing a different item now
          await doc.reference.update({
            'itemId': itemId,
            'itemTitle': itemTitle,
            'lastMessageTime': DateTime.now().toIso8601String(),
          });

          return doc.id;
        }
      }

      print('No existing chat found, creating new one...');
    } catch (e) {
      print('Error checking existing chats: $e');
    }

    // Create new chat if none exists
    final chatData = {
      'participants': [currentUserId, otherUserId],
      'itemId': itemId,
      'itemTitle': itemTitle,
      'lastMessage': '',
      'lastMessageTime': DateTime.now().toIso8601String(),
      'lastSenderId': '',
    };

    final docRef = await _firestore.collection('chats').add(chatData);
    print('✅ Created new chat: ${docRef.id}');
    return docRef.id;
  }

  static Stream<List<ChatModel>> getUserChatsStream() {
    final userId = currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs.map((doc) {
        final data = doc.data();
        data['chatId'] = doc.id;

        // Extract unread count for current user
        final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
        data['unreadCount'] = unreadCounts[userId] ?? 0;

        return ChatModel.fromJson(data);
      }).toList();

      // Sort by lastMessageTime
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    })
        .handleError((e) {
      print('Error in getUserChatsStream: $e');
      return <ChatModel>[];
    });
  }

  static Future<void> sendMessage(String chatId, String content) async
  {
    final currentUserId = currentUser!.uid;

    final messageData = {
      'senderId': currentUserId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Get the chat document to find the other participant
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);

    // Find the other user ID
    final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );

    final updates = <String, dynamic>{
      'lastMessage': content,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'lastSenderId': currentUserId,
    };

    // Increment unread count for the other user
    if (otherUserId.isNotEmpty) {
      updates['unreadCounts.$otherUserId'] = FieldValue.increment(1);
    }

    await _firestore.collection('chats').doc(chatId).update(updates);
  }

  static Future<void> sendPhotoMessage(String chatId, File photoFile) async {
    final currentUserId = currentUser!.uid;

    // Upload photo to ImgBB
    final photoUrl = await ImageUploadService.uploadImage(photoFile);

    final messageData = {
      'senderId': currentUserId,
      'content': 'Photo',
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
      'messageType': 'photo',
      'photoUrl': photoUrl,
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Get the chat document to find the other participant
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);

    // Find the other user ID
    final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );

    final updates = <String, dynamic>{
      'lastMessage': '📷 Photo',
      'lastMessageTime': DateTime.now().toIso8601String(),
      'lastSenderId': currentUserId,
    };

    // Increment unread count for the other user
    if (otherUserId.isNotEmpty) {
      updates['unreadCounts.$otherUserId'] = FieldValue.increment(1);
    }

    await _firestore.collection('chats').doc(chatId).update(updates);
  }

  static Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['messageId'] = doc.id;
          return MessageModel.fromJson(data);
        }).toList())
        .handleError((e) {
      print('Error in getMessagesStream: $e');
      return <MessageModel>[];
    });
  }

  /// Mark chat as read by resetting unread count for current user
  static Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  /// Mark all messages as read in a chat
  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Also update the chat's lastSenderId
      await _firestore.collection('chats').doc(chatId).update({
        'lastSenderId': userId,
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Get unread message count for a specific chat
  static Future<int> getUnreadMessageCount(String chatId, String userId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return messagesSnapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get total unread messages count across all chats
  static Stream<int> getTotalUnreadCountStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts = Map<String, dynamic>.from(data['unreadCounts'] ?? {});

        // Read unread count for this user from the map
        final userUnreadCount = unreadCounts[userId] ?? 0;
        if (userUnreadCount is int && userUnreadCount > 0) {
          total += userUnreadCount;
        }
      }
      return total;
    });
  }

  // ==================== STORAGE ====================

  static Future<String> uploadImage(File file, String path) async {
    try {
      print('Uploading to path: $path');
      final ref = _storage.ref().child(path);

      // Upload file
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for completion
      final snapshot = await uploadTask;
      print('Upload complete, getting download URL...');

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  static Future<List<String>> uploadMultipleImages(List<File> files,
      String basePath,) async
  {
    List<String> urls = [];
    for (int i = 0; i < files.length; i++) {
      final path = '$basePath/${DateTime
          .now()
          .millisecondsSinceEpoch}_$i.jpg';
      final url = await uploadImage(files[i], path);
      urls.add(url);
    }
    return urls;
  }

  // ==================== SAVED ITEMS (FAVORITES) ====================

  /// Add item to user's saved items
  static Future<void> addToSavedItems(String userId, String itemId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('savedItems')
        .doc(itemId)
        .set({
      'itemId': itemId,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Remove item from user's saved items
  static Future<void> removeFromSavedItems(String userId, String itemId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('savedItems')
        .doc(itemId)
        .delete();
  }

  /// Check if item is saved by user
  static Future<bool> isItemSaved(String userId, String itemId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedItems')
          .doc(itemId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking if item is saved: $e');
      return false;
    }
  }

  /// Get stream of saved item IDs
  static Stream<List<String>> getSavedItemsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedItems')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList())
        .handleError((e) {
      print('Error in getSavedItemsStream: $e');
      return <String>[];
    });
  }

  /// Get multiple items by their IDs
  static Future<List<ItemModel>> getItemsByIds(List<String> itemIds) async {
    if (itemIds.isEmpty) return [];

    try {
      List<ItemModel> items = [];

      // Firestore 'in' query has a limit of 10 items
      // So we need to batch the requests if we have more than 10
      for (int i = 0; i < itemIds.length; i += 10) {
        final batch = itemIds.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection('items')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          if (doc.exists) {
            final data = doc.data();
            data['id'] = doc.id;
            items.add(ItemModel.fromJson(data));
          }
        }
      }

      return items;
    } catch (e) {
      print('Error getting items by IDs: $e');
      return [];
    }
  }

  /// Toggle saved status (add if not saved, remove if saved)
  static Future<bool> toggleSavedItem(String userId, String itemId) async {
    try {
      final isSaved = await isItemSaved(userId, itemId);

      if (isSaved) {
        await removeFromSavedItems(userId, itemId);
        return false; // Now not saved
      } else {
        await addToSavedItems(userId, itemId);
        return true; // Now saved
      }
    } catch (e) {
      print('Error toggling saved item: $e');
      rethrow;
    }
  }

  // ==================== NOTIFICATIONS ====================

  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('notifications').add(notification.toJson());
      await docRef.update({'id': docRef.id});
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  static Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data()))
            .toList())
        .handleError((e) {
      print('Error getting notifications: $e');
      return <NotificationModel>[];
    });
  }

  static Stream<int> getUnreadNotificationsCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((e) {
      print('Error getting unread notifications count: $e');
      return 0;
    });
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // ==================== EXCHANGES (FIXED) ====================

  /// Create a new exchange proposal
  static Future<String> createExchange({
    required String proposedTo,
    required List<ExchangeItem> itemsOffered,
    required List<ExchangeItem> itemsRequested,
    String? notes,
  }) async {
    final currentUserId = currentUser!.uid;

    // Create or get existing chat for this item (using the first requested item as context)
    final chatId = await createOrGetChat(
      proposedTo,
      itemsRequested.first.itemId,
      itemsRequested.first.title,
    );

    final exchangeData = {
      'status': 0, // ExchangeStatus.pending
      'proposedBy': currentUserId,
      'proposedTo': proposedTo,
      'participants': [currentUserId, proposedTo],
      'itemsOffered': itemsOffered.map((i) => i.toJson()).toList(),
      'itemsRequested': itemsRequested.map((i) => i.toJson()).toList(),
      // Legacy fields for backward compatibility
      'itemOffered': itemsOffered.first.toJson(),
      'itemRequested': itemsRequested.first.toJson(),
      'proposedAt': DateTime.now().toIso8601String(),
      'confirmedBy': [],
      'notes': notes,
      'chatId': chatId,
    };

    final docRef = await _firestore.collection('exchanges').add(exchangeData);
    await docRef.update({'id': docRef.id});

    print('Created exchange: ${docRef.id}');

    // Notify the receiver
    await createNotification(
      userId: proposedTo,
      title: 'New Exchange Request',
      body: 'You have a new exchange request!',
      type: NotificationType.exchangeRequest,
      relatedId: docRef.id,
    );

    return docRef.id;
  }

  /// Accept an exchange proposal
  static Future<void> acceptExchange(String exchangeId) async {
    // Get exchange details
    final doc = await _firestore.collection('exchanges').doc(exchangeId).get();
    final data = doc.data()!;

    // Handle both new list format and legacy single item format
    List<String> itemOfferedIds = [];
    if (data['itemsOffered'] != null) {
      itemOfferedIds = (data['itemsOffered'] as List)
          .map((i) => i['itemId'] as String)
          .toList();
    } else if (data['itemOffered'] != null) {
      itemOfferedIds.add(data['itemOffered']['itemId']);
    }

    List<String> itemRequestedIds = [];
    if (data['itemsRequested'] != null) {
      itemRequestedIds = (data['itemsRequested'] as List)
          .map((i) => i['itemId'] as String)
          .toList();
    } else if (data['itemRequested'] != null) {
      itemRequestedIds.add(data['itemRequested']['itemId']);
    }

    // Update exchange status
    await _firestore.collection('exchanges').doc(exchangeId).update({
      'status': 1, // ExchangeStatus.accepted
      'acceptedAt': DateTime.now().toIso8601String(),
    });

    // Mark all items as unavailable
    final batch = _firestore.batch();

    for (final id in itemOfferedIds) {
      batch.update(_firestore.collection('items').doc(id), {'isAvailable': false});
    }

    for (final id in itemRequestedIds) {
      batch.update(_firestore.collection('items').doc(id), {'isAvailable': false});
    }

    await batch.commit();

    print('Marked items as unavailable: $itemOfferedIds, $itemRequestedIds');

    // Notify the proposer
    await createNotification(
      userId: data['proposedBy'],
      title: 'Exchange Accepted',
      body: 'Your exchange request has been accepted!',
      type: NotificationType.exchangeAccepted,
      relatedId: exchangeId,
    );
  }

  /// Reject/Cancel an exchange
  static Future<void> cancelExchange(String exchangeId) async {
    // Get exchange details
    final doc = await _firestore.collection('exchanges').doc(exchangeId).get();
    final data = doc.data()!;

    // Check if exchange was accepted (status = 1)
    // If so, make items available again
    if (data['status'] == 1) {
      List<String> itemOfferedIds = [];
      if (data['itemsOffered'] != null) {
        itemOfferedIds = (data['itemsOffered'] as List)
            .map((i) => i['itemId'] as String)
            .toList();
      } else if (data['itemOffered'] != null) {
        itemOfferedIds.add(data['itemOffered']['itemId']);
      }

      List<String> itemRequestedIds = [];
      if (data['itemsRequested'] != null) {
        itemRequestedIds = (data['itemsRequested'] as List)
            .map((i) => i['itemId'] as String)
            .toList();
      } else if (data['itemRequested'] != null) {
        itemRequestedIds.add(data['itemRequested']['itemId']);
      }

      // Make all items available again
      final batch = _firestore.batch();

      for (final id in itemOfferedIds) {
        batch.update(_firestore.collection('items').doc(id), {'isAvailable': true});
      }

      for (final id in itemRequestedIds) {
        batch.update(_firestore.collection('items').doc(id), {'isAvailable': true});
      }

      await batch.commit();

      print('Made items available again: $itemOfferedIds, $itemRequestedIds');
    }

    // Update exchange status to cancelled
    await _firestore.collection('exchanges').doc(exchangeId).update({
      'status': 3, // ExchangeStatus.cancelled
    });

    // Notify the other party
    final currentUserId = currentUser!.uid;
    final otherUserId = data['proposedBy'] == currentUserId
        ? data['proposedTo']
        : data['proposedBy'];

    await createNotification(
      userId: otherUserId,
      title: 'Exchange Cancelled',
      body: 'An exchange request was cancelled.',
      type: NotificationType.exchangeCancelled,
      relatedId: exchangeId,
    );
  }

  /// Confirm exchange completion by a user
  static Future<void> confirmExchangeCompletion(String exchangeId) async {
    final userId = currentUser!.uid;

    final doc = await _firestore.collection('exchanges').doc(exchangeId).get();
    final data = doc.data()!;
    final confirmedBy = List<String>.from(data['confirmedBy'] ?? []);

    if (!confirmedBy.contains(userId)) {
      confirmedBy.add(userId);

      // If both users confirmed, mark as completed
      final proposedBy = data['proposedBy'];
      final proposedTo = data['proposedTo'];
      final bothConfirmed = confirmedBy.contains(proposedBy) &&
          confirmedBy.contains(proposedTo);

      await _firestore.collection('exchanges').doc(exchangeId).update({
        'confirmedBy': confirmedBy,
        'status': bothConfirmed ? 2 : 1, // completed : accepted
        'completedAt': bothConfirmed ? DateTime.now().toIso8601String() : null,
      });

      // Notify the other party that you confirmed
      final otherUserId = proposedBy == userId ? proposedTo : proposedBy;
      await createNotification(
        userId: otherUserId,
        title: 'Exchange Confirmation',
        body: 'The other party has confirmed the exchange completion.',
        type: NotificationType.exchangeCompleted, // Use generic type for now
        relatedId: exchangeId,
      );

      if (bothConfirmed) {
        // Notify both that it is fully completed
        await createNotification(
          userId: proposedBy,
          title: 'Exchange Completed',
          body: 'The exchange has been successfully completed!',
          type: NotificationType.exchangeCompleted,
          relatedId: exchangeId,
        );
        await createNotification(
          userId: proposedTo,
          title: 'Exchange Completed',
          body: 'The exchange has been successfully completed!',
          type: NotificationType.exchangeCompleted,
          relatedId: exchangeId,
        );
      }
    }
  }

  /// Update meeting details
  static Future<void> updateMeetingDetails(
      String exchangeId,
      String? location,
      DateTime? date,
      ) async {
    final updates = <String, dynamic>{};

    if (location != null) {
      updates['meetingLocation'] = location;
    }
    if (date != null) {
      updates['meetingDate'] = date.toIso8601String();
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('exchanges').doc(exchangeId).update(updates);
    }
  }

  /// Add rating and review
  static Future<void> rateExchange(
      String exchangeId,
      double rating,
      String? review,
      ) async {
    final userId = currentUser!.uid;

    final doc = await _firestore.collection('exchanges').doc(exchangeId).get();
    final data = doc.data()!;
    final proposedBy = data['proposedBy'];

    final updates = <String, dynamic>{};

    if (userId == proposedBy) {
      updates['ratingByProposer'] = rating;
      if (review != null) updates['reviewByProposer'] = review;
    } else {
      updates['ratingByAccepter'] = rating;
      if (review != null) updates['reviewByAccepter'] = review;
    }

    await _firestore.collection('exchanges').doc(exchangeId).update(updates);
  }

  /// Get exchange by ID
  static Future<ExchangeModel?> getExchangeById(String exchangeId) async {
    try {
      final doc = await _firestore.collection('exchanges').doc(exchangeId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return ExchangeModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting exchange by ID: $e');
      return null;
    }
  }

  /// Get user's exchanges (as proposer or receiver)
  static Stream<List<ExchangeModel>> getUserExchangesStream(String userId) {
    print('Getting exchanges for user: $userId');

    return _firestore
        .collection('exchanges')
        .where('participants', arrayContains: userId)
        .orderBy('proposedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ExchangeModel.fromJson(data);
      }).toList();
    })
        .handleError((e) {
      print('Error in getUserExchangesStream: $e');
      return <ExchangeModel>[];
    });
  }

  /// Get pending exchanges stream for notification badge (incoming only)
  static Stream<List<ExchangeModel>> getPendingExchangesStream() {
    final userId = currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('exchanges')
        .where('proposedTo', isEqualTo: userId)
        .where('status', isEqualTo: 0) // ExchangeStatus.pending
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ExchangeModel.fromJson(data);
      }).toList();
    })
        .handleError((e) {
      print('Error in getPendingExchangesStream: $e');
      return <ExchangeModel>[];
    });
  }

  /// Get exchanges for a specific item (both offered and requested)
  static Future<List<ExchangeModel>> getItemExchanges(String itemId) async {
    try {
      // Get exchanges where this item is offered (legacy check)
      final offeredSnapshot = await _firestore
          .collection('exchanges')
          .where('itemOffered.itemId', isEqualTo: itemId)
          .get();

      // Get exchanges where this item is requested (legacy check)
      final requestedSnapshot = await _firestore
          .collection('exchanges')
          .where('itemRequested.itemId', isEqualTo: itemId)
          .get();

      // Note: For full multi-item support in queries, we'd need to query against arrays
      // but Firestore doesn't support array-contains-any on objects easily.
      // For now, this covers the legacy cases and primary item cases.

      final allDocs = [...offeredSnapshot.docs, ...requestedSnapshot.docs];
      final uniqueIds = <String>{};
      final uniqueDocs = allDocs.where((doc) {
        if (uniqueIds.contains(doc.id)) return false;
        uniqueIds.add(doc.id);
        return true;
      }).toList();

      return uniqueDocs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ExchangeModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting item exchanges: $e');
      return [];
    }
  }


  // ============================================
// ADD THESE METHODS TO YOUR FirebaseService CLASS
// ============================================

  // ==================== LOCATION-BASED QUERIES ====================

  /// Get items within a specific radius from a location
  static Future<List<ItemModel>> getItemsNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    ItemCategory? category,
  }) async {
    try {
      print('Searching items within ${radiusKm}km of ($latitude, $longitude)');

      // Get all available items (we'll filter by distance in memory)
      var query = _firestore
          .collection('items')
          .where('isAvailable', isEqualTo: true);

      // Add category filter if specified
      if (category != null) {
        query = query.where('category', isEqualTo: category.index);
      }

      final snapshot = await query.get();

      // Filter items by distance
      final nearbyItems = <ItemModel>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final item = ItemModel.fromJson(data);

        // Check if item has coordinates and is within radius
        if (item.hasCoordinates &&
            item.isWithinRadius(latitude, longitude, radiusKm)) {
          nearbyItems.add(item);
        }
      }

      // Sort by distance (closest first)
      nearbyItems.sort((a, b) {
        final distA = a.distanceFrom(latitude, longitude) ?? double.infinity;
        final distB = b.distanceFrom(latitude, longitude) ?? double.infinity;
        return distA.compareTo(distB);
      });

      print('Found ${nearbyItems.length} items within radius');
      return nearbyItems;
    } catch (e) {
      print('Error getting nearby items: $e');
      return [];
    }
  }

  /// Get items near current user's location
  static Future<List<ItemModel>> getItemsNearMe({
    required double radiusKm,
    ItemCategory? category,
  }) async {
    try {
      // Get current position
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied');
        return [];
      }

      Position position = await Geolocator.getCurrentPosition();

      return await getItemsNearLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: radiusKm,
        category: category,
      );
    } catch (e) {
      print('Error getting items near me: $e');
      return [];
    }
  }

  /// Search items by query and filter by location
  static Future<List<ItemModel>> searchItemsNearLocation({
    required String query,
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      // First get all matching search results
      final searchResults = await searchItems(query);

      // Then filter by location
      final nearbyResults = searchResults.where((item) {
        return item.hasCoordinates &&
            item.isWithinRadius(latitude, longitude, radiusKm);
      }).toList();

      // Sort by distance
      nearbyResults.sort((a, b) {
        final distA = a.distanceFrom(latitude, longitude) ?? double.infinity;
        final distB = b.distanceFrom(latitude, longitude) ?? double.infinity;
        return distA.compareTo(distB);
      });

      return nearbyResults;
    } catch (e) {
      print('Error searching nearby items: $e');
      return [];
    }
  }

  /// Get stream of items ordered by distance from a location
  static Stream<List<ItemModel>> getItemsStreamNearLocation({
    required double latitude,
    required double longitude,
    double? maxDistanceKm,
  }) {
    return _firestore
        .collection('items')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ItemModel.fromJson(data);
      }).toList();

      // Filter by distance if specified
      var filteredItems = items.where((item) {
        if (!item.hasCoordinates) return false;
        if (maxDistanceKm == null) return true;
        return item.isWithinRadius(latitude, longitude, maxDistanceKm);
      }).toList();

      // Sort by distance
      filteredItems.sort((a, b) {
        final distA = a.distanceFrom(latitude, longitude) ?? double.infinity;
        final distB = b.distanceFrom(latitude, longitude) ?? double.infinity;
        return distA.compareTo(distB);
      });

      return filteredItems;
    })
        .handleError((e) {
      print('Error in getItemsStreamNearLocation: $e');
      return <ItemModel>[];
    });
  }

  /// Get items grouped by distance ranges
  static Future<Map<String, List<ItemModel>>> getItemsByDistanceRanges(
      double latitude,
      double longitude,
      ) async {
    try {
      final allItems = await _firestore
          .collection('items')
          .where('isAvailable', isEqualTo: true)
          .get();

      final Map<String, List<ItemModel>> ranges = {
        'Under 1km': [],
        '1-5km': [],
        '5-10km': [],
        '10-25km': [],
        '25km+': [],
      };

      for (var doc in allItems.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final item = ItemModel.fromJson(data);

        if (!item.hasCoordinates) continue;

        final distance = item.distanceFrom(latitude, longitude);
        if (distance == null) continue;

        if (distance < 1) {
          ranges['Under 1km']!.add(item);
        } else if (distance < 5) {
          ranges['1-5km']!.add(item);
        } else if (distance < 10) {
          ranges['5-10km']!.add(item);
        } else if (distance < 25) {
          ranges['10-25km']!.add(item);
        } else {
          ranges['25km+']!.add(item);
        }
      }

      return ranges;
    } catch (e) {
      print('Error getting items by distance ranges: $e');
      return {};
    }
  }

  /// Count items within a specific radius
  static Future<int> countItemsNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final items = await getItemsNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      return items.length;
    } catch (e) {
      print('Error counting nearby items: $e');
      return 0;
    }
  }

  /// Get the closest item to a location
  static Future<ItemModel?> getClosestItem({
    required double latitude,
    required double longitude,
    ItemCategory? category,
  }) async {
    try {
      final items = await getItemsNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: 100, // Search within 100km
        category: category,
      );

      if (items.isEmpty) return null;

      // Items are already sorted by distance
      return items.first;
    } catch (e) {
      print('Error getting closest item: $e');
      return null;
    }
  }

  /// Update item location
  static Future<void> updateItemLocation({
    required String itemId,
    required double latitude,
    required double longitude,
    required String location,
    String? detailedAddress,
  }) async {
    await _firestore.collection('items').doc(itemId).update({
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'detailedAddress': detailedAddress,
    });
  }

  /// Get items on map (with coordinates only)
  static Future<List<ItemModel>> getItemsForMap() async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('isAvailable', isEqualTo: true)
          .where('latitude', isNull: false)
          .where('longitude', isNull: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ItemModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting items for map: $e');
      // Fallback: get all items and filter
      final snapshot = await _firestore
          .collection('items')
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ItemModel.fromJson(data);
      })
          .where((item) => item.hasCoordinates)
          .toList();
    }
  }
}