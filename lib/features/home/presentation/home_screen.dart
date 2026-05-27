import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/home_provider.dart';
import 'widgets/profile_card.dart';
import 'widgets/swipe_action_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veloura'),
        centerTitle: true,
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(
              child: Text('Анкет пока нет'),
            );
          }

          final currentProfile = profiles.first;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: AppinioSwiper(
                    cardCount: profiles.length,
                    onSwipeEnd: (previousIndex, targetIndex, activity) async {
                      final profile = profiles[previousIndex];
                      debugPrint('activity: $activity');
                      debugPrint('direction: ${activity.direction}');

                      if (activity is Swipe) {
                        if (activity.direction == AxisDirection.right) {
                          final isMatch = await ref
                              .read(homeRepositoryProvider)
                              .likeUser(profile['uid']);

                          ref.invalidate(profilesProvider);

                          if (isMatch && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('У вас новый матч 🔥'),
                              ),
                            );
                          }
                        }

                        if (activity.direction == AxisDirection.left) {
                          await ref
                              .read(homeRepositoryProvider)
                              .passUser(profile['uid']);

                          ref.invalidate(profilesProvider);
                        }
                      }
                    },
                    cardBuilder: (context, index) {
                      final profile = profiles[index];

                      return GestureDetector(
                        onTap: () {
                          context.push(
                            '/profile-details',
                            extra: profile,
                          );
                        },
                        child: ProfileCard(profile: profile),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    SwipeActionButton(
                      icon: Icons.close,
                      onTap: () async {
                        await ref
                            .read(homeRepositoryProvider)
                            .passUser(currentProfile['uid']);

                        ref.invalidate(profilesProvider);
                      },
                    ),
                    SwipeActionButton(
                      icon: Icons.favorite,
                      onTap: () async {
                        final isMatch = await ref
                            .read(homeRepositoryProvider)
                            .likeUser(currentProfile['uid']);

                        ref.invalidate(profilesProvider);

                        if (isMatch && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text('У вас новый матч 🔥'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(error.toString()),
          );
        },
      ),
    );
  }
}