import 'package:flutter/material.dart';

class LuxuryColors {
  static const black = Color(0xFF0F0F0F);
  static const black2 = Color(0xFF1C1C1C);
  static const card = Color(0xFF121212);
  static const gold = Color(0xFFD4AF37);
  static const gold2 = Color(0xFFB8862D);
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFFA6A6A6);
  static const online = Color(0xFF29D45A);
}

const luxuryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFD4AF37), Color(0xFF8A5F1D)],
);

class LuxuryScreen extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const LuxuryScreen({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.1,
          colors: [Color(0xFF1B1B1B), Color(0xFF070707)],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class LuxuryPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const LuxuryPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: LuxuryColors.card.withOpacity(0.88),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: LuxuryColors.gold.withOpacity(0.32)),
        boxShadow: [
          BoxShadow(
            // color: LuxuryColors.gold.withOpacity(0.12),
            blurRadius: 22,
          ),
        ],
      ),
      child: child,
    );
  }
}

class LuxuryGradientButton extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool loading;

  const LuxuryGradientButton({
    super.key,
    required this.title,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: luxuryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: LuxuryColors.gold.withOpacity(0.26),
            blurRadius: 18,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

InputDecoration luxuryInputDecoration(String hint, {IconData? suffixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF777777), fontSize: 14),
    suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, color: LuxuryColors.gold, size: 18),
    filled: true,
    fillColor: const Color(0xFF141414),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: LuxuryColors.gold.withOpacity(0.22)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: LuxuryColors.gold),
    ),
  );
}

class VelouraWordmark extends StatelessWidget {
  final double size;

  const VelouraWordmark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.workspace_premium, color: LuxuryColors.gold, size: size * 0.9),
        Text(
          'VELOURA',
          style: TextStyle(
            color: LuxuryColors.gold,
            fontSize: size,
            letterSpacing: 2.2,
            fontFamily: 'serif',
          ),
        ),
        Text(
          'PREMIUM DATING',
          style: TextStyle(
            color: LuxuryColors.gold.withOpacity(0.9),
            fontSize: size * 0.28,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
