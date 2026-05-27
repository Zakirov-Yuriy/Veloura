import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/chat_provider.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(myChatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(
              child: Text('Чатов пока нет'),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final chat = chats[index];

              final otherUser =
                  chat['otherUser'] as Map<String, dynamic>;

              final isOnline =
                  otherUser['isOnline'] == true;

              final unreadBy = List<String>.from(chat['unreadBy'] ?? []);

              final hasUnread = unreadBy.contains(
                ref.read(chatRepositoryProvider).currentUserId,
              );

              final unreadCount = chat['unreadCount'] ?? 0;

              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherUser['name'] ?? 'Пользователь',
                      ),
                    ),
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: isOnline
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ],
                ),
                subtitle: Text(
                  chat['lastMessage'].toString().isEmpty
                      ? 'Новый матч'
                      : chat['lastMessage'],
                ),
                trailing: hasUnread && unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () {
                  context.go('/chat/${chat['id']}');
                },
              );
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(error.toString()),
          );
        },
      ),
    );
  }
}
