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

  // Auth Methods
  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> register(RegisterRequest request) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: request.email,
      password: request.password,
    );

    // Create user document in Firestore
    await _createUserDocument(credential.user!, request.name!);
    return credential;
  }

  static Future<void> _createUserDocument(User user, String name) async {
    final userModel = UserModel(
      uid: user.uid,
      name: name,
      email: user.email!,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toJson());
  }

  static Future<UserCredential> login(LoginRequest request) async {
    return await _auth.signInWithEmailAndPassword(
      email: request.email,
      password: request.password,
    );
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // User Methods
  static Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  static Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toJson());
  }

  // Item Methods
  static Future<String> addItem(ItemModel item) async {
    final docRef = await _firestore.collection('items').add(item.toJson());
    return docRef.id;
  }

  static Future<void> updateItem(ItemModel item) async {
    await _firestore.collection('items').doc(item.id).update(item.toJson());
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
        .map((snapshot) => snapshot.docs
        .map((doc) => ItemModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList());
  }

  static Stream<List<ItemModel>> getUserItemsStream(String userId) {
    return _firestore
        .collection('items')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ItemModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList());
  }

  static Future<List<ItemModel>> searchItems(String query) async {
    final snapshot = await _firestore
        .collection('items')
        .where('isAvailable', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ItemModel.fromJson({...doc.data(), 'id': doc.id}))
        .where((item) =>
    item.title.toLowerCase().contains(query.toLowerCase()) ||
        item.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Chat Methods
  static Future<String> createOrGetChat(
      String otherUserId,
      String itemId,
      String itemTitle,
      ) async {
    final currentUserId = currentUser!.uid;

    // Check if chat exists
    final existingChat = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .where('itemId', isEqualTo: itemId)
        .get();

    for (var doc in existingChat.docs) {
      final participants = List<String>.from(doc.data()['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new chat
    final chat = ChatModel(
      chatId: '',
      participants: [currentUserId, otherUserId],
      itemId: itemId,
      itemTitle: itemTitle,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      lastSenderId: '',
    );

    final docRef = await _firestore.collection('chats').add(chat.toJson());
    return docRef.id;
  }

  static Stream<List<ChatModel>> getUserChatsStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser!.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatModel.fromJson({...doc.data(), 'chatId': doc.id}))
        .toList());
  }

  static Future<void> sendMessage(String chatId, String content) async {
    final message = MessageModel(
      messageId: '',
      senderId: currentUser!.uid,
      content: content,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toJson());

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
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        MessageModel.fromJson({...doc.data(), 'messageId': doc.id}))
        .toList());
  }

  // Storage Methods
  static Future<String> uploadImage(File file, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}