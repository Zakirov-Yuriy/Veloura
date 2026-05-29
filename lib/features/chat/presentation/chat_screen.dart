import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/luxury_theme.dart';
import 'providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

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
      ref.read(chatRepositoryProvider).setTyping(
            chatId: widget.chatId,
            isTyping: messageController.text.trim().isNotEmpty,
          );
    });
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    await ref.read(chatRepositoryProvider).sendMessage(chatId: widget.chatId, text: messageController.text.trim());
    messageController.clear();
    await ref.read(chatRepositoryProvider).setTyping(chatId: widget.chatId, isTyping: false);
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final chatAsync = ref.watch(chatProvider(widget.chatId));

    return Scaffold(
      body: LuxuryScreen(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 12, 10),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                    Expanded(
                      child: chatAsync.when(
                        data: (chat) {
                          final otherUser = Map<String, dynamic>.from(chat['otherUser'] ?? {});
                          final photos = List<String>.from(otherUser['photoUrls'] ?? []);
                          final photoUrl = photos.isNotEmpty ? photos.first : null;
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: LuxuryColors.gold, width: 2.0)),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                                  child: photoUrl == null ? const Icon(Icons.person) : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(otherUser['name'] ?? 'Пользователь', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(otherUser['isOnline'] == true ? 'Онлайн' : 'Не в сети', style: const TextStyle(color: LuxuryColors.online, fontSize: 11)),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const Text('Чат'),
                        error: (_, __) => const Text('Чат'),
                      ),
                    ),
                    const Icon(Icons.more_vert, color: Colors.white),
                  ],
                ),
              ),
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) return const Center(child: Text('Напишите первое сообщение'));
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message['senderId'] == currentUserId;
                        final readBy = List<String>.from(message['readBy'] ?? []);
                        final isReadByOther = readBy.length > 1;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                            decoration: BoxDecoration(
                              gradient: isMe ? luxuryGradient : null,
                              color: isMe ? null : const Color(0xFF1B1B1B),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 5),
                                bottomRight: Radius.circular(isMe ? 5 : 16),
                              ),
                              border: Border.all(color: isMe ? Colors.transparent : Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(child: Text(message['text'] ?? '', style: const TextStyle(color: Colors.white, height: 1.35))),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  Icon(isReadByOther ? Icons.done_all : Icons.done, size: 15, color: Colors.white70),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: LuxuryColors.gold)),
                  error: (error, _) => Center(child: Text(error.toString())),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: luxuryInputDecoration('Сообщение...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: luxuryGradient),
                          child: const Icon(Icons.send, color: Colors.white, size: 21),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
