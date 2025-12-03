// // ============================================
// // FILE: lib/helpers/chat_cleanup_helper.dart
// // CREATE THIS FILE - One-time cleanup utility
// // ============================================
//
// import 'package:barter/firebase/firebase_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class ChatCleanupHelper {
//   /// Merges duplicate chats for the current user
//   /// Run this once to clean up existing duplicate chats
//   static Future<Map<String, dynamic>> mergeDuplicateChats() async {
//     final userId = FirebaseService.currentUser?.uid;
//     if (userId == null) {
//       return {'success': false, 'error': 'User not logged in'};
//     }
//
//     print('=== Starting Chat Cleanup ===');
//     print('User ID: $userId');
//
//     try {
//       // Get all chats for this user
//       final chatsSnapshot = await FirebaseFirestore.instance
//           .collection('chats')
//           .where('participants', arrayContains: userId)
//           .get();
//
//       print('Found ${chatsSnapshot.docs.length} total chats');
//
//       // Group chats by other participant
//       final Map<String, List<QueryDocumentSnapshot>> chatsByUser = {};
//
//       for (var doc in chatsSnapshot.docs) {
//         final data = doc.data();
//         final participants = List<String>.from(data['participants'] ?? []);
//
//         // Get the other user
//         final otherUserId = participants.firstWhere(
//               (id) => id != userId,
//           orElse: () => '',
//         );
//
//         if (otherUserId.isEmpty) continue;
//
//         if (!chatsByUser.containsKey(otherUserId)) {
//           chatsByUser[otherUserId] = [];
//         }
//         chatsByUser[otherUserId]!.add(doc);
//       }
//
//       print('Found ${chatsByUser.length} unique conversation partners');
//
//       int merged = 0;
//       int deleted = 0;
//
//       // Process each group
//       for (var entry in chatsByUser.entries) {
//         final otherUserId = entry.key;
//         final userChats = entry.value;
//
//         if (userChats.length > 1) {
//           print('User $otherUserId has ${userChats.length} duplicate chats');
//
//           // Sort by last message time (newest first)
//           userChats.sort((a, b) {
//             final aData = a.data();
//             final bData = b.data();
//
//             final aTimeStr = aData['lastMessageTime'] as String?;
//             final bTimeStr = bData['lastMessageTime'] as String?;
//
//             final aTime = aTimeStr != null
//                 ? DateTime.parse(aTimeStr)
//                 : DateTime.now();
//             final bTime = bTimeStr != null
//                 ? DateTime.parse(bTimeStr)
//                 : DateTime.now();
//
//             return bTime.compareTo(aTime);
//           });
//
//           // Keep the most recent chat
//           final keepChat = userChats.first;
//           print('Keeping chat: ${keepChat.id}');
//
//           // Merge messages from other chats
//           for (int i = 1; i < userChats.length; i++) {
//             final oldChat = userChats[i];
//             print('Merging chat: ${oldChat.id}');
//
//             // Get all messages from old chat
//             final messagesSnapshot = await FirebaseFirestore.instance
//                 .collection('chats')
//                 .doc(oldChat.id)
//                 .collection('messages')
//                 .get();
//
//             print('  Found ${messagesSnapshot.docs.length} messages to merge');
//
//             // Copy messages to the kept chat
//             for (var messageDoc in messagesSnapshot.docs) {
//               await FirebaseFirestore.instance
//                   .collection('chats')
//                   .doc(keepChat.id)
//                   .collection('messages')
//                   .add(messageDoc.data());
//             }
//
//             // Delete old chat
//             await FirebaseFirestore.instance
//                 .collection('chats')
//                 .doc(oldChat.id)
//                 .delete();
//
//             deleted++;
//           }
//
//           merged++;
//         }
//       }
//
//       print('=== Cleanup Complete ===');
//       print('Merged: $merged conversation groups');
//       print('Deleted: $deleted duplicate chats');
//
//       return {
//         'success': true,
//         'merged': merged,
//         'deleted': deleted,
//         'total': chatsSnapshot.docs.length,
//         'unique': chatsByUser.length,
//       };
//     } catch (e) {
//       print('Error during cleanup: $e');
//       return {
//         'success': false,
//         'error': e.toString(),
//       };
//     }
//   }
// }
//
// // ============================================
// // USAGE: Add this button temporarily to your settings or debug screen
// // ============================================
//
// /*
// ElevatedButton(
//   onPressed: () async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         title: Text('Cleaning up chats...'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 16),
//             Text('Please wait...'),
//           ],
//         ),
//       ),
//     );
//
//     final result = await ChatCleanupHelper.mergeDuplicateChats();
//
//     Navigator.pop(context);
//
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(result['success'] ? 'Success' : 'Error'),
//         content: Text(
//           result['success']
//               ? 'Merged ${result['merged']} conversations\n'
//                 'Deleted ${result['deleted']} duplicate chats\n'
//                 'You now have ${result['unique']} unique conversations'
//               : 'Error: ${result['error']}',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   },
//   child: Text('Cleanup Duplicate Chats'),
// )
// */