import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/luxury_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/onboarding_prefs.dart';

/// Описание одного слайда онбординга.
/// Тексты (title/subtitle) теперь не хранятся здесь, а берутся из
/// локализаций по индексу слайда — см. _slideTexts ниже.
class _OnboardingSlide {
  final String image;
  final IconData icon;

  const _OnboardingSlide({
    required this.image,
    required this.icon,
  });
}

const _slides = <_OnboardingSlide>[
  _OnboardingSlide(
    image: 'assets/onboarding/girl_man.png',
    icon: Icons.workspace_premium_rounded,
  ),
  _OnboardingSlide(
    image: 'assets/onboarding/girl.png',
    icon: Icons.verified_user_rounded,
  ),
  _OnboardingSlide(
    image: 'assets/onboarding/man.png',
    icon: Icons.diamond_rounded,
  ),
];

/// Локализованные тексты слайдов по их индексу.
(String, String) _slideTexts(AppLocalizations l10n, int index) {
  switch (index) {
    case 0:
      return (l10n.onboard1Title, l10n.onboard1Body);
    case 1:
      return (l10n.onboard2Title, l10n.onboard2Body);
    default:
      return (l10n.onboard3Title, l10n.onboard3Body);
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingPrefs.markCompletedForCurrentUser();
    if (!mounted) return;
    // После онбординга — на заполнение профиля.
    context.go('/profile-setup');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: LuxuryColors.black,
      body: Stack(
        children: [
          // Слайды с фоновыми фото.
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) => _SlideView(
              slide: _slides[index],
              index: index,
            ),
          ),

          // Кнопка «Пропустить» сверху справа.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: AnimatedOpacity(
              opacity: _isLast ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: _isLast,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l10n.skip,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Нижний блок: точки-индикаторы и кнопка действия.
          Positioned(
            left: 24,
            right: 24,
            bottom: 24 + bottomInset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: active ? luxuryGradient : null,
                        color: active ? null : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                LuxuryGradientButton(
                  title: _isLast ? l10n.start : l10n.next,
                  onTap: _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  final int index;

  const _SlideView({required this.slide, required this.index});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, subtitle) = _slideTexts(l10n, index);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Фото на весь экран.
        Image.asset(
          slide.image,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),

        // Тёмный градиент для читаемости текста (плотнее снизу).
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x66000000),
                Color(0x110A0A0A),
                Color(0xCC0A0A0A),
                Color(0xF20A0A0A),
              ],
              stops: [0.0, 0.42, 0.74, 1.0],
            ),
          ),
        ),

        // Текстовый блок над нижней панелью.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              28,
              0,
              28,
              130 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Золотой бейдж с иконкой.
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: luxuryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: LuxuryColors.gold.withOpacity(0.9),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(slide.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LuxuryColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LuxuryColors.muted,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
