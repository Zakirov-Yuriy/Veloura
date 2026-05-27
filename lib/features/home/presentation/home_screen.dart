import 'package:cached_network_image/cached_network_image.dart';
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

          final profile = profiles.first;

          final photos =
              List<String>.from(profile['photoUrls'] ?? []);

          final photoUrl =
              photos.isNotEmpty ? photos.first : null;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: Dismissible(
                    key: ValueKey(profile['uid']),
                    direction: DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
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
                      } else {
                        await ref
                            .read(homeRepositoryProvider)
                            .passUser(profile['uid']);

                        ref.invalidate(profilesProvider);
                      }

                      return false;
                    },
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 32),
                      child: const Icon(
                        Icons.favorite,
                        size: 56,
                      ),
                    ),
                    secondaryBackground: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 32),
                      child: const Icon(
                        Icons.close,
                        size: 56,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        context.push(
                          '/profile-details',
                          extra: profile,
                        );
                      },
                      child: ProfileCard(profile: profile),
                    ),
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
                            .passUser(profile['uid']);

                        ref.invalidate(profilesProvider);
                      },
                    ),
                    SwipeActionButton(
                      icon: Icons.favorite,
                      onTap: () async {
                        final isMatch = await ref
                            .read(homeRepositoryProvider)
                            .likeUser(profile['uid']);

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