import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/utils/auth_validation.dart';
import '../../../core/widgets/glow_field.dart';
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
  bool isGoogleLoading = false;

  String? emailError;
  String? passwordError;

  /// Клиентская проверка перед запросом к Firebase.
  bool validateForm() {
    final eErr = validateEmail(emailController.text);
    final pErr = validatePassword(passwordController.text);
    setState(() {
      emailError = eErr;
      passwordError = pErr;
    });
    return eErr == null && pErr == null;
  }

  Future<void> signIn() async {
    if (!validateForm()) return;
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
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = mapAuthError(e);
      setState(() {
        // Ошибку показываем под тем полем, к которому она относится.
        if (emailErrorCodes.contains(e.code)) {
          emailError = message;
        } else if (passwordErrorCodes.contains(e.code)) {
          passwordError = message;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e))));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() => isGoogleLoading = true);
      final isNewUser = await ref.read(authRepositoryProvider).signInWithGoogle();
      await ref.read(authRepositoryProvider).setOnlineStatus(true);
      await FcmService().init();
      ref.invalidate(profilesProvider);
      if (!mounted) return;
      // Новый пользователь идёт через онбординг, существующий — на главный.
      context.go(isNewUser ? '/onboarding' : '/home');
    } on GoogleSignInException catch (e) {
      // Пользователь закрыл окно выбора аккаунта — это не ошибка.
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e))));
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
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
                    _AuthTextField(
                      controller: emailController,
                      hintText: 'Email или телефон',
                      errorText: emailError,
                      onChanged: (_) {
                        if (emailError != null) setState(() => emailError = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    _AuthTextField(
                      controller: passwordController,
                      hintText: 'Пароль',
                      obscureText: true,
                      suffixIcon: Icons.visibility_outlined,
                      errorText: passwordError,
                      onChanged: (_) {
                        if (passwordError != null) setState(() => passwordError = null);
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 10, bottom: 16),
                          child: Text('Забыли пароль?', style: TextStyle(color: LuxuryColors.gold, fontSize: 12)),
                        ),
                      ),
                    ),
                    LuxuryGradientButton(title: 'Войти', onTap: signIn, loading: isLoading),
                    const SizedBox(height: 22),
                    const Row(children: [Expanded(child: Divider(color: Colors.white12)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('или', style: TextStyle(color: LuxuryColors.muted))), Expanded(child: Divider(color: Colors.white12))]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            imagePath: 'assets/icons/google.png',
                            loading: isGoogleLoading,
                            onTap: isGoogleLoading ? null : signInWithGoogle,
                          ),
                        ),
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

class _AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData? suffixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
  });

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  late bool _obscure = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final base = widget.obscureText
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

    final decoration = base.copyWith(
      enabledBorder: transparentInputBorder(),
      focusedBorder: transparentInputBorder(),
    );

    final hasError = widget.errorText != null;

    // Текст ошибки рисуем ВНЕ GlowField, иначе градиентная рамка
    // обернёт и поле, и подпись с ошибкой вместе.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlowField(
          hasError: hasError,
          builder: (focusNode) => TextField(
            controller: widget.controller,
            focusNode: focusNode,
            obscureText: _obscure,
            onChanged: widget.onChanged,
            style: const TextStyle(color: Colors.white),
            decoration: decoration,
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Color(0xFFFF5252), fontSize: 11.5),
            ),
          ),
      ],
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