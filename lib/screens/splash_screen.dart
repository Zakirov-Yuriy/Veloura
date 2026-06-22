import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

// ============================================================
//  VELO — анимированный сплеш-экран
//
//  Сценарий:
//    1. 20 осколков сердца слетаются с двух сторон (0–1.3с)
//    2. Пульс; трещины «затягиваются» — половинки становятся
//       цельными (1.3–1.9с)
//    3. Сверху опускается корона (1.6–2.1с)
//    4. По буквам появляется LOVE (1.9–2.8с)
//    5. Буквы разлетаются каждая своим манером и пересобираются
//       в VELO, вспыхивая золотом (2.85–4.1с)
//    6. Слоган (4.2с)
//
//  Ассеты (pubspec: assets: - assets/splash/):
//    assets/splash/shard_L0.png ... shard_L9.png
//    assets/splash/shard_R0.png ... shard_R9.png
//    assets/splash/velo_heart_left.png
//    assets/splash/velo_heart_right.png
//    assets/splash/velo_crown.png
//
//  Шрифт Cinzel должен быть подключён в pubspec (family: Cinzel).
// ============================================================

const Color _kBg = Color(0xFF0F0F0F);
const Color _kGold = Color(0xFFD4AF37);
const Color _kGoldLight = Color(0xFFF2DC85);
const Color _kWhite = Color(0xFFF5F2FA);
const Color _kTextMuted = Color(0xFFA6A6A6);

class VeloSplashScreen extends StatefulWidget {
  const VeloSplashScreen({
    super.key,
    required this.nextScreen,
    this.holdDuration = const Duration(milliseconds: 5400),
  });

  final Widget nextScreen;
  final Duration holdDuration;

  @override
  State<VeloSplashScreen> createState() => _VeloSplashScreenState();
}

// ---------------------------------------------------------------------------
// Описание осколка: позиция на канве (доли от 1024) и параметры полёта
// ---------------------------------------------------------------------------
class _Shard {
  final String asset;
  final double x, y, w, h; // позиция/размер, доли канвы
  final double dx, dy; // стартовое смещение, доли контейнера
  final double rotDeg; // стартовый поворот
  final double delay, dur; // тайминг внутри фазы осколков, сек

  const _Shard(this.asset, this.x, this.y, this.w, this.h, this.dx, this.dy,
      this.rotDeg, this.delay, this.dur);
}

const List<_Shard> _shards = [
  _Shard('shard_L0', 0.3301, 0.3438, 0.1533, 0.1592, -1.076, -0.480, 48, 0.02, 0.88),
  _Shard('shard_L1', 0.4297, 0.7568, 0.0732, 0.0693, -1.110, -0.608, 2, 0.01, 0.86),
  _Shard('shard_L2', 0.2617, 0.5693, 0.1279, 0.1396, -0.869, -0.563, -24, 0.25, 0.78),
  _Shard('shard_L3', 0.3955, 0.5439, 0.1201, 0.1230, -0.994, 0.175, 143, 0.17, 0.85),
  _Shard('shard_L4', 0.2461, 0.4277, 0.0869, 0.1494, -1.606, -0.623, 115, 0.09, 0.79),
  _Shard('shard_L5', 0.3486, 0.6309, 0.1260, 0.1533, -0.908, -0.263, 101, 0.05, 0.90),
  _Shard('shard_L6', 0.2822, 0.4668, 0.1553, 0.1660, -1.332, -0.175, 15, 0.02, 0.76),
  _Shard('shard_L7', 0.2627, 0.3438, 0.1250, 0.1162, -0.980, 0.248, -23, 0.09, 0.90),
  _Shard('shard_L8', 0.4229, 0.4600, 0.1074, 0.0947, -1.181, -0.275, 94, 0.21, 0.81),
  _Shard('shard_L9', 0.4639, 0.6611, 0.0566, 0.1035, -1.279, 0.035, 120, 0.22, 0.82),
  _Shard('shard_R0', 0.5156, 0.3438, 0.1260, 0.0967, 1.609, -0.525, -26, 0.23, 0.79),
  _Shard('shard_R1', 0.4971, 0.7568, 0.0664, 0.0801, 1.210, -0.634, 54, 0.23, 0.89),
  _Shard('shard_R2', 0.6475, 0.5342, 0.1016, 0.1572, 1.524, -0.256, 62, 0.18, 0.89),
  _Shard('shard_R3', 0.4697, 0.5459, 0.0732, 0.1396, 1.183, 0.467, 142, 0.14, 0.92),
  _Shard('shard_R4', 0.6621, 0.4053, 0.0918, 0.1367, 0.862, 0.277, 47, 0.30, 0.96),
  _Shard('shard_R5', 0.4727, 0.3848, 0.0908, 0.1348, 1.044, -0.157, 54, 0.01, 0.87),
  _Shard('shard_R6', 0.5186, 0.6650, 0.1484, 0.1250, 0.949, -0.526, -141, 0.23, 0.78),
  _Shard('shard_R7', 0.5293, 0.4326, 0.1748, 0.1465, 1.014, -0.150, 119, 0.02, 0.86),
  _Shard('shard_R8', 0.5352, 0.5537, 0.1201, 0.1162, 1.259, 0.527, 102, 0.26, 0.82),
  _Shard('shard_R9', 0.6289, 0.3486, 0.0947, 0.1016, 1.150, -0.194, 123, 0.29, 0.79),
];

class _VeloSplashScreenState extends State<VeloSplashScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalMs = 4700;

  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    )..forward();
    Future.delayed(widget.holdDuration, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Локальный прогресс 0..1 внутри отрезка [startMs, endMs] с кривой
  double _seg(double t, int startMs, int endMs, [Curve curve = Curves.linear]) {
    final p = ((t * _totalMs - startMs) / (endMs - startMs)).clamp(0.0, 1.0);
    return curve.transform(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeart(t),
                const SizedBox(height: 16),
                _buildWord(t),
                const SizedBox(height: 12),
                Opacity(
                  opacity: _seg(t, 4200, 4650, Curves.easeOut),
                  child: Transform.translate(
                    offset: Offset(
                        0, 18 * (1 - _seg(t, 4200, 4700, Curves.easeOut))),
                    child: Text(
                      AppLocalizations.of(context).splashTagline,
                      style: const TextStyle(
                        color: _kTextMuted,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Сердце: осколки -> заживление -> пульс + корона
  // -------------------------------------------------------------------------
  Widget _buildHeart(double t) {
    const double size = 240;

    // Пульс при сборке (1380..1740), пик в середине
    final pulseP = _seg(t, 1380, 1740);
    final pulse = 1 + 0.07 * math.sin(math.pi * pulseP);

    final healOpacity = _seg(t, 1300, 1750, Curves.easeIn);
    final shardsOpacity = 1 - _seg(t, 1650, 1950, Curves.easeOut);

    // Корона: опускается с отскоком (1600..2100)
    final crownDrop = _seg(t, 1600, 2100, Curves.easeOutBack);
    final crownFade = _seg(t, 1600, 1950, Curves.easeOut);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // Слой сердца с пульсом вокруг центра сердца (чуть ниже середины)
          Transform.scale(
            scale: pulse,
            alignment: const Alignment(0, 0.17),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // Осколки
                if (shardsOpacity > 0)
                  Opacity(
                    opacity: shardsOpacity,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        for (final s in _shards) _buildShard(s, t, size),
                      ],
                    ),
                  ),
                // Цельные половинки («заживление»)
                Opacity(
                  opacity: healOpacity,
                  child: const Image(
                    image: AssetImage('assets/splash/velo_heart_left.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                Opacity(
                  opacity: healOpacity,
                  child: const Image(
                    image: AssetImage('assets/splash/velo_heart_right.png'),
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            ),
          ),
          // Корона
          Transform.translate(
            offset: Offset(0, -52 * (1 - crownDrop)),
            child: Opacity(
              opacity: crownFade.clamp(0.0, 1.0),
              child: const Image(
                image: AssetImage('assets/splash/velo_crown.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShard(_Shard s, double t, double size) {
    // Фаза осколков: 0..1300мс; у каждого свой delay/dur (в долях секунды)
    final start = (s.delay * 1000).round();
    final end = (start + s.dur * 1000).round();
    final p = _seg(t, start, end, Curves.easeOutCubic);

    final dx = s.dx * size * (1 - p);
    final dy = s.dy * size * (1 - p);
    final rot = s.rotDeg * math.pi / 180 * (1 - p);
    final scale = 0.6 + 0.4 * p;
    final opacity = (p / 0.25).clamp(0.0, 1.0);

    return Positioned(
      left: s.x * size,
      top: s.y * size,
      width: s.w * size,
      height: s.h * size,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Image(
                image: AssetImage('assets/splash/${s.asset}.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // LOVE -> VELO: у каждой буквы своя хореография
  // -------------------------------------------------------------------------
  static const double _adv = 52; // шаг буквы
  static const double _jump = _adv * 2; // дистанция перелёта (2 позиции)

  Widget _buildWord(double t) {
    return SizedBox(
      width: _adv * 4,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildLetter(t, 'L', 0,
              inStart: 1900, flyStart: 3050, flyEnd: 3850, fly: _flyL),
          _buildLetter(t, 'O', 1,
              inStart: 2020, flyStart: 3150, flyEnd: 4100, fly: _flyO),
          _buildLetter(t, 'V', 2,
              inStart: 2140, flyStart: 2850, flyEnd: 3700, fly: _flyV),
          _buildLetter(t, 'E', 3,
              inStart: 2260, flyStart: 2950, flyEnd: 3750, fly: _flyE),
        ],
      ),
    );
  }

  /// Трансформации букв в полёте: p=0 старт, p=1 на новом месте.

  Matrix4 _flyL(double p) {
    // Скользит вправо с проворотом, лёгкий перелёт-откат у места посадки
    final tx = _jump * Curves.easeInOutCubic.transform(p) +
        8 * math.sin(math.pi * _ramp(p, 0.55, 1.0));
    final ty = -26 * math.sin(math.pi * p);
    final rot = 2 * math.pi * Curves.easeInOut.transform(p);
    final scale = 1 + 0.15 * math.sin(math.pi * p);
    return Matrix4.identity()
      ..translate(tx, ty)
      ..rotateZ(rot)
      ..scale(scale);
  }

  Matrix4 _flyO(double p) {
    // Катится как колесо: два полных оборота, мелкие подскоки
    final tx = _jump * Curves.easeInOutCubic.transform(p);
    final ty = -6 * math.sin(2 * math.pi * p).abs();
    final rot = 4 * math.pi * p;
    return Matrix4.identity()
      ..translate(tx, ty)
      ..rotateZ(rot);
  }

  Matrix4 _flyV(double p) {
    // Высокая дуга с сальто назад и отскоком при посадке
    final tx = -_jump * Curves.easeInOutCubic.transform(p);
    final arc = -58.0 * math.sin(math.pi * (p / 0.85).clamp(0.0, 1.0));
    final bounce =
        p > 0.78 ? -8.0 * math.sin(math.pi * (p - 0.78) / 0.22) : 0.0;
    final rot = -2 * math.pi * Curves.easeOut.transform(p);
    final scale = 1 + 0.35 * math.sin(math.pi * (p / 0.9).clamp(0.0, 1.0));
    return Matrix4.identity()
      ..translate(tx, arc + bounce)
      ..rotateZ(rot)
      ..scale(scale);
  }

  Matrix4 _flyE(double p) {
    // Ныряет под строку с 3D-кувырком
    final tx = -_jump * Curves.easeInOutCubic.transform(p);
    final ty = 34 * math.sin(math.pi * p);
    final rotX = 2 * math.pi * p;
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0015) // перспектива
      ..translate(tx, ty)
      ..rotateX(rotX);
  }

  double _ramp(double p, double from, double to) =>
      ((p - from) / (to - from)).clamp(0.0, 1.0);

  Widget _buildLetter(
    double t,
    String char,
    int slot, {
    required int inStart,
    required int flyStart,
    required int flyEnd,
    required Matrix4 Function(double) fly,
  }) {
    // Появление буквы
    final inP = _seg(t, inStart, inStart + 500, Curves.easeOut);
    // Полёт на новое место
    final flyP = _seg(t, flyStart, flyEnd);

    final transform = flyP > 0
        ? fly(flyP)
        : (Matrix4.identity()..translate(0.0, 16 * (1 - inP)));

    // Цвет: белый -> золото в полёте; вспышка ближе к посадке
    final color = Color.lerp(_kWhite, _kGold, flyP)!;
    final glow = math.sin(math.pi * _ramp(flyP, 0.6, 1.0));

    return Positioned(
      left: slot * _adv,
      top: 4,
      width: _adv,
      child: Transform(
        transform: transform,
        alignment: Alignment.center,
        child: Opacity(
          opacity: inP,
          child: Text(
            char,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: color,
              shadows: glow > 0.01
                  ? [
                      Shadow(
                        color: _kGoldLight.withOpacity(0.9 * glow),
                        blurRadius: 18 * glow,
                      ),
                      Shadow(
                        color: _kGold.withOpacity(0.6 * glow),
                        blurRadius: 36 * glow,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}