import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../home/presentation/providers/home_provider.dart';
import 'providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> signUp() async {
    try {
      setState(() => isLoading = true);
      await ref.read(authRepositoryProvider).signUp(email: emailController.text.trim(), password: passwordController.text.trim());
      await ref.read(authRepositoryProvider).setOnlineStatus(true);
      await FcmService().init();
      ref.invalidate(profilesProvider);
      if (mounted) context.go('/profile-setup');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
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
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VelouraWordmark(size: 29),
                    const SizedBox(height: 24),
                    const Text('Создайте аккаунт', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Начните своё путешествие', style: TextStyle(color: LuxuryColors.muted, fontSize: 13)),
                    const SizedBox(height: 22),
                    _AuthTextField(controller: nameController, hintText: 'Имя'),
                    const SizedBox(height: 12),
                    _AuthTextField(controller: emailController, hintText: 'Email'),
                    const SizedBox(height: 12),
                    _AuthTextField(controller: passwordController, hintText: 'Пароль', obscureText: true, suffixIcon: Icons.visibility_outlined),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(width: 17, height: 17, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white24))),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Я принимаю условия использования и политику конфиденциальности', style: TextStyle(color: LuxuryColors.muted, fontSize: 11))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LuxuryGradientButton(title: 'Зарегистрироваться', onTap: signUp, loading: isLoading),
                    const SizedBox(height: 18),
                    const Row(children: [Expanded(child: Divider(color: Colors.white12)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('или', style: TextStyle(color: LuxuryColors.muted))), Expanded(child: Divider(color: Colors.white12))]),
                    const SizedBox(height: 14),
                    Row(children: const [Expanded(child: _SocialButton(icon: Icons.apple)), SizedBox(width: 12), Expanded(child: _SocialButton(text: 'G'))]),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => context.go('/sign-in'),
                      child: const Text.rich(TextSpan(text: 'Уже есть аккаунт? ', style: TextStyle(color: LuxuryColors.muted, fontSize: 13), children: [TextSpan(text: 'Войти', style: TextStyle(color: LuxuryColors.gold, fontWeight: FontWeight.w700))])),
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
    return TextField(controller: controller, obscureText: obscureText, style: const TextStyle(color: Colors.white), decoration: luxuryInputDecoration(hintText, suffixIcon: suffixIcon));
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? text;

  const _SocialButton({this.icon, this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: LuxuryColors.gold.withOpacity(0.32))),
      child: Center(child: icon != null ? Icon(icon, color: Colors.white) : Text(text!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
    );
  }
}
