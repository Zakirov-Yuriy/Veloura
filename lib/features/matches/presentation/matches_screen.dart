import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/luxury_theme.dart';
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Матчи', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    Icon(Icons.workspace_premium, color: LuxuryColors.gold),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: matchesAsync.when(
                    data: (matches) {
                      if (matches.isEmpty) return const Center(child: Text('Матчей пока нет'));
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 22,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.74,
                        ),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          final otherUser = match['otherUser'] as Map<String, dynamic>;
                          final photos = List<String>.from(otherUser['photoUrls'] ?? []);
                          final photoUrl = photos.isNotEmpty ? photos.first : null;
                          return GestureDetector(
                            onTap: () => context.go('/chat/${match['id']}'),
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
                                const Text('Онлайн', style: TextStyle(color: LuxuryColors.online, fontSize: 11)),
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
