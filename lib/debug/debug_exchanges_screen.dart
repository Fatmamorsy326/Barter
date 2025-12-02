// ============================================
// FILE: lib/debug/debug_exchanges_screen.dart
// ============================================
// USE THIS TO DEBUG - Add a button in your app to open this screen

import 'package:barter/firebase/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DebugExchangesScreen extends StatelessWidget {
  const DebugExchangesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Exchanges'),
      ),
      body: SingleChildScrollView(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current User ID:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            Text(userId ?? 'Not logged in'),
            SizedBox(height: 24.h),

            // Show all exchanges in Firestore
            Text(
              'All Exchanges in Database:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('exchanges')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text('No exchanges in database at all');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final proposedBy = data['proposedBy'] ?? 'N/A';
                    final proposedTo = data['proposedTo'] ?? 'N/A';
                    final participants = data['participants'] ?? [];
                    final status = data['status'] ?? 'N/A';

                    return Card(
                      margin: REdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: REdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${doc.id}',
                                style: TextStyle(fontSize: 11.sp, fontFamily: 'monospace')),
                            Text('Status: $status'),
                            Text('ProposedBy: $proposedBy'),
                            Text('ProposedTo: $proposedTo'),
                            Text('Participants: $participants'),
                            Text('Has participants field: ${data.containsKey('participants')}'),
                            if (userId != null) ...[
                              Text('You are proposer: ${proposedBy == userId}'),
                              Text('You are receiver: ${proposedTo == userId}'),
                              Text('You are in participants: ${participants.contains(userId)}'),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            SizedBox(height: 24.h),

            // Test the query
            if (userId != null) ...[
              Text(
                'Exchanges Where You Are Participant:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('exchanges')
                    .where('participants', arrayContains: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text('Query returns 0 results - THIS IS THE PROBLEM!');
                  }

                  return Text('Query returns ${docs.length} exchanges - Good!');
                },
              ),

              SizedBox(height: 24.h),

              Text(
                'Pending Exchanges For You:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
              SizedBox(height: 12.h),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('exchanges')
                    .where('proposedTo', isEqualTo: userId)
                    .where('status', isEqualTo: 0)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text('No pending exchanges');
                  }

                  return Text('${docs.length} pending exchanges');
                },
              ),
            ],

            SizedBox(height: 24.h),

            ElevatedButton(
              onPressed: () => _fixExistingExchanges(context),
              child: const Text('Fix Existing Exchanges (Add participants field)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fixExistingExchanges(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exchanges')
          .get();

      int fixed = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Check if participants field exists
        if (!data.containsKey('participants')) {
          final proposedBy = data['proposedBy'];
          final proposedTo = data['proposedTo'];

          // Add participants field
          await doc.reference.update({
            'participants': [proposedBy, proposedTo],
          });

          fixed++;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fixed $fixed exchanges')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}