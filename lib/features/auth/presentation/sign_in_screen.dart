import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../home/presentation/providers/home_provider.dart';
import 'providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> signIn() async {
    try {
      setState(() => isLoading = true);
      await ref.read(authRepositoryProvider).signIn(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      await ref.read(authRepositoryProvider).setOnlineStatus(true);
      await FcmService().init();
      ref.invalidate(profilesProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuxuryScreen(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: LuxuryPanel(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VelouraWordmark(size: 31),
                    const SizedBox(height: 28),
                    const Text('С возвращением!', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Мы рады видеть вас снова', style: TextStyle(color: LuxuryColors.muted, fontSize: 13)),
                    const SizedBox(height: 26),
                    _AuthTextField(controller: emailController, hintText: 'Email или телефон'),
                    const SizedBox(height: 12),
                    _AuthTextField(controller: passwordController, hintText: 'Пароль', obscureText: true, suffixIcon: Icons.visibility_outlined),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 16),
                        child: Text('Забыли пароль?', style: TextStyle(color: LuxuryColors.gold, fontSize: 12)),
                      ),
                    ),
                    LuxuryGradientButton(title: 'Войти', onTap: signIn, loading: isLoading),
                    const SizedBox(height: 22),
                    const Row(children: [Expanded(child: Divider(color: Colors.white12)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('или', style: TextStyle(color: LuxuryColors.muted))), Expanded(child: Divider(color: Colors.white12))]),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(child: _SocialButton(icon: Icons.apple)),
                        SizedBox(width: 12),
                        Expanded(child: _SocialButton(text: 'G')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => context.go('/sign-up'),
                      child: const Text.rich(
                        TextSpan(
                          text: 'Нет аккаунта? ',
                          style: TextStyle(color: LuxuryColors.muted, fontSize: 13),
                          children: [TextSpan(text: 'Зарегистрироваться', style: TextStyle(color: LuxuryColors.gold, fontWeight: FontWeight.w700))],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData? suffixIcon;

  const _AuthTextField({required this.controller, required this.hintText, this.obscureText = false, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: luxuryInputDecoration(hintText, suffixIcon: suffixIcon),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? text;

  const _SocialButton({this.icon, this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: LuxuryColors.gold.withOpacity(0.32))),
      child: Center(child: icon != null ? Icon(icon, color: Colors.white) : Text(text!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
    );
  }
}
