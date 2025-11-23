// ============================================
// FILE: lib/firebase/firebase_service.dart
// ============================================

import 'package:barter/model/chat_model.dart';
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
          user.displayName ?? user.email?.split('@').first ?? 'User',
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
  static Future<void> updateItemDirect(String itemId, Map<String, dynamic> itemData) async {
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
        .map((snapshot) => snapshot.docs.map((doc) {
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
        .map((snapshot) => snapshot.docs.map((doc) {
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
      // Check if chat already exists for this item between these two users
      final existingChats = await _firestore
          .collection('chats')
          .where('itemId', isEqualTo: itemId)
          .get();

      // Look for a chat with both participants
      for (var doc in existingChats.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        // Check if both users are in this chat
        if (participants.contains(currentUserId) && participants.contains(otherUserId)) {
          print('Found existing chat: ${doc.id}');
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
    print('Created new chat: ${docRef.id}');
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

  static Future<void> sendMessage(String chatId, String content) async {
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
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      data['messageId'] = doc.id;
      return MessageModel.fromJson(data);
    }).toList())
        .handleError((e) {
      print('Error in getMessagesStream: $e');
      return <MessageModel>[];
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

  static Future<List<String>> uploadMultipleImages(
      List<File> files,
      String basePath,
      ) async {
    List<String> urls = [];
    for (int i = 0; i < files.length; i++) {
      final path = '$basePath/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
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
}