import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/utils/presence.dart';
import '../../safety/presentation/providers/safety_provider.dart';
import 'providers/chat_provider.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);
    final currentUserId = ref.read(chatRepositoryProvider).currentUserId;

    return Scaffold(
      body: LuxuryScreen(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Чаты', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    SvgPicture.asset('assets/icons/king.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(LuxuryColors.gold, BlendMode.srcIn)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: luxuryInputDecoration('Поиск', suffixIcon: Icons.tune).copyWith(prefixIcon: const Icon(Icons.search, color: LuxuryColors.muted, size: 19)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: chatsAsync.when(
                    data: (chats) {
                      final blocked = ref.watch(blockedUserIdsProvider).value ?? <String>{};
                      final visibleChats = chats.where((c) {
                        final ou = Map<String, dynamic>.from(c['otherUser'] ?? {});
                        return !blocked.contains(ou['uid']);
                      }).toList();
                      if (visibleChats.isEmpty) return const Center(child: Text('Чатов пока нет'));
                      return ListView.separated(
                        itemCount: visibleChats.length,
                        separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.06), indent: 72),
                        itemBuilder: (context, index) {
                          final chat = visibleChats[index];
                          final otherUser = chat['otherUser'] as Map<String, dynamic>;
                          final photos = List<String>.from(otherUser['photoUrls'] ?? []);
                          final photoUrl = photos.isNotEmpty ? photos.first : null;
                          final isOnline = isUserOnline(otherUser);
                          final unreadBy = List<String>.from(chat['unreadBy'] ?? []);
                          final hasUnread = unreadBy.contains(currentUserId);
                          final unreadCount = chat['unreadCount'] ?? 0;
                          final typingUsers = List<String>.from(chat['typingUsers'] ?? []);
                          final isOtherTyping = typingUsers.any((id) => id != currentUserId);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: LuxuryColors.gold.withOpacity(0.8), width: 2.0)),
                                  child: CircleAvatar(
                                    radius: 27,
                                    backgroundColor: LuxuryColors.black2,
                                    backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                                    child: photoUrl == null ? const Icon(Icons.person, color: LuxuryColors.gold) : null,
                                  ),
                                ),
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: isOnline ? LuxuryColors.online : LuxuryColors.muted,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF0B0B0B), width: 2.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    otherUser['name'] ?? 'Пользователь',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isOnline ? 'Онлайн' : 'Не в сети',
                                  style: TextStyle(
                                    color: isOnline ? LuxuryColors.online : LuxuryColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              isOtherTyping ? 'Печатает...' : chat['lastMessage'].toString().isEmpty ? 'Новый матч' : chat['lastMessage'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isOtherTyping ? LuxuryColors.gold : LuxuryColors.muted, fontSize: 12),
                            ),
                            trailing: hasUnread && unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(color: LuxuryColors.gold, shape: BoxShape.circle),
                                    child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                  )
                                : Text(index == 0 ? '12:30' : 'Вчера', style: const TextStyle(color: LuxuryColors.muted, fontSize: 11)),
                            onTap: () => context.push('/chat/${chat['id']}'),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: LuxuryColors.gold)),
                    error: (error, _) => Center(child: Text(error.toString())),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}