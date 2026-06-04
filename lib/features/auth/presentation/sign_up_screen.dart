import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  bool isGoogleLoading = false;

  Future<void> signUp() async {
    try {
      setState(() => isLoading = true);
      await ref.read(authRepositoryProvider).signUp(email: emailController.text.trim(), password: passwordController.text.trim());
      await ref.read(authRepositoryProvider).setOnlineStatus(true);
      await FcmService().init();
      ref.invalidate(profilesProvider);
      if (mounted) context.go('/onboarding');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signUpWithGoogle() async {
    try {
      setState(() => isGoogleLoading = true);
      final isNewUser = await ref.read(authRepositoryProvider).signInWithGoogle();
      await ref.read(authRepositoryProvider).setOnlineStatus(true);
      await FcmService().init();
      ref.invalidate(profilesProvider);
      if (!mounted) return;
      context.go(isNewUser ? '/onboarding' : '/home');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
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
                    // Row(
                    //   children: [
                    //     Container(width: 17, height: 17, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white24))),
                    //     const SizedBox(width: 8),
                    //     const Expanded(child: Text('Я принимаю условия использования и политику конфиденциальности', style: TextStyle(color: LuxuryColors.muted, fontSize: 11))),
                    //   ],
                    // ),
                    const SizedBox(height: 16),
                    LuxuryGradientButton(title: 'Зарегистрироваться', onTap: signUp, loading: isLoading),
                    const SizedBox(height: 18),
                    const Row(children: [Expanded(child: Divider(color: Colors.white12)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('или', style: TextStyle(color: LuxuryColors.muted))), Expanded(child: Divider(color: Colors.white12))]),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // const Expanded(
                        //   child: _SocialButton(icon: Icons.apple),
                        // ),
                        // const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            imagePath: 'assets/icons/google.png',
                            loading: isGoogleLoading,
                            onTap: isGoogleLoading ? null : signUpWithGoogle,
                          ),
                        ),
                      ],
                    ),
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

class _AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData? suffixIcon;

  const _AuthTextField({required this.controller, required this.hintText, this.obscureText = false, this.suffixIcon});

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final decoration = widget.obscureText
        ? luxuryInputDecoration(widget.hintText).copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: LuxuryColors.gold,
                size: 18,
              ),
            ),
          )
        : luxuryInputDecoration(widget.hintText, suffixIcon: widget.suffixIcon);

    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: decoration,
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final String? imagePath;
  final VoidCallback? onTap;
  final bool loading;

  const _SocialButton({this.icon, this.text, this.imagePath, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: LuxuryColors.gold.withOpacity(0.32))),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: LuxuryColors.gold),
                )
              : (icon != null
                  ? Icon(icon, color: Colors.white)
                  : imagePath != null
                      ? Image.asset(imagePath!, width: 20, height: 20)
                      : Text(text!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}