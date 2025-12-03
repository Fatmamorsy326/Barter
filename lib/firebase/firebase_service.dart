// ============================================
// FILE: lib/firebase/firebase_service.dart
// ============================================

import 'package:barter/model/chat_model.dart';
import 'package:barter/model/exchange_model.dart';
import 'package:barter/model/item_model.dart';
import 'package:barter/model/login_request.dart';
import 'package:barter/model/register_request.dart';
import 'package:barter/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== AUTH ====================

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register - simplified and robust
  static Future<UserCredential> register(RegisterRequest request) async {
    // Step 1: Create auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: request.email,
      password: request.password,
    );

    // Step 2: Try to update display name (don't fail if this fails)
    try {
      await credential.user?.updateDisplayName(request.name);
    } catch (e) {
      print('Warning: Could not update display name: $e');
    }

    // Step 3: Try to create user document (don't fail if this fails)
    try {
      await _createUserDocument(credential.user!, request.name);
    } catch (e) {
      print('Warning: Could not create user document: $e');
    }

    return credential;
  }

  static Future<void> _createUserDocument(User user, String name) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    final userModel = UserModel(
      uid: user.uid,
      name: name,
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );

    await userDoc.set(userModel.toJson());
  }

  // Login - simplified and robust
  static Future<UserCredential> login(LoginRequest request) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: request.email,
      password: request.password,
    );

    // Try to ensure user document exists (don't fail login if this fails)
    try {
      await ensureUserDocument();
    } catch (e) {
      print('Warning: Could not ensure user document: $e');
    }

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

  // ============================================
// REPLACE createOrGetChat in firebase_service.dart
// ============================================

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
    final messageData = {
      'senderId': currentUser!.uid,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'lastSenderId': currentUser!.uid,
    });
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

  // ============================================
// ADD THIS METHOD to firebase_service.dart in the CHAT section
// ============================================

  /// Mark chat as read by updating lastSenderId to current user
  /// This removes the unread badge
  static Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSenderId': userId,
      });
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

// ============================================
// ALTERNATIVE: More sophisticated approach with unread count
// Add this if you want to track exact unread message count
// ============================================
  // ============================================

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
        final lastSenderId = data['lastSenderId'] ?? '';

        // Count as unread if last sender is not the current user
        if (lastSenderId.isNotEmpty && lastSenderId != userId) {
          total++;
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

  // ============================================
// FILE: lib/firebase/firebase_service.dart (FIXED EXCHANGE METHODS)
// ============================================

  // ==================== EXCHANGES (FIXED) ====================

  /// Create a new exchange proposal
  // ============================================
// FILE: lib/firebase/firebase_service.dart (FIXED EXCHANGE METHODS)
// ============================================

  // ==================== EXCHANGES (FIXED) ====================

  /// Create a new exchange proposal
  static Future<String> createExchange({
    required String proposedTo,
    required String itemOfferedId,
    required String itemOfferedTitle,
    required String itemOfferedImage,
    required String itemRequestedId,
    required String itemRequestedTitle,
    required String itemRequestedImage,
    String? notes,
  }) async {
    final currentUserId = currentUser!.uid;

    // Create or get existing chat for this item
    final chatId = await createOrGetChat(
      proposedTo,
      itemRequestedId,
      itemRequestedTitle,
    );

    final exchangeData = {
      'status': 0, // ExchangeStatus.pending
      'proposedBy': currentUserId,
      'proposedTo': proposedTo,
      'participants': [currentUserId, proposedTo], // ADDED THIS - Important!
      'itemOffered': {
        'itemId': itemOfferedId,
        'title': itemOfferedTitle,
        'imageUrl': itemOfferedImage,
      },
      'itemRequested': {
        'itemId': itemRequestedId,
        'title': itemRequestedTitle,
        'imageUrl': itemRequestedImage,
      },
      'proposedAt': DateTime.now().toIso8601String(),
      'confirmedBy': [],
      'notes': notes,
      'chatId': chatId,
    };

    final docRef = await _firestore.collection('exchanges').add(exchangeData);
    await docRef.update({'id': docRef.id});

    print('Created exchange: ${docRef.id}');
    print('Participants: [${currentUserId}, ${proposedTo}]');

    return docRef.id;
  }

  /// Accept an exchange proposal
  static Future<void> acceptExchange(String exchangeId) async {
    // Get exchange details
    final doc = await _firestore.collection('exchanges').doc(exchangeId).get();
    final data = doc.data()!;

    final itemOfferedId = data['itemOffered']['itemId'];
    final itemRequestedId = data['itemRequested']['itemId'];

    // Update exchange status
    await _firestore.collection('exchanges').doc(exchangeId).update({
      'status': 1, // ExchangeStatus.accepted
      'acceptedAt': DateTime.now().toIso8601String(),
    });

    // Mark both items as unavailable
    await _firestore.collection('items').doc(itemOfferedId).update({
      'isAvailable': false,
    });

    await _firestore.collection('items').doc(itemRequestedId).update({
      'isAvailable': false,
    });

    print('Marked items as unavailable: $itemOfferedId, $itemRequestedId');
  }

  /// Reject/Cancel an exchange
  static Future<void> cancelExchange(String exchangeId) async {
    // Get exchange details
    final doc = await _firestore.collection('exchanges').doc(exchangeId).get();
    final data = doc.data()!;

    // Check if exchange was accepted (status = 1)
    // If so, make items available again
    if (data['status'] == 1) {
      final itemOfferedId = data['itemOffered']['itemId'];
      final itemRequestedId = data['itemRequested']['itemId'];

      // Make both items available again
      await _firestore.collection('items').doc(itemOfferedId).update({
        'isAvailable': true,
      });

      await _firestore.collection('items').doc(itemRequestedId).update({
        'isAvailable': true,
      });

      print('Made items available again: $itemOfferedId, $itemRequestedId');
    }

    // Update exchange status to cancelled
    await _firestore.collection('exchanges').doc(exchangeId).update({
      'status': 3, // ExchangeStatus.cancelled
    });
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

  /// Get user's exchanges (as proposer or receiver) - FIXED VERSION
  static Stream<List<ExchangeModel>> getUserExchangesStream(String userId) {
    print('Getting exchanges for user: $userId');

    return _firestore
        .collection('exchanges')
        .where('participants', arrayContains: userId) // This is the key fix
        .orderBy('proposedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Found ${snapshot.docs.length} exchanges');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        print('Exchange ${doc.id}: status=${data['status']}, proposedBy=${data['proposedBy']}, proposedTo=${data['proposedTo']}');

        return ExchangeModel.fromJson(data);
      }).toList();
    })
        .handleError((e) {
      print('Error in getUserExchangesStream: $e');
      return <ExchangeModel>[];
    });
  }

  /// Get exchanges for a specific item (both offered and requested)
  static Future<List<ExchangeModel>> getItemExchanges(String itemId) async {
    try {
      // Get exchanges where this item is offered
      final offeredSnapshot = await _firestore
          .collection('exchanges')
          .where('itemOffered.itemId', isEqualTo: itemId)
          .get();

      // Get exchanges where this item is requested
      final requestedSnapshot = await _firestore
          .collection('exchanges')
          .where('itemRequested.itemId', isEqualTo: itemId)
          .get();

      // Combine both lists and remove duplicates
      final allDocs = [...offeredSnapshot.docs, ...requestedSnapshot.docs];
      final uniqueIds = <String>{};
      final uniqueDocs = allDocs.where((doc) {
        if (uniqueIds.contains(doc.id)) {
          return false;
        }
        uniqueIds.add(doc.id);
        return true;
      }).toList();

      return uniqueDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ExchangeModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting item exchanges: $e');
      return [];
    }
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
      print('Error getting exchange: $e');
      return null;
    }
  }

  /// Get pending exchange proposals for current user - FIXED VERSION
  static Stream<List<ExchangeModel>> getPendingExchangesStream() {
    final userId = currentUser?.uid;
    if (userId == null) {
      print('No current user for pending exchanges');
      return Stream.value([]);
    }

    print('Getting pending exchanges for user: $userId');

    return _firestore
        .collection('exchanges')
        .where('proposedTo', isEqualTo: userId)
        .where('status', isEqualTo: 0) // pending only
        .orderBy('proposedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Found ${snapshot.docs.length} pending exchanges');

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
  }}