import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'uid': credential.user!.uid,
      'email': email,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> setOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.now(),
    });
  }
}