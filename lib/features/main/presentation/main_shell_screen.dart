import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bottom_navigation_animated_notch_bar/bottom_navigation_animated_notch_bar.dart';

import '../../chat/presentation/chats_screen.dart';
import '../../chat/presentation/providers/chat_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../matches/presentation/matches_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int currentIndex = 0;
  late NotchBottomBarController _notchBottomBarController;

  final pages = const [
    HomeScreen(),
    MatchesScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _notchBottomBarController = NotchBottomBarController(index: 0);
  }

  @override
  void dispose() {
    _notchBottomBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadChatsAsync =
        ref.watch(unreadChatsCountProvider);

    final unreadChatsCount =
        unreadChatsAsync.value ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _notchBottomBarController,
        color: const Color(0xFF1A1A1A),
        notchColor: const Color(0xFF222E3A),
        activeIconColor: const Color.fromARGB(255, 146, 33, 33),
        showLabel: true,
        bottomBarHeight: 72.0,
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: const Icon(
              Icons.favorite,
              color: Colors.grey,
            ),
            activeItem: const Icon(
              Icons.favorite_outlined,
              color: Colors.white,
            ),
            itemLabel: 'Анкеты',
          ),
          BottomBarItem(
            inActiveItem: const Icon(
              Icons.local_fire_department,
              color: Colors.grey,
            ),
            activeItem: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
            ),
            itemLabel: 'Матчи',
          ),
          BottomBarItem(
            inActiveItem: Stack(
              children: [
                const Icon(
                  Icons.chat,
                  color: Colors.grey,
                ),
                if (unreadChatsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadChatsCount.toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeItem: Stack(
              children: [
                const Icon(
                  Icons.chat,
                  color: Colors.white,
                ),
                if (unreadChatsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadChatsCount.toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            itemLabel: 'Чаты',
          ),
          BottomBarItem(
            inActiveItem: const Icon(
              Icons.person,
              color: Colors.grey,
            ),
            activeItem: const Icon(
              Icons.person,
              color: Colors.white,
            ),
            itemLabel: 'Профиль',
          ),
        ],
        onTap: (index) {
          setState(() {
            currentIndex = index;
            _notchBottomBarController.jumpTo(index);
          });
        },
      ),
    );
  }
}
