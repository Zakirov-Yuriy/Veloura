import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/profile_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> saveProfile(ProfileModel profile) async {
    await _firestore.collection('users').doc(profile.uid).update(
          profile.toMap(),
        );
  }
}