import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/fcm_service.dart';
import '../../home/presentation/providers/home_provider.dart';
import 'providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() =>
      _SignInScreenState();
}

class _SignInScreenState
    extends ConsumerState<SignInScreen> {
  final emailController = TextEditingController();

  final passwordController =
      TextEditingController();

  bool isLoading = false;

  Future<void> signIn() async {
    try {
      setState(() {
        isLoading = true;
      });

      await ref
          .read(authRepositoryProvider)
          .signIn(
            email: emailController.text.trim(),
            password:
                passwordController.text.trim(),
          );

      await ref
          .read(authRepositoryProvider)
          .setOnlineStatus(true);

      await FcmService().init();

      ref.invalidate(profilesProvider);

      if (mounted) {
        context.go('/home');
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
        title: const Text('Вход'),
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
                    isLoading ? null : signIn,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Войти'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}