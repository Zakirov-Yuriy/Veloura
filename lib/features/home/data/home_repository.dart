import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class HomeRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getProfiles() {
    final currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('users')
        .where('profileCompleted', isEqualTo: true)
        .snapshots()
        .asyncMap((usersSnapshot) async {
      final likesSnapshot =
          await _firestore.collection('likes').get();

      final passesSnapshot =
          await _firestore.collection('passes').get();

      final blocksSnapshot =
          await _firestore.collection('blocks').get();

      final likedUserIds = likesSnapshot.docs
          .where(
            (doc) =>
                doc['fromUserId'] == currentUserId,
          )
          .map((doc) => doc['toUserId'] as String)
          .toList();

      final passedUserIds = passesSnapshot.docs
          .where(
            (doc) =>
                doc['fromUserId'] == currentUserId,
          )
          .map((doc) => doc['toUserId'] as String)
          .toList();

      final blockedUserIds = blocksSnapshot.docs
          .where(
            (doc) => doc['fromUserId'] == currentUserId,
          )
          .map((doc) => doc['blockedUserId'] as String)
          .toList();

      final excludedIds = [
        ...likedUserIds,
        ...passedUserIds,
        ...blockedUserIds,
      ];

      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      final currentUserData =
          currentUserDoc.data() ?? {};

      final lookingFor =
          currentUserData['lookingFor'];

      final minAge =
          currentUserData['minAge'] ?? 18;

      final maxAge =
          currentUserData['maxAge'] ?? 100;

      return usersSnapshot.docs
          .map((doc) => doc.data())
          .where(
            (user) =>
                user['uid'] != currentUserId &&
                !excludedIds.contains(
                  user['uid'],
                ) &&
                user['gender'] == lookingFor &&
                (user['age'] ?? 0) >= minAge &&
                (user['age'] ?? 0) <= maxAge,
          )
          .toList();
    });
  }

  Future<void> passUser(String toUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    await _firestore.collection('passes').add({
      'fromUserId': currentUserId,
      'toUserId': toUserId,
      'createdAt': Timestamp.now(),
    });
  }

  Future<bool> likeUser(String toUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    await _firestore.collection('likes').add({
      'fromUserId': currentUserId,
      'toUserId': toUserId,
      'createdAt': Timestamp.now(),
    });

    final reverseLikeSnapshot = await _firestore
        .collection('likes')
        .where('fromUserId', isEqualTo: toUserId)
        .where('toUserId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    if (reverseLikeSnapshot.docs.isEmpty) {
      return false;
    }

    final users = [currentUserId, toUserId]..sort();

    final matchId = users.join('_');

    await _firestore.collection('matches').doc(matchId).set({
      'id': matchId,
      'users': users,
      'createdAt': Timestamp.now(),
    });

    await _firestore.collection('chats').doc(matchId).set({
      'id': matchId,
      'matchId': matchId,
      'members': users,
      'lastMessage': '',
      'updatedAt': Timestamp.now(),
    });

    return true;
  }
}
