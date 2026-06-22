import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/home_provider.dart';
import 'widgets/profile_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Контроллер создаётся один раз на всё время жизни экрана,
  // а не на каждый build (иначе кнопки лайк/дизлайк теряют связь
  // с актуальным свайпером после пересборки).
  final AppinioSwiperController swiperController = AppinioSwiperController();

  // Зафиксированная колода. Заполняется один раз из провайдера, чтобы
  // фоновые обновления стрима (например, статусы онлайн каждые 45 сек)
  // не сбрасывали свайпер и не «съедали» карточки во время свайпа.
  List<Map<String, dynamic>>? _deck;

  @override
  void dispose() {
    swiperController.dispose();
    super.dispose();
  }

  // Подтянуть свежую порцию анкет (исключая уже пролайканных/пропущенных).
  void _reload() {
    setState(() => _deck = null);
    ref.invalidate(profilesProvider);
  }

  Future<void> _onSwipeEnd(int previousIndex, int targetIndex, SwiperActivity activity) async {
    final deck = _deck;
    if (deck == null || previousIndex < 0 || previousIndex >= deck.length) return;

    final uid = deck[previousIndex]['uid'];
    if (uid == null) return;

    if (activity.direction == AxisDirection.right) {
      final isMatch = await ref.read(homeRepositoryProvider).likeUser(uid);
      if (isMatch && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).newMatchTitle)),
        );
      }
    } else if (activity.direction == AxisDirection.left) {
      await ref.read(homeRepositoryProvider).passUser(uid);
    }
    // Важно: НЕ инвалидируем провайдер здесь. Свайпер сам убирает
    // карточку из вида, а исключение учтётся при следующей загрузке.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profilesAsync = ref.watch(profilesProvider);

    return Scaffold(
      body: LuxuryScreen(
        child: SafeArea(
          child: profilesAsync.when(
            data: (profiles) {
              _deck ??= List<Map<String, dynamic>>.from(profiles);
              final deck = _deck!;

              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 64),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _reload,
                          child: const Icon(Icons.refresh, color: LuxuryColors.gold),
                        ),
                        const VelouraWordmark(size: 18),
                        SvgPicture.asset('assets/icons/king.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(LuxuryColors.gold, BlendMode.srcIn)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: deck.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l10n.noProfilesYet),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            )
                          : AppinioSwiper(
                              controller: swiperController,
                              backgroundCardCount: 2,
                              swipeOptions: const SwipeOptions.all(),
                              cardCount: deck.length,
                              onSwipeEnd: _onSwipeEnd,
                              onEnd: _reload,
                              cardBuilder: (context, index) {
                                final profile = deck[index];
                                return GestureDetector(
                                  onTap: () => context.push('/profile-details', extra: profile),
                                  child: ProfileCard(profile: profile),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 42),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HomeRoundButton(icon: Icons.close, onTap: () => swiperController.swipeLeft()),
                        const SizedBox(width: 26),
                        _HomeRoundButton(icon: Icons.favorite, onTap: () => swiperController.swipeRight(), filled: true),
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
          border: Border.all(color: LuxuryColors.gold.withOpacity(0.65), width: 3.0),
          boxShadow: [BoxShadow(color: LuxuryColors.gold.withOpacity(0.18), blurRadius: 0, spreadRadius: 1)],
        ),
        child: Icon(icon, color: filled ? Colors.white : LuxuryColors.gold, size: featured ? 30 : 35),
      ),
    );
  }
}
