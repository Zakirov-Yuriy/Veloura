import 'package:cached_network_image/cached_network_image.dart';
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

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(chatRepositoryProvider).markChatAsRead(widget.chatId);
      ref.read(chatRepositoryProvider).markMessagesAsRead(widget.chatId);
    });

    messageController.addListener(() {
      final hasText = messageController.text.trim().isNotEmpty;

      ref.read(chatRepositoryProvider).setTyping(
            chatId: widget.chatId,
            isTyping: hasText,
          );
    });
  }

  Future<void> sendMessage() async {
    await ref.read(chatRepositoryProvider).sendMessage(
          chatId: widget.chatId,
          text: messageController.text,
        );

    messageController.clear();

    await ref.read(chatRepositoryProvider).setTyping(
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
    const pink = Color(0xFFFF4F7B);

    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final chatAsync = ref.watch(chatProvider(widget.chatId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        title: chatAsync.when(
          data: (chat) {
            final otherUser =
                Map<String, dynamic>.from(chat['otherUser'] ?? {});

            final photos = List<String>.from(otherUser['photoUrls'] ?? []);
            final photoUrl = photos.isNotEmpty ? photos.first : null;

            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser['name'] ?? 'Пользователь',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      otherUser['isOnline'] == true ? 'Онлайн' : 'Не в сети',
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Text('Чат'),
          error: (_, __) => const Text('Чат'),
        ),
        actions: const [
          Icon(Icons.more_horiz),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Напишите первое сообщение',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == currentUserId;

                    final readBy = List<String>.from(message['readBy'] ?? []);
                    final isReadByOther = readBy.length > 1;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? pink : const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                message['text'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            if (isMe) ...[                           const SizedBox(width: 6),
                              Icon(
                                isReadByOther ? Icons.done_all : Icons.done,
                                size: 15,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
          chatAsync.when(
            data: (chat) {
              final typingUsers = List<String>.from(chat['typingUsers'] ?? []);
              final isOtherTyping = typingUsers.any((id) => id != currentUserId);

              if (!isOtherTyping) return const SizedBox.shrink();

              return const Padding(
                padding: EdgeInsets.only(left: 18, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Печатает...',
                    style: TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 13,
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
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: messageController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Сообщение...',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB8B8B8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE7E7E7),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: pink),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: pink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: sendMessage,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
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
