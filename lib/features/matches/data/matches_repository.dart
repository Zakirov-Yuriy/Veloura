import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchesRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  Stream<List<Map<String, dynamic>>> getMyMatches() async* {
    await for (final snapshot in _firestore
        .collection('matches')
        .where('users', arrayContains: currentUserId)
        .snapshots()) {
      final matches = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final match = doc.data();

        final users = List<String>.from(match['users']);

        final otherUserId = users.firstWhere(
          (id) => id != currentUserId,
        );

        final userDoc = await _firestore
            .collection('users')
            .doc(otherUserId)
            .get();

        final userData = userDoc.data();

        if (userData != null) {
          matches.add({
            ...match,
            'otherUser': userData,
          });
        }
      }

      yield matches;
    }
  }
}
