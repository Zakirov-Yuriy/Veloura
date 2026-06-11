import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class HomeRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Одноразовая загрузка анкет для ленты.
  ///
  /// Лайки, пропуски и блокировки запрашиваются только СВОИ (фильтр по
  /// fromUserId). Анкеты фильтруются по полу на стороне сервера и
  /// ограничиваются порцией в [_feedBatchSize] документов, чтобы при
  /// тысячах профилей (включая ботов) не выкачивать всю базу: это и
  /// квота чтений Firestore, и память устройства.
  ///
  /// Обновление ленты — через ref.invalidate(profilesProvider).
  static const _feedBatchSize = 100;

  Future<List<Map<String, dynamic>>> getProfiles() async {
    final currentUserId = _auth.currentUser!.uid;

    // Сначала свой профиль: его настройки нужны для фильтра анкет.
    final currentUserDoc =
        await _firestore.collection('users').doc(currentUserId).get();
    final currentUserData = currentUserDoc.data() ?? {};

    final lookingFor = currentUserData['lookingFor'];
    final minAge = currentUserData['minAge'] ?? 18;
    final maxAge = currentUserData['maxAge'] ?? 100;

    final results = await Future.wait([
      _firestore
          .collection('users')
          .where('profileCompleted', isEqualTo: true)
          .where('gender', isEqualTo: lookingFor)
          .limit(_feedBatchSize)
          .get(),
      _firestore
          .collection('likes')
          .where('fromUserId', isEqualTo: currentUserId)
          .get(),
      _firestore
          .collection('passes')
          .where('fromUserId', isEqualTo: currentUserId)
          .get(),
      _firestore
          .collection('blocks')
          .where('fromUserId', isEqualTo: currentUserId)
          .get(),
    ]);

    final usersSnapshot = results[0];
    final likesSnapshot = results[1];
    final passesSnapshot = results[2];
    final blocksSnapshot = results[3];

    final excludedIds = <String>{
      ...likesSnapshot.docs.map((doc) => doc['toUserId'] as String),
      ...passesSnapshot.docs.map((doc) => doc['toUserId'] as String),
      ...blocksSnapshot.docs.map((doc) => doc['blockedUserId'] as String),
    };

    return usersSnapshot.docs
        .map((doc) => doc.data())
        .where(
          (user) =>
              user['uid'] != currentUserId &&
              !excludedIds.contains(user['uid']) &&
              (user['age'] ?? 0) >= minAge &&
              (user['age'] ?? 0) <= maxAge,
        )
        .toList();
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