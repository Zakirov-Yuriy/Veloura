import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SafetyRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
  }) async {
    await _firestore.collection('reports').add({
      'fromUserId': currentUserId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> blockUser(String blockedUserId) async {
    await _firestore.collection('blocks').add({
      'fromUserId': currentUserId,
      'blockedUserId': blockedUserId,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<Map<String, dynamic>>> getBlockedUsers() async* {
    await for (final snapshot in _firestore
        .collection('blocks')
        .where('fromUserId', isEqualTo: currentUserId)
        .snapshots()) {
      final users = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final userDoc = await _firestore
            .collection('users')
            .doc(data['blockedUserId'])
            .get();

        final userData = userDoc.data();

        if (userData != null) {
          users.add({
            ...userData,
            'blockId': doc.id,
          });
        }
      }

      yield users;
    }
  }

  Future<void> unblockUser(String blockId) async {
    await _firestore.collection('blocks').doc(blockId).delete();
  }
}