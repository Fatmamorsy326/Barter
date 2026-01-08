import 'dart:io';

import 'package:barter/model/chat_model.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/model/user_model.dart';
import 'package:barter/model/notification_model.dart';
import 'package:barter/model/review_model.dart';
import 'package:barter/services/image_upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;

  // ==================== AUTH ====================

  static Future<UserCredential> signUp(
      String email,
      String password,
      String name,
      ) async {
    print('🔵 FIREBASE: signUp called');
    print('🔵 FIREBASE: Email = $email');
    print('🔵 FIREBASE: Name = $name');

    // Step 1: Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    print('✅ FIREBASE: Auth account created');

    try {
      // Step 2: Update displayName FIRST (before any errors)
      await credential.user!.updateDisplayName(name);
      print('✅ FIREBASE: DisplayName updated to: $name');

      // Step 3: Create Firestore document with the name
      await _createUserDocument(credential.user!, name);
      print('✅ FIREBASE: User document created');

      // Step 4: Send verification email
      await credential.user?.sendEmailVerification();
      print('✅ FIREBASE: Verification email sent to: ${credential.user?.email}');
    } catch (e) {
      print('❌ FIREBASE: Error in post-signup steps: $e');
      // Even if there's an error, the account is created
      // Let's ensure the document exists with the correct name
      try {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': credential.user!.email ?? '',
          'name': name, // Use the name parameter directly
          'createdAt': DateTime.now().toIso8601String(),
        });
        print('✅ FIREBASE: User document created (fallback)');
      } catch (e2) {
        print('❌ FIREBASE: Fallback document creation failed: $e2');
      }
    }

    return credential;
  }


  static Future<void> ensureUserDocument() async {
    final user = currentUser;
    if (user == null) return;

    try {
      print('🔍 FIREBASE: Checking if user document exists for ${user.uid}');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print('⚠️ FIREBASE: User document missing');

        // IMPORTANT: Check displayName first, then email
        final name = user.displayName?.trim();

        if (name != null && name.isNotEmpty) {
          print('✅ FIREBASE: Using displayName: $name');
          await _createUserDocument(user, name);
        } else {
          print('⚠️ FIREBASE: displayName is null, using email prefix');
          final emailName = user.email?.split('@').first ?? 'User';
          await _createUserDocument(user, emailName);
        }
      } else {
        final existingName = userDoc.data()?['name'];
        print('✅ FIREBASE: User document exists with name: $existingName');

        // Optional: Sync displayName from Firestore to Auth if they differ
        if (user.displayName != existingName && existingName != null) {
          print('🔄 FIREBASE: Syncing displayName to Auth: $existingName');
          await user.updateDisplayName(existingName);
        }
      }
    } catch (e) {
      print('❌ FIREBASE: Error in ensureUserDocument: $e');
    }
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

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('🔵 FIREBASE: Google Sign-In started');
      
      // Force account selection picker by signing out first
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('⚠️ FIREBASE: Google Sign-In cancelled by user');
        return null;
      }
      
      print('✅ FIREBASE: Google user obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);
      
      print('✅ FIREBASE: Firebase authentication successful');
      
      // Ensure user document exists (captures profile info from Google)
      await ensureUserDocument();
      
      return userCredential;
    } catch (e) {
      print('❌ FIREBASE: Error in signInWithGoogle: $e');
      rethrow;
    }
  }

  static Future<UserModel?> getUserById(String uid) async {
    try {
      print('🔍 Getting user from Firestore: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromJson(doc.data()!);
        print('✅ Found user in Firestore: ${user.name}');
        return user;
      }

      print('⚠️ User document not found in Firestore');
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }


  static Future<UserCredential> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      print('✅ FIREBASE: Signed in anonymously: ${credential.user?.uid}');

      // Create a minimal user document for anonymous user
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': '',
          'name': 'Guest',
          'isAnonymous': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      return credential;
    } catch (e) {
      print('❌ FIREBASE: Anonymous sign in failed: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ==================== USER ====================


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
    // Before deleting, cancel any pending exchanges involving this item
    await _autoCancelPendingExchanges(
      [itemId],
      'System: This exchange request has been automatically cancelled because one of the items has been deleted by its owner.',
      'An exchange you proposed was cancelled because one of the items was deleted by its owner.',
    );

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

        // Extract blockedBy list
        data['blockedBy'] = List<String>.from(data['blockedBy'] ?? []);

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

  static Future<void> sendMessage(String chatId, String content) async {
    final currentUserId = currentUser!.uid;

    // Get the chat document to check for blocks
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data() ?? {};
    final blockedBy = List<String>.from(chatData['blockedBy'] ?? []);

    if (blockedBy.isNotEmpty) {
      throw Exception('Cannot send message. This chat is blocked.');
    }

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

    // Find the other participant
    final participants = List<String>.from(chatData['participants'] ?? []);
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

    // Get the chat document to check for blocks
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data() ?? {};
    final blockedBy = List<String>.from(chatData['blockedBy'] ?? []);

    if (blockedBy.isNotEmpty) {
      throw Exception('Cannot send photo. This chat is blocked.');
    }

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

    // Find the other participant
    final participants = List<String>.from(chatData['participants'] ?? []);
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

  /// Block a user in a chat
  static Future<void> blockUser(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'blockedBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Unblock a user in a chat
  static Future<void> unblockUser(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'blockedBy': FieldValue.arrayRemove([userId]),
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

    // Check if any item is already exchanged
    for (var item in itemsRequested) {
      final doc = await _firestore.collection('items').doc(item.itemId).get();
      if (doc.exists && (doc.data()?['isExchanged'] ?? false)) {
        throw Exception('Item "${item.title}" is already part of another accepted exchange.');
      }
    }
    for (var item in itemsOffered) {
      final doc = await _firestore.collection('items').doc(item.itemId).get();
      if (doc.exists && (doc.data()?['isExchanged'] ?? false)) {
        throw Exception('Your item "${item.title}" is already part of another accepted exchange.');
      }
    }

    // Check for duplicate pending requests
    final existingQuery = await _firestore
        .collection('exchanges')
        .where('proposedBy', isEqualTo: currentUserId)
        .where('proposedTo', isEqualTo: proposedTo)
        .where('status', isEqualTo: 0) // pending
        .get();

    final currentOfferedIds = itemsOffered.map((i) => i.itemId).toSet();
    final currentRequestedIds = itemsRequested.map((i) => i.itemId).toSet();

    for (var doc in existingQuery.docs) {
      final data = doc.data();
      
      // Extract item IDs from existing request (handle list and legacy single item)
      Set<String> existingOfferedIds = {};
      if (data['itemsOffered'] != null) {
        existingOfferedIds = (data['itemsOffered'] as List).map((i) => i['itemId'] as String).toSet();
      } else if (data['itemOffered'] != null) {
        existingOfferedIds.add(data['itemOffered']['itemId']);
      }

      Set<String> existingRequestedIds = {};
      if (data['itemsRequested'] != null) {
        existingRequestedIds = (data['itemsRequested'] as List).map((i) => i['itemId'] as String).toSet();
      } else if (data['itemRequested'] != null) {
        existingRequestedIds.add(data['itemRequested']['itemId']);
      }

      // Check intersection and size equality to determine if sets are equal
      final bool offeredMatch = existingOfferedIds.length == currentOfferedIds.length &&
          existingOfferedIds.containsAll(currentOfferedIds);
      
      final bool requestedMatch = existingRequestedIds.length == currentRequestedIds.length &&
          existingRequestedIds.containsAll(currentRequestedIds);

      if (offeredMatch && requestedMatch) {
         throw Exception('You have already sent this exact exchange request.');
      }
    }

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
      batch.update(_firestore.collection('items').doc(id), {'isAvailable': false, 'isExchanged': true});
    }

    for (final id in itemRequestedIds) {
      batch.update(_firestore.collection('items').doc(id), {'isAvailable': false, 'isExchanged': true});
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

  // --- AUTO-REJECT OTHER PENDING EXCHANGES ---
  final allItemIds = [...itemOfferedIds, ...itemRequestedIds];
  
  await _autoCancelPendingExchanges(
    allItemIds,
    'System: This exchange request has been automatically cancelled because one or more items involved are now exchanged in another operation.',
    'An exchange you proposed was cancelled because the items are no longer available.',
    excludeExchangeId: exchangeId,
  );
}

/// Helper to automatically cancel pending exchanges involving specific items
static Future<void> _autoCancelPendingExchanges(
  List<String> itemIds,
  String chatMessage,
  String notificationBody, {
  String? excludeExchangeId,
}) async {
  try {
    // Find all pending exchanges
    final pendingSnapshot = await _firestore
        .collection('exchanges')
        .where('status', isEqualTo: 0) // ExchangeStatus.pending
        .get();

    for (var doc in pendingSnapshot.docs) {
      if (excludeExchangeId != null && doc.id == excludeExchangeId) continue;

      final data = doc.data();
      Set<String> involvedItemIds = {};

      // Helper to extract IDs from list format
      void extractFromList(dynamic list) {
        if (list is List) {
          for (var item in list) {
            if (item is Map && item['itemId'] != null) {
              involvedItemIds.add(item['itemId'].toString());
            }
          }
        }
      }

      // Helper to extract IDs from legacy single-item format
      void extractFromLegacy(dynamic item) {
        if (item is Map && item['itemId'] != null) {
          involvedItemIds.add(item['itemId'].toString());
        }
      }

      // Check new List format
      extractFromList(data['itemsOffered']);
      extractFromList(data['itemsRequested']);

      // Check legacy single-item format
      extractFromLegacy(data['itemOffered']);
      extractFromLegacy(data['itemRequested']);

      final hasOverlap = involvedItemIds.any((id) => itemIds.contains(id));

      if (hasOverlap) {
        // Automatically cancel this exchange
        await _firestore.collection('exchanges').doc(doc.id).update({
          'status': 3, // ExchangeStatus.cancelled
        });

        // Send a system message to the chat
        final chatId = data['chatId'] as String? ?? '';
        if (chatId.isNotEmpty) {
          await sendMessage(chatId, chatMessage);
        }

        // Notify the proposer
        final proposedBy = data['proposedBy'] as String? ?? '';
        if (proposedBy.isNotEmpty) {
          await createNotification(
            userId: proposedBy,
            title: 'Exchange Cancelled',
            body: notificationBody,
            type: NotificationType.exchangeCancelled,
            relatedId: doc.id,
          );
        }
        
        // Notify the receiver if they are not the current user
        final proposedTo = data['proposedTo'] as String? ?? '';
        final currentUid = currentUser?.uid;
        if (proposedTo.isNotEmpty && proposedTo != currentUid) {
           await createNotification(
            userId: proposedTo,
            title: 'Exchange Cancelled',
            body: 'An exchange request was cancelled because the items are no longer available.',
            type: NotificationType.exchangeCancelled,
            relatedId: doc.id,
          );
        }
      }
    }
  } catch (e) {
    print('Error in auto-cancelling exchanges: $e');
  }
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
        batch.update(_firestore.collection('items').doc(id), {'isAvailable': true, 'isExchanged': false});
      }

      for (final id in itemRequestedIds) {
        batch.update(_firestore.collection('items').doc(id), {'isAvailable': true, 'isExchanged': false});
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

  // ==================== LOCATION-BASED QUERIES ====================

  /// Get items within a specific radius from a location
  static Future<List<ItemModel>> getItemsNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    ItemCategory? category,
    List<ItemCondition>? conditions,
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

      // Add condition filter if specified
      if (conditions != null && conditions.isNotEmpty) {
        query = query.where('condition', whereIn: conditions.map((e) => e.index).toList());
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
    List<ItemCondition>? conditions,
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
        conditions: conditions,
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
  // ==================== FIREBASE SERVICE - EMAIL VERIFICATION ====================
// Add these methods to your FirebaseService class

// Send email verification
  static Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    if (!user.emailVerified) {
      await user.sendEmailVerification();
      print('✅ Verification email sent to: ${user.email}');
    } else {
      print('⚠️ Email already verified');
    }
  }

// Check if email is verified
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

// Reload user to check verification status
  static Future<void> reloadUser() async {
    await currentUser?.reload();
    print('User reloaded, verified: ${currentUser?.emailVerified}');
  }

// Sign up with email verification
  static Future<UserCredential> signUpWithVerification(
      String email,
      String password,
      String name,
      ) async
  {
    print('🔵 FIREBASE: signUp with verification called');
    print('🔵 FIREBASE: Email = $email');
    print('🔵 FIREBASE: Name = $name');

    // Step 1: Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    print('✅ FIREBASE: Auth account created');

    try {
      // Step 2: Update displayName
      await credential.user!.updateDisplayName(name);
      print('✅ FIREBASE: DisplayName updated to: $name');

      // Step 3: Create Firestore document
      await _createUserDocument(credential.user!, name);
      print('✅ FIREBASE: User document created');

      // Step 4: Send verification email
      await credential.user!.sendEmailVerification();
      print('✅ FIREBASE: Verification email sent');

    } catch (e) {
      print('❌ FIREBASE: Error in post-signup steps: $e');
      // Fallback: ensure document exists
      try {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': credential.user!.email ?? '',
          'name': name,
          'createdAt': DateTime.now().toIso8601String(),
          'emailVerified': false,
        });
        print('✅ FIREBASE: User document created (fallback)');

        // Try to send verification email anyway
        await credential.user!.sendEmailVerification();
      } catch (e2) {
        print('❌ FIREBASE: Fallback failed: $e2');
      }
    }

    return credential;
  }

// Update _createUserDocument to include email verification status
  static Future<void> _createUserDocument(User user, String name) async {
    print('🔵 FIREBASE: _createUserDocument called');
    print('🔵 FIREBASE: Name parameter = $name');

    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: name,
      createdAt: DateTime.now(),
      emailVerified: user.emailVerified, // Add this field
    );

    print('🔵 FIREBASE: UserModel created with name: ${userModel.name}');
    print('🔵 FIREBASE: Saving to Firestore...');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toJson());

    print('✅ FIREBASE: User document saved successfully');
  }

  // ==================== MFA / 2FA ====================

  /// Generates a random 6-digit OTP and saves it to Firestore with a 5-minute expiry.
  /// Also triggers a real email if the 'Trigger Email' extension is configured.
  static Future<void> generateAndSendOtp(String uid) async {
    try {
      final otp = (100000 + (DateTime.now().millisecond * 899999) ~/ 1000).toString().padLeft(6, '0');
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));

      print('🔵 FIREBASE: Generating OTP for $uid: $otp');

      // 1. Save OTP for verification
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('mfa')
          .doc('current_otp')
          .set({
        'otp': otp,
        'expiresAt': expiresAt.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. Trigger Real Email via extension
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final email = userDoc.data()?['email'] ?? currentUser?.email;

      if (email != null && email.isNotEmpty) {
        await _firestore.collection('mail').add({
          'to': email,
          'message': {
            'subject': 'Your Barter Verification Code: $otp',
            'html': '''
              <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 500px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #6200EE; text-align: center;">Barter Security</h2>
                <p>Hello,</p>
                <p>You are receiving this email because a Two-Step Verification was requested for your Barter account.</p>
                <div style="background: #f9f9f9; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
                  <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #333;">$otp</span>
                </div>
                <p style="font-size: 13px; color: #777;">This code will expire in 5 minutes. If you did not request this, please ignore this email.</p>
                <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="font-size: 11px; color: #999; text-align: center;">© 2024 Barter App. Professional Exchange Platform.</p>
              </div>
            ''',
          },
        });
        print('✅ FIREBASE: Email trigger document created for $email');
      } else {
        print('⚠️ FIREBASE: Could not find email to send OTP');
      }

      print('✅ FIREBASE: OTP saved to Firestore (expires at $expiresAt)');
    } catch (e) {
      print('❌ FIREBASE: Error generating OTP: $e');
      rethrow;
    }
  }

  /// Verifies if the provided OTP matches and hasn't expired.
  static Future<bool> verifyOtp(String uid, String code) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('mfa')
          .doc('current_otp')
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final savedOtp = data['otp'];
      final expiresAt = DateTime.parse(data['expiresAt']);

      if (DateTime.now().isAfter(expiresAt)) {
        print('⚠️ FIREBASE: OTP has expired');
        return false;
      }

      if (savedOtp == code) {
        print('✅ FIREBASE: OTP verified successfully');
        // Clear the OTP after successful verification
        await doc.reference.delete();
        return true;
      }

      print('❌ FIREBASE: OTP mismatch');
      return false;
    } catch (e) {
      print('❌ FIREBASE: Error verifying OTP: $e');
      return false;
    }
  }

  // ==================== REVIEWS ====================

  static Future<void> submitReview({
    required String exchangeId,
    required String revieweeId,
    required double rating,
    required String comment,
  }) async {
    final reviewerId = currentUser!.uid;
    final reviewId = _firestore.collection('reviews').doc().id;

    final review = ReviewModel(
      id: reviewId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      exchangeId: exchangeId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Get Exchange and User refs
        final exchangeRef = _firestore.collection('exchanges').doc(exchangeId);
        final userRef = _firestore.collection('users').doc(revieweeId);

        final exchangeDoc = await transaction.get(exchangeRef);
        final userDoc = await transaction.get(userRef);

        if (!exchangeDoc.exists || !userDoc.exists) {
          throw Exception('Exchange or User not found');
        }

        // 2. Add Review to collection
        final reviewRef = _firestore.collection('reviews').doc(reviewId);
        final reviewData = review.toJson();
        reviewData['createdAt'] = FieldValue.serverTimestamp();
        transaction.set(reviewRef, reviewData);

        // 3. Update Exchange with review data
        final data = exchangeDoc.data()!;
        final isProposer = data['proposedBy'] == reviewerId;

        if (isProposer) {
          transaction.update(exchangeRef, {
            'ratingByProposer': rating,
            'reviewByProposer': comment,
          });
        } else {
          transaction.update(exchangeRef, {
            'ratingByAccepter': rating,
            'reviewByAccepter': comment,
          });
        }

        // 4. Update User stats
        final userData = userDoc.data()!;
        final currentRatingSum = (userData['ratingSum'] ?? 0).toDouble();
        final currentReviewCount = (userData['reviewCount'] ?? 0) as int;

        transaction.update(userRef, {
          'ratingSum': currentRatingSum + rating,
          'reviewCount': currentReviewCount + 1,
        });
      });
    } catch (e) {
      print('Error submitting review: $e');
      rethrow;
    }
  }

  static Stream<List<ReviewModel>> getUserReviews(String userId) {
    print('Querying reviews for userId: $userId');
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          print('Reviews snapshot received: ${snapshot.docs.length} documents');
          return snapshot.docs
              .map((doc) {
                print('Review doc data: ${doc.data()}');
                final data = doc.data();
                // Handle Firestore Timestamp
                if (data['createdAt'] is Timestamp) {
                  data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
                }
                return ReviewModel.fromJson(data);
              })
              .toList();
        });
  }

  /// Toggles MFA for the current user.
  static Future<void> toggleMfa(bool enabled) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'mfaEnabled': enabled,
    });
    print('✅ FIREBASE: MFA ${enabled ? 'enabled' : 'disabled'} for user ${user.uid}');
  }
}