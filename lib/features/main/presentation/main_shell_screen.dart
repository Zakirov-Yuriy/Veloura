import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/providers/auth_provider.dart';
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

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  Timer? _heartbeat;

  // Ссылку на репозиторий сохраняем в поле, чтобы можно было безопасно
  // вызвать его из dispose() — использовать ref в dispose() нельзя.
  late final AuthRepository _authRepo;

  // Как часто обновляем lastSeen, пока приложение открыто.
  static const _heartbeatInterval = Duration(seconds: 45);

  final pages = const [HomeScreen(), MatchesScreen(), ChatsScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();
    _authRepo = ref.read(authRepositoryProvider);
    WidgetsBinding.instance.addObserver(this);
    _goOnline();
  }

  void _goOnline() {
    _authRepo.setOnlineStatus(true);
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) {
      _authRepo.setOnlineStatus(true);
    });
  }

  void _goOffline() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _authRepo.setOnlineStatus(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _goOnline();
    } else {
      // paused / inactive / hidden / detached — приложение не на экране.
      _goOffline();
    }
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // Лучшая попытка пометить оффлайн при уходе с шелла (например, выход).
    // Используем сохранённую ссылку, а не ref — ref в dispose() небезопасен.
    _authRepo.setOnlineStatus(false);
    super.dispose();
  }

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