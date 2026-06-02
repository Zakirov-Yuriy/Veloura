import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/utils/presence.dart';
import '../../safety/presentation/providers/safety_provider.dart';
import 'providers/matches_provider.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(myMatchesProvider);

    return Scaffold(
      body: LuxuryScreen(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Матчи', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    SvgPicture.asset('assets/icons/king.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(LuxuryColors.gold, BlendMode.srcIn)),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: matchesAsync.when(
                    data: (matches) {
                      final blocked = ref.watch(blockedUserIdsProvider).value ?? <String>{};
                      final visibleMatches = matches.where((m) {
                        final ou = Map<String, dynamic>.from(m['otherUser'] ?? {});
                        return !blocked.contains(ou['uid']);
                      }).toList();
                      if (visibleMatches.isEmpty) return const Center(child: Text('Матчей пока нет'));
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 22,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.74,
                        ),
                        itemCount: visibleMatches.length,
                        itemBuilder: (context, index) {
                          final match = visibleMatches[index];
                          final otherUser = match['otherUser'] as Map<String, dynamic>;
                          final photos = List<String>.from(otherUser['photoUrls'] ?? []);
                          final photoUrl = photos.isNotEmpty ? photos.first : null;
                          final isOnline = isUserOnline(otherUser);
                          return GestureDetector(
                            onTap: () => context.push('/chat/${match['id']}'),
                            child: Column(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: LuxuryColors.gold, width: 2.0)),
                                  child: CircleAvatar(
                                    backgroundColor: LuxuryColors.black2,
                                    backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                                    child: photoUrl == null ? const Icon(Icons.person, color: LuxuryColors.gold) : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  otherUser['name'] ?? 'Пользователь',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                Text(
                                  isOnline ? 'Онлайн' : 'Не в сети',
                                  style: TextStyle(
                                    color: isOnline ? LuxuryColors.online : Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: LuxuryColors.gold)),
                    error: (error, _) => Center(child: Text(error.toString())),
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