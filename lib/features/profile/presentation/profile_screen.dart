import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Пользователь не найден'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text('Профиль не найден'),
            ),
          );
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>;

        final photos =
            List<String>.from(data['photoUrls'] ?? []);

        final photoUrl =
            photos.isNotEmpty ? photos.first : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Профиль'),
            actions: [
              IconButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .update({
                    'isOnline': false,
                    'lastSeen': Timestamp.now(),
                  });

                  await FirebaseAuth.instance
                      .signOut();

                  if (context.mounted) {
                    context.go('/sign-in');
                  }
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(
                          photoUrl,
                        )
                      : null,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 70,
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  '${data['name']}, ${data['age']}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['city'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['bio'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/profile-setup');
                    },
                    child: const Text('Редактировать профиль'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      context.go('/blocked-users');
                    },
                    child: const Text('Заблокированные пользователи'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
