import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> init() async {
    await _messaging.requestPermission();

    final token = await _messaging.getToken();

    final user = _auth.currentUser;

    if (user == null || token == null) {
      return;
    }

    await _firestore.collection('users').doc(user.uid).set(
      {
        'fcmToken': token,
      },
      SetOptions(merge: true),
    );
  }
}
