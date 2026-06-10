import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Обёртка, которая рисует анимированный градиентный бордер вокруг
/// любого поля ввода. Бордер «играет» (крутится градиент), пока поле
/// в фокусе, и становится спокойным золотым, когда фокус снят.
///
/// Передаёт во вложенный виджет [FocusNode], чтобы обёртка знала,
/// сфокусировано ли поле. Подходит и для [TextField], и для
/// [DropdownButtonFormField].
///
/// Пример:
/// ```dart
/// GlowField(
///   builder: (focusNode) => TextField(focusNode: focusNode, ...),
/// )
/// ```
class GlowField extends StatefulWidget {
  final Widget Function(FocusNode focusNode) builder;
  final double radius;
  final double strokeWidth;
  final Duration duration;

  /// Цвета бегущего градиента. По кругу, поэтому последний цвет
  /// лучше делать равным первому для бесшовного стыка.
  final List<Color> colors;

  /// Цвет статичного бордера, когда поле не в фокусе.
  final Color idleColor;

  /// Если true, бордер становится красным (статичным) независимо от фокуса.
  final bool hasError;

  /// Цвет бордера в состоянии ошибки.
  final Color errorColor;

  const GlowField({
    super.key,
    required this.builder,
    this.radius = 10,
    this.strokeWidth = 1.6,
    this.duration = const Duration(seconds: 3),
    this.colors = const [
      Color(0xFFD4AF37),
      Color(0xFFFF4F7B),
      Color(0xFFD4AF37),
      Color(0xFFFF4F7B),
      Color(0xFFD4AF37),
    ],
    this.idleColor = const Color(0x38D4AF37), // gold с прозрачностью ~0.22
    this.hasError = false,
    this.errorColor = const Color(0xFFFF5252),
  });

  @override
  State<GlowField> createState() => _GlowFieldState();
}

class _GlowFieldState extends State<GlowField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _anim;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    _anim = AnimationController(vsync: this, duration: widget.duration);
  }

  void _onFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused == _focused) return;
    setState(() => _focused = focused);
    if (focused) {
      _anim.repeat();
    } else {
      _anim.stop();
      _anim.reset();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _GradientBorderPainter(
            radius: widget.radius,
            strokeWidth: widget.strokeWidth,
            progress: _anim.value,
            // При ошибке гасим анимацию и рисуем статичный красный бордер.
            active: _focused && !widget.hasError,
            colors: widget.colors,
            idleColor: widget.hasError ? widget.errorColor : widget.idleColor,
          ),
          child: child,
        );
      },
      child: widget.builder(_focusNode),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final double progress; // 0..1
  final bool active;
  final List<Color> colors;
  final Color idleColor;

  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.progress,
    required this.active,
    required this.colors,
    required this.idleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    // Поле не в фокусе: спокойный статичный бордер.
    if (!active) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = idleColor;
      canvas.drawRRect(rrect, paint);
      return;
    }

    final shader = SweepGradient(
      transform: GradientRotation(2 * math.pi * progress),
      colors: colors,
    ).createShader(rect);

    // Мягкое свечение под основным бордером.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2.5
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, glow);

    // Основной бордер.
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = shader;
    canvas.drawRRect(rrect, border);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) =>
      old.progress != progress ||
      old.active != active ||
      old.idleColor != idleColor;
}

/// Прозрачный бордер для встроенной декорации поля: визуальную рамку
/// рисует [GlowField], а собственные бордеры поля нужно спрятать.
InputBorder transparentInputBorder([double radius = 10]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: const BorderSide(color: Colors.transparent),
  );
}