import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/utils/auth_validation.dart';
import '../../../core/widgets/glow_field.dart';
import '../../../l10n/app_localizations.dart';
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

  String? nameError;
  String? emailError;
  String? passwordError;

  /// Клиентская проверка перед запросом к Firebase.
  bool validateForm() {
    final l10n = AppLocalizations.of(context);
    final nErr = validateName(nameController.text, l10n);
    final eErr = validateEmail(emailController.text, l10n);
    final pErr = validatePassword(passwordController.text, l10n);
    setState(() {
      nameError = nErr;
      emailError = eErr;
      passwordError = pErr;
    });
    return nErr == null && eErr == null && pErr == null;
  }

  Future<void> signUp() async {
    final l10n = AppLocalizations.of(context);
    if (!validateForm()) return;
    try {
      setState(() => isLoading = true);
      await ref.read(authRepositoryProvider).signUp(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            name: nameController.text.trim(),
          );
      await ref.read(authRepositoryProvider).setOnlineStatus(true);
      await FcmService().init();
      ref.invalidate(profilesProvider);
      if (mounted) context.go('/onboarding');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = mapAuthError(e, l10n);
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e, l10n))));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signUpWithGoogle() async {
    final l10n = AppLocalizations.of(context);
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e, l10n))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e, l10n))));
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
    final l10n = AppLocalizations.of(context);
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
                    Text(l10n.createAccount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(l10n.startYourJourney, style: const TextStyle(color: LuxuryColors.muted, fontSize: 13)),
                    const SizedBox(height: 22),
                    _AuthTextField(
                      controller: nameController,
                      hintText: l10n.name,
                      errorText: nameError,
                      onChanged: (_) {
                        if (nameError != null) setState(() => nameError = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    _AuthTextField(
                      controller: emailController,
                      hintText: 'Email',
                      errorText: emailError,
                      onChanged: (_) {
                        if (emailError != null) setState(() => emailError = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    _AuthTextField(
                      controller: passwordController,
                      hintText: l10n.password,
                      obscureText: true,
                      suffixIcon: Icons.visibility_outlined,
                      errorText: passwordError,
                      onChanged: (_) {
                        if (passwordError != null) setState(() => passwordError = null);
                      },
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 16),
                    LuxuryGradientButton(title: l10n.signUp, onTap: signUp, loading: isLoading),
                    const SizedBox(height: 18),
                    Row(children: [const Expanded(child: Divider(color: Colors.white12)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(l10n.or, style: const TextStyle(color: LuxuryColors.muted))), const Expanded(child: Divider(color: Colors.white12))]),
                    const SizedBox(height: 14),
                    Row(
                      children: [
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
                      child: Text.rich(TextSpan(text: l10n.haveAccount, style: const TextStyle(color: LuxuryColors.muted, fontSize: 13), children: [TextSpan(text: l10n.signIn, style: const TextStyle(color: LuxuryColors.gold, fontWeight: FontWeight.w700))])),
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
