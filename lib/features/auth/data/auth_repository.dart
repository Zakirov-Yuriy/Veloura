import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

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

  /// Вход через Google.
  /// Возвращает true, если это новый пользователь (нужно отправить
  /// на /profile-setup), и false, если аккаунт уже существует (на /home).
  Future<bool> signInWithGoogle() async {
    final UserCredential userCredential;

    if (kIsWeb) {
      // На Web используем popup от FirebaseAuth, чтобы не настраивать
      // clientId вручную и не ловить зависание плагина.
      final googleProvider = GoogleAuthProvider();
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      // google_sign_in 7.x: authenticate() вместо signIn().
      // При отмене пользователем бросает GoogleSignInException(canceled).
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      userCredential =
          await _auth.signInWithCredential(credential);
    }

    final user = userCredential.user!;
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final isNewUser = !snapshot.exists;

    if (isNewUser) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'createdAt': Timestamp.now(),
      });
    }

    return isNewUser;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
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