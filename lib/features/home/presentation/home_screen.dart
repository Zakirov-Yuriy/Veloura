import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'providers/home_provider.dart';
import 'widgets/profile_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final swiperController = AppinioSwiperController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // leading: IconButton(
        //   icon: const Icon(Icons.person_outline),
        //   color: Colors.black,
        //   onPressed: () {},
        // ),
        title: SvgPicture.asset(
          'assets/images/Logo.svg',
          width: 30,
          height: 30,
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.tune),
        //     color: Colors.black,
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(
              child: Text(
                'Анкет пока нет',
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                Expanded(
                  child: AppinioSwiper(
                    controller: swiperController,
                    backgroundCardCount: 3,
                    swipeOptions: const SwipeOptions.all(),
                    cardCount: profiles.length,
                    onSwipeEnd: (previousIndex, targetIndex, activity) async {
                      final profile = profiles[previousIndex];

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
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HomeRoundButton(
                      icon: Icons.close,
                      color: const Color(0xFFEC0120),
                      onTap: () {
                        swiperController.swipeLeft();
                      },
                    ),
                    const SizedBox(width: 38),
                    _HomeRoundButton(
                      icon: Icons.favorite,
                      color: const Color.fromARGB(255, 35, 146, 102),
                      onTap: () {
                        swiperController.swipeRight();
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
            child: Text(
              error.toString(),
              style: const TextStyle(color: Colors.black),
            ),
          );
        },
      ),
    );
  }
}

class _HomeRoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeRoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: CircleBorder(
        side: BorderSide(
          color: color,
          width: 2.0,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 74,
          height: 74,
          child: Icon(
            icon,
            color: color,
            size: 36,
          ),
        ),
      ),
    );
  }
}