import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/fcm_service.dart';
import 'providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() =>
      _SignUpScreenState();
}

class _SignUpScreenState
    extends ConsumerState<SignUpScreen> {
  final emailController = TextEditingController();

  final passwordController =
      TextEditingController();

  bool isLoading = false;

  Future<void> signUp() async {
    try {
      setState(() {
        isLoading = true;
      });

      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: emailController.text.trim(),
            password:
                passwordController.text.trim(),
          );

      await ref
          .read(authRepositoryProvider)
          .setOnlineStatus(true);

      await FcmService().init();

      if (mounted) {
        context.go('/profile-setup');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Пароль',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    isLoading ? null : signUp,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Создать аккаунт',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}