import 'package:flutter/material.dart';

// ============================================================
//  VELOURA — брендовый анимированный сплеш-экран
//  Тёмная тема: коралл + фиолетовый (под логотип «разбитое сердце»)
//
//  Использование в main.dart:
//    MaterialApp(
//      home: VelouraSplashScreen(nextScreen: HomeScreen()),
//    )
//  где HomeScreen() — твой главный экран (свайпы / Анкеты).
// ============================================================

// --- Палитра (вынеси потом в общий файл темы) ---
const Color kBg = Color(0xFF15131F); // фон
const Color kCoral = Color(0xFFFB4E6D); // основной акцент, левая половина сердца
const Color kPurple = Color(0xFF5B4B9E); // второй цвет, правая половина сердца
const Color kTextMain = Color(0xFFF5F2FA); // основной текст
const Color kTextMuted = Color(0xFF9A93B0); // приглушённый текст

class VelouraSplashScreen extends StatefulWidget {
  const VelouraSplashScreen({
    super.key,
    required this.nextScreen,
    this.holdDuration = const Duration(milliseconds: 2200),
  });

  /// Экран, на который перейдём после сплеша.
  final Widget nextScreen;

  /// Сколько держать сплеш на экране (вместе с анимацией).
  final Duration holdDuration;

  @override
  State<VelouraSplashScreen> createState() => _VelouraSplashScreenState();
}

class _VelouraSplashScreenState extends State<VelouraSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _wordFade;
  late final Animation<Offset> _wordSlide;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Логотип: проявление + лёгкий «выскок» (scale)
    _logoFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    // Текст: проявление чуть позже + подъезд снизу
    _wordFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
    );
    _wordSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.40, 0.85, curve: Curves.easeOut),
      ),
    );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: const SizedBox(
                  width: 104,
                  height: 104,
                  child: Image(image: AssetImage('assets/splash_logo.png')),
                ),
              ),
            ),
            const SizedBox(height: 26),
            SlideTransition(
              position: _wordSlide,
              child: FadeTransition(
                opacity: _wordFade,
                child: Column(
                  children: const [
                    Text(
                      'VELOURA',
                      style: TextStyle(
                        color: kTextMain,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 7,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Подзаголовок опциональный, можно удалить
                    Text(
                      'найди свою половину',
                      style: TextStyle(
                        color: kTextMuted,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Логотип: разбитое сердце из двух половин ---
class _BrokenHeartPainter extends CustomPainter {
  const _BrokenHeartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Контур сердца
    final Path heart = Path()
      ..moveTo(w * 0.50, h * 0.30)
      ..cubicTo(w * 0.43, h * 0.10, w * 0.06, h * 0.12, w * 0.06, h * 0.40)
      ..cubicTo(w * 0.06, h * 0.60, w * 0.28, h * 0.76, w * 0.50, h * 0.94)
      ..cubicTo(w * 0.72, h * 0.76, w * 0.94, h * 0.60, w * 0.94, h * 0.40)
      ..cubicTo(w * 0.94, h * 0.12, w * 0.57, h * 0.10, w * 0.50, h * 0.30)
      ..close();

    // Линия «трещины» по центру (зигзаг)
    final List<Offset> crack = [
      Offset(w * 0.50, h * 0.16),
      Offset(w * 0.44, h * 0.34),
      Offset(w * 0.54, h * 0.48),
      Offset(w * 0.45, h * 0.62),
      Offset(w * 0.53, h * 0.78),
      Offset(w * 0.48, h * 0.98),
    ];

    Path sideRegion(double edgeX) {
      final Path p = Path()..moveTo(edgeX, 0)..lineTo(crack.first.dx, 0);
      for (final Offset pt in crack) {
        p.lineTo(pt.dx, pt.dy);
      }
      p.lineTo(edgeX, h);
      p.close();
      return p;
    }

    final Path leftHalf =
        Path.combine(PathOperation.intersect, heart, sideRegion(0));
    final Path rightHalf =
        Path.combine(PathOperation.intersect, heart, sideRegion(w));

    canvas.drawPath(leftHalf, Paint()..color = kCoral..isAntiAlias = true);
    canvas.drawPath(rightHalf, Paint()..color = kPurple..isAntiAlias = true);

    // Тонкий зазор между половинами под цвет фона
    final Path crackPath = Path()..moveTo(crack.first.dx, crack.first.dy);
    for (final Offset pt in crack.skip(1)) {
      crackPath.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = kBg
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
