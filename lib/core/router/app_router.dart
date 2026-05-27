import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/chats_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/profile_details_screen.dart';
import '../../features/main/presentation/main_shell_screen.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/safety/presentation/blocked_users_screen.dart';

final appRouter = GoRouter(
  initialLocation:
      FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/home',
  routes: [
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainShellScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/chats',
      builder: (context, state) => const ChatsScreen(),
    ),
    GoRoute(
      path: '/chat/:chatId',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;

        return ChatScreen(chatId: chatId);
      },
    ),
    GoRoute(
      path: '/profile-details',
      builder: (context, state) {
        final profile = state.extra as Map<String, dynamic>;

        return ProfileDetailsScreen(profile: profile);
      },
    ),
    GoRoute(
      path: '/blocked-users',
      builder: (context, state) => const BlockedUsersScreen(),
    ),
  ],
);