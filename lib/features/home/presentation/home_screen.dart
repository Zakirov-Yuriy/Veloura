import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/luxury_theme.dart';
import 'providers/home_provider.dart';
import 'widgets/profile_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final swiperController = AppinioSwiperController();

    return Scaffold(
      body: LuxuryScreen(
        child: SafeArea(
          child: profilesAsync.when(
            data: (profiles) {
              if (profiles.isEmpty) {
                return const Center(child: Text('Анкет пока нет'));
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 104),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.tune, color: LuxuryColors.gold),
                        VelouraWordmark(size: 18),
                        Icon(Icons.workspace_premium, color: LuxuryColors.gold),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: AppinioSwiper(
                        controller: swiperController,
                        backgroundCardCount: 2,
                        swipeOptions: const SwipeOptions.all(),
                        cardCount: profiles.length,
                        onSwipeEnd: (previousIndex, targetIndex, activity) async {
                          final profile = profiles[previousIndex];
                          if (activity.direction == AxisDirection.right) {
                            final isMatch = await ref.read(homeRepositoryProvider).likeUser(profile['uid']);
                            ref.invalidate(profilesProvider);
                            if (isMatch && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('У вас новый матч')));
                            }
                          }
                          if (activity.direction == AxisDirection.left) {
                            await ref.read(homeRepositoryProvider).passUser(profile['uid']);
                            ref.invalidate(profilesProvider);
                          }
                        },
                        cardBuilder: (context, index) {
                          final profile = profiles[index];
                          return GestureDetector(
                            onTap: () => context.push('/profile-details', extra: profile),
                            child: ProfileCard(profile: profile),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HomeRoundButton(icon: Icons.close, onTap: swiperController.swipeLeft),
                        const SizedBox(width: 26),
                        // _HomeRoundButton(icon: Icons.star, onTap: () {}, featured: true),
                        // const SizedBox(width: 26),
                        _HomeRoundButton(icon: Icons.favorite, onTap: swiperController.swipeRight, filled: true),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: LuxuryColors.gold)),
            error: (error, _) => Center(child: Text(error.toString())),
          ),
        ),
      ),
    );
  }
}

class _HomeRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool featured;

  const _HomeRoundButton({required this.icon, required this.onTap, this.filled = false, this.featured = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: filled || featured ? luxuryGradient : null,
          color: filled || featured ? null : Colors.black.withOpacity(0.35),
          border: Border.all(color: LuxuryColors.gold.withOpacity(0.65), width: 2.0),
          boxShadow: [BoxShadow(color: LuxuryColors.gold.withOpacity(0.18), blurRadius: 0, spreadRadius: 1)],
        ),
        child: Icon(icon, color: filled ? Colors.white : LuxuryColors.gold, size: featured ? 30 : 35),
      ),
    );
  }
}
