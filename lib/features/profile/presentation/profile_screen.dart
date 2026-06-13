import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/luxury_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Пользователь не найден')));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LuxuryScreen(child: Center(child: CircularProgressIndicator(color: LuxuryColors.gold))));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: LuxuryScreen(child: Center(child: Text('Профиль не найден'))));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final photos = List<String>.from(data['photoUrls'] ?? []);
        final photoUrl = photos.isNotEmpty ? photos.first : null;

        return Scaffold(
          body: LuxuryScreen(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
                        IconButton(onPressed: () => context.push('/profile-setup'), icon: const Icon(Icons.edit_outlined)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [ 
                        Container(
                          width: 156,
                          height: 156,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: LuxuryColors.gold, width: 2.0)),
                          child: CircleAvatar(
                            backgroundColor: LuxuryColors.black2,
                            backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                            child: photoUrl == null ? const Icon(Icons.person, size: 76, color: LuxuryColors.gold) : null,
                          ),
                        ),
                        // Positioned(
                        //   right: 2,
                        //   bottom: 8,
                        //   child: Container(
                        //     width: 46,
                        //     height: 46,
                        //     decoration: BoxDecoration(shape: BoxShape.circle, gradient: luxuryGradient, border: Border.all(color: LuxuryColors.black, width: 3)),
                        //     child: const Icon(Icons.workspace_premium, color: Colors.white),
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${data['name'] ?? 'Пользователь'}, ${data['age'] ?? ''}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: LuxuryColors.gold, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                        Text(data['city'] ?? '', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _StatsPanel(uid: currentUser.uid),
                    const SizedBox(height: 18),
                    LuxuryPanel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          // _ProfileMenu(icon: Icons.workspace_premium, title: 'Премиум аккаунт', onTap: () {}),
                          _ProfileMenu(icon: Icons.image_outlined, title: 'Мои фото', onTap: () => context.push('/profile-setup')),
                          // _ProfileMenu(icon: Icons.star_border, title: 'Избранные', onTap: () {}),
                          _ProfileMenu(icon: Icons.block, title: 'Заблокированные', onTap: () => context.push('/blocked-users')),
                          _ProfileMenu(
                            icon: Icons.logout,
                            title: 'Выйти',
                            onTap: () async {
                              await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({'isOnline': false, 'lastSeen': Timestamp.now()});
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) context.go('/sign-in');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: LuxuryColors.gold, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: LuxuryColors.muted, fontSize: 11)),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final String uid;

  const _StatsPanel({required this.uid});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return LuxuryPanel(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Лайки, которые получил пользователь.
          // Если нужно считать отправленные лайки, замените
          // 'toUserId' на 'fromUserId'.
          _LiveStat(
            label: 'Лайков',
            query: firestore
                .collection('likes')
                .where('toUserId', isEqualTo: uid),
          ),
          // Матчи: документы коллекции matches, где массив users содержит мой uid.
          _LiveStat(
            label: 'Матчей',
            query: firestore
                .collection('matches')
                .where('users', arrayContains: uid),
          ),
          // Друзей: отдельной коллекции в проекте пока нет.
          // const _Stat(value: '0', label: 'Друзей'),
        ],
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  final String label;
  final Query<Map<String, dynamic>> query;

  const _LiveStat({required this.label, required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('[$label] ОШИБКА: ${snapshot.error}');
          return _Stat(value: 'E', label: label);
        }
        if (!snapshot.hasData) {
          return _Stat(value: '...', label: label);
        }
        final count = snapshot.data!.docs.length;
        debugPrint('[$label] найдено документов: $count');
        return _Stat(value: '$count', label: label);
      },
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenu({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: LuxuryColors.gold),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
      onTap: onTap,
    );
  }
}