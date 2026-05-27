import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({
    super.key,
    required this.chatId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final messageController = TextEditingController();
  bool isTyping = false;

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(chatRepositoryProvider)
          .markChatAsRead(widget.chatId);

      ref
          .read(chatRepositoryProvider)
          .markMessagesAsRead(widget.chatId);
    });

    messageController.addListener(() async {
      final hasText =
          messageController.text.trim().isNotEmpty;

      if (hasText != isTyping) {
        isTyping = hasText;

        await ref
            .read(chatRepositoryProvider)
            .setTyping(
              chatId: widget.chatId,
              isTyping: hasText,
            );
      }
    });
  }

  Future<void> sendMessage() async {
    await ref.read(chatRepositoryProvider).sendMessage(
          chatId: widget.chatId,
          text: messageController.text,
        );

    messageController.clear();

    await ref
        .read(chatRepositoryProvider)
        .setTyping(
          chatId: widget.chatId,
          isTyping: false,
        );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      messagesProvider(widget.chatId),
    );

    final chatAsync = ref.watch(chatProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Напишите первое сообщение'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    final isMe =
                        message['senderId'] == currentUserId;

                    final readBy = List<String>.from(message['readBy'] ?? []);
                    final isReadByOther = readBy.length > 1;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.pink
                              : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                message['text'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            if (isMe) ...[                              const SizedBox(width: 6),
                              Icon(
                                isReadByOther ? Icons.done_all : Icons.done,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
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
          ),
          chatAsync.when(
            data: (chat) {
              final typingUsers = List<String>.from(chat['typingUsers'] ?? []);

              final isOtherTyping = typingUsers.any(
                (userId) => userId != currentUserId,
              );

              if (!isOtherTyping) {
                return const SizedBox.shrink();
              }

              return const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Печатает...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: 'Сообщение',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
