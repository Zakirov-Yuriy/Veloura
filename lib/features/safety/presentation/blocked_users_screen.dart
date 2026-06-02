import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/luxury_theme.dart';
import '../../../core/utils/presence.dart';
import 'providers/safety_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      body: LuxuryScreen(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Заблокированные',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: blockedUsersAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return const Center(
                          child: Text(
                            'Заблокированных пользователей нет',
                            style: TextStyle(color: LuxuryColors.muted),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withOpacity(0.06),
                          indent: 72,
                        ),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final photos = List<String>.from(user['photoUrls'] ?? []);
                          final photoUrl = photos.isNotEmpty ? photos.first : null;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: LuxuryColors.gold.withOpacity(0.8), width: 2.0),
                              ),
                              child: CircleAvatar(
                                radius: 27,
                                backgroundColor: LuxuryColors.black2,
                                backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                                child: photoUrl == null ? const Icon(Icons.person, color: LuxuryColors.gold) : null,
                              ),
                            ),
                            title: Text(
                              user['name'] ?? 'Пользователь',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              isUserOnline(user) ? 'Онлайн' : 'Не в сети',
                              style: TextStyle(
                                color: isUserOnline(user) ? LuxuryColors.online : LuxuryColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                await ref
                                    .read(safetyRepositoryProvider)
                                    .unblockUser(user['blockId']);

                                ref.invalidate(blockedUsersProvider);
                              },
                              child: const Text(
                                'Разблокировать',
                                style: TextStyle(
                                  color: LuxuryColors.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: LuxuryColors.gold),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}