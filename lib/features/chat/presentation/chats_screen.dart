import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/chat_provider.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pink = Color(0xFFFF4F7B);

    final chatsAsync = ref.watch(myChatsProvider);
    final currentUserId = ref.read(chatRepositoryProvider).currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Чаты',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.8,
        foregroundColor: Colors.black,
        centerTitle: false,
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'Чатов пока нет',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color(0xFFF0F0F0),
              indent: 76,
            ),
            itemBuilder: (context, index) {
              final chat = chats[index];

              final otherUser =
                  chat['otherUser'] as Map<String, dynamic>;

              final photos =
                  List<String>.from(otherUser['photoUrls'] ?? []);

              final photoUrl = photos.isNotEmpty ? photos.first : null;

              final unreadBy = List<String>.from(chat['unreadBy'] ?? []);
              final hasUnread = unreadBy.contains(currentUserId);
              final unreadCount = chat['unreadCount'] ?? 0;

              final typingUsers =
                  List<String>.from(chat['typingUsers'] ?? []);

              final isOtherTyping = typingUsers.any(
                (id) => id != currentUserId,
              );

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFF2F2F2),
                      backgroundImage: photoUrl != null
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                    if (otherUser['isOnline'] == true)
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF55C99B),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  otherUser['name'] ?? 'Пользователь',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isOtherTyping
                        ? 'Печатает...'
                        : chat['lastMessage'].toString().isEmpty
                            ? 'Новый матч'
                            : chat['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isOtherTyping
                          ? pink
                          : const Color(0xFF8A8A8A),
                      fontSize: 13,
                      fontWeight: isOtherTyping
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                trailing: hasUnread && unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: pink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFB8B8B8),
                      ),
                onTap: () {
                  context.go('/chat/${chat['id']}');
                },
              );
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(
              color: pink,
            ),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(
              error.toString(),
              style: const TextStyle(color: Colors.black),
            ),
          );
        },
      ),
    );
  }
}
