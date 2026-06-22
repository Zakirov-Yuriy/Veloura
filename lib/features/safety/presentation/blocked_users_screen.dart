import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/bot_localization.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/utils/presence.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/safety_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                    Text(
                      l10n.blockedTitle,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: blockedUsersAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.noBlockedUsers,
                            style: const TextStyle(color: LuxuryColors.muted),
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
                          final name = context.botField(user, 'name');

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
                              name.isNotEmpty ? name : l10n.user,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              isUserOnline(user) ? l10n.online : l10n.offline,
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
                              child: Text(
                                l10n.unblock,
                                style: const TextStyle(
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
