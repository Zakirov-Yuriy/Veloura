import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/luxury_theme.dart';
import '../../../core/utils/auth_validation.dart';
import '../../../core/widgets/glow_field.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/auth_provider.dart';

/// Экран восстановления пароля.
/// Пользователь вводит email, мы просим Firebase отправить письмо
/// со ссылкой для сброса. Новый пароль задаётся по ссылке из письма.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;
  bool emailSent = false;
  String? emailError;

  Future<void> sendResetEmail() async {
    final l10n = AppLocalizations.of(context);
    final err = validateEmail(emailController.text, l10n);
    if (err != null) {
      setState(() => emailError = err);
      return;
    }

    try {
      setState(() => isLoading = true);
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(emailController.text.trim());
      if (mounted) setState(() => emailSent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Не раскрываем, существует ли аккаунт: при user-not-found
      // показываем тот же экран успеха, что и при реальной отправке.
      if (e.code == 'user-not-found') {
        setState(() => emailSent = true);
      } else {
        setState(() => emailError = mapAuthError(e, l10n));
      }
    } catch (e) {
      if (mounted) setState(() => emailError = mapAuthError(e, l10n));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
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
                child: emailSent ? _buildSuccess() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VelouraWordmark(size: 31),
        const SizedBox(height: 28),
        Text(
          l10n.forgotPassword,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.resetSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: LuxuryColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 26),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlowField(
              hasError: emailError != null,
              builder: (focusNode) => TextField(
                controller: emailController,
                focusNode: focusNode,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (emailError != null) {
                    setState(() => emailError = null);
                  }
                },
                style: const TextStyle(color: Colors.white),
                decoration: luxuryInputDecoration('Email').copyWith(
                  enabledBorder: transparentInputBorder(),
                  focusedBorder: transparentInputBorder(),
                ),
              ),
            ),
            if (emailError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  emailError!,
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 11.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        LuxuryGradientButton(
          title: l10n.sendLink,
          onTap: sendResetEmail,
          loading: isLoading,
        ),
        const SizedBox(height: 22),
        GestureDetector(
          onTap: () => context.go('/sign-in'),
          child: Text.rich(
            TextSpan(
              text: l10n.rememberedPassword,
              style: const TextStyle(color: LuxuryColors.muted, fontSize: 13),
              children: [
                TextSpan(
                  text: l10n.signIn,
                  style: const TextStyle(
                    color: LuxuryColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VelouraWordmark(size: 31),
        const SizedBox(height: 28),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: LuxuryColors.gold.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: LuxuryColors.gold,
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.checkEmailTitle,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.checkEmailBody(emailController.text.trim()),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LuxuryColors.muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 26),
        LuxuryGradientButton(
          title: l10n.backToSignIn,
          onTap: () => context.go('/sign-in'),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => setState(() => emailSent = false),
          child: Text(
            l10n.sendAgain,
            style: const TextStyle(color: LuxuryColors.gold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
