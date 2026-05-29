import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/presentation/chats_screen.dart';
import '../../chat/presentation/providers/chat_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../matches/presentation/matches_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'widgets/custom_bottom_nav_bar.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int currentIndex = 0;

  final pages = const [HomeScreen(), MatchesScreen(), ChatsScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final unreadChatsCount = ref.watch(unreadChatsCountProvider).value ?? 0;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        unreadChatsCount: unreadChatsCount,
        onTap: (index) => setState(() => currentIndex = index),
      ),
    );
  }
}
