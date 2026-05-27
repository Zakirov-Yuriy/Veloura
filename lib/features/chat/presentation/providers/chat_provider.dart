import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final myChatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(chatRepositoryProvider).getMyChats();
});

final messagesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chatId) {
  return ref.read(chatRepositoryProvider).getMessages(chatId);
});

final chatProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, chatId) {
  return ref.read(chatRepositoryProvider).getChat(chatId);
});

final unreadChatsCountProvider =
    StreamProvider<int>((ref) {
  return ref
      .read(chatRepositoryProvider)
      .getUnreadChatsCount();
});
