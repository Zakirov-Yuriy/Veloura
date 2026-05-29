import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/luxury_theme.dart';
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Чаты', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    Icon(Icons.workspace_premium, color: LuxuryColors.gold),
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
                      if (chats.isEmpty) return const Center(child: Text('Чатов пока нет'));
                      return ListView.separated(
                        itemCount: chats.length,
                        separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.06), indent: 72),
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final otherUser = chat['otherUser'] as Map<String, dynamic>;
                          final photos = List<String>.from(otherUser['photoUrls'] ?? []);
                          final photoUrl = photos.isNotEmpty ? photos.first : null;
                          final unreadBy = List<String>.from(chat['unreadBy'] ?? []);
                          final hasUnread = unreadBy.contains(currentUserId);
                          final unreadCount = chat['unreadCount'] ?? 0;
                          final typingUsers = List<String>.from(chat['typingUsers'] ?? []);
                          final isOtherTyping = typingUsers.any((id) => id != currentUserId);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: LuxuryColors.gold.withOpacity(0.8), width: 2.0)),
                              child: CircleAvatar(
                                radius: 27,
                                backgroundColor: LuxuryColors.black2,
                                backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                                child: photoUrl == null ? const Icon(Icons.person, color: LuxuryColors.gold) : null,
                              ),
                            ),
                            title: Text(otherUser['name'] ?? 'Пользователь', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                            onTap: () => context.go('/chat/${chat['id']}'),
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
