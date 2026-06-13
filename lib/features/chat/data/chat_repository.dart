import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated');
    }
    return user.uid;
  }

  String? get currentUserIdOrNull => _auth.currentUser?.uid;

  Stream<List<Map<String, dynamic>>> getMyChats() async* {
    final userId = currentUserIdOrNull;
    if (userId == null) {
      yield [];
      return;
    }

    await for (final snapshot in _firestore
        .collection('chats')
        .where('members', arrayContains: userId)
        .snapshots()) {
      final chats = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final members =
            List<String>.from(data['members']);

        final otherUserId = members.firstWhere(
          (id) => id != userId,
        );

        final userDoc = await _firestore
            .collection('users')
            .doc(otherUserId)
            .get();

        final userData = userDoc.data() ?? {};

        chats.add({
          ...data,
          'otherUser': userData,
        });
      }

      yield chats;
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                // id документа — нужен для удаления и других операций.
                'id': doc.id,
                // true, пока запись не подтверждена сервером —
                // используется для статуса «отправлено/доставлено».
                '_pending': doc.metadata.hasPendingWrites,
              })
          .toList();

      messages.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp;
        final bTime = b['createdAt'] as Timestamp;

        return aTime.compareTo(bTime);
      });

      return messages;
    });
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final userId = currentUserIdOrNull;
    if (userId == null) return;

    final chatDoc =
        await _firestore.collection('chats').doc(chatId).get();

    final chatData = chatDoc.data() ?? {};

    final members =
        List<String>.from(chatData['members'] ?? []);

    final receiverId = members.firstWhere(
      (id) => id != userId,
    );

    await _firestore.collection('messages').add({
      'chatId': chatId,
      'senderId': userId,
      'receiverId': receiverId,
      'text': text.trim(),
      'createdAt': Timestamp.now(),
      'readBy': [userId],
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text.trim(),
      'lastMessageSenderId': userId,
      'unreadCount': FieldValue.increment(1),
      'unreadBy': FieldValue.arrayUnion([receiverId]),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Отправка медиа-сообщения (фото или видео).
  ///
  /// [mediaType] — 'image' или 'video'.
  Future<void> sendMediaMessage({
    required String chatId,
    required String mediaUrl,
    required String mediaType,
  }) async {
    final userId = currentUserIdOrNull;
    if (userId == null) return;

    final chatDoc =
        await _firestore.collection('chats').doc(chatId).get();

    final chatData = chatDoc.data() ?? {};

    final members =
        List<String>.from(chatData['members'] ?? []);

    final receiverId = members.firstWhere(
      (id) => id != userId,
    );

    final preview = mediaType == 'video' ? '🎥 Видео' : '📷 Фото';

    await _firestore.collection('messages').add({
      'chatId': chatId,
      'senderId': userId,
      'receiverId': receiverId,
      'text': '',
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'createdAt': Timestamp.now(),
      'readBy': [userId],
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': preview,
      'lastMessageSenderId': userId,
      'unreadCount': FieldValue.increment(1),
      'unreadBy': FieldValue.arrayUnion([receiverId]),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Отправка голосового сообщения.
  ///
  /// [audioUrl] — ссылка на загруженный аудиофайл.
  /// [durationMs] — длительность записи в миллисекундах.
  Future<void> sendVoiceMessage({
    required String chatId,
    required String audioUrl,
    required int durationMs,
  }) async {
    final userId = currentUserIdOrNull;
    if (userId == null) return;

    final chatDoc =
        await _firestore.collection('chats').doc(chatId).get();

    final chatData = chatDoc.data() ?? {};

    final members =
        List<String>.from(chatData['members'] ?? []);

    final receiverId = members.firstWhere(
      (id) => id != userId,
    );

    await _firestore.collection('messages').add({
      'chatId': chatId,
      'senderId': userId,
      'receiverId': receiverId,
      'text': '',
      'mediaUrl': audioUrl,
      'mediaType': 'audio',
      'audioDurationMs': durationMs,
      'createdAt': Timestamp.now(),
      'readBy': [userId],
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': '🎤 Голосовое сообщение',
      'lastMessageSenderId': userId,
      'unreadCount': FieldValue.increment(1),
      'unreadBy': FieldValue.arrayUnion([receiverId]),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Удаление сообщения по его id.
  ///
  /// После удаления, если это было последнее сообщение в чате,
  /// пересчитывает превью (lastMessage) в документе чата.
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final userId = currentUserIdOrNull;
    if (userId == null) return;

    await _firestore.collection('messages').doc(messageId).delete();

    // Находим самое свежее оставшееся сообщение, чтобы обновить превью чата.
    final remaining = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .get();

    if (remaining.docs.isEmpty) {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '',
        'updatedAt': Timestamp.now(),
      });
      return;
    }

    final docs = remaining.docs.toList()
      ..sort((a, b) {
        final at = a.data()['createdAt'] as Timestamp;
        final bt = b.data()['createdAt'] as Timestamp;
        return bt.compareTo(at);
      });

    final last = docs.first.data();
    String preview;
    final mediaType = last['mediaType'] as String?;
    if (mediaType == 'audio') {
      preview = '🎤 Голосовое сообщение';
    } else if (mediaType == 'video') {
      preview = '🎥 Видео';
    } else if (mediaType == 'image') {
      preview = '📷 Фото';
    } else {
      preview = (last['text'] as String?) ?? '';
    }

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': preview,
      'lastMessageSenderId': last['senderId'],
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final userId = currentUserIdOrNull;
    if (userId == null) return;

    final messagesSnapshot = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .get();

    for (final doc in messagesSnapshot.docs) {
      final data = doc.data();

      final readBy =
          List<String>.from(data['readBy'] ?? []);

      if (!readBy.contains(userId)) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([
            userId,
          ]),
        });
      }
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    final userId = currentUserIdOrNull;
    if (userId == null) return;

    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount': 0,
      'unreadBy': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> setTyping({
    required String chatId,
    required bool isTyping,
  }) async {
    final userId = currentUserIdOrNull;
    if (userId == null) return;

    await _firestore.collection('chats').doc(chatId).update({
      'typingUsers': isTyping
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    });
  }

  Stream<Map<String, dynamic>> getChat(String chatId) async* {
    final userId = currentUserIdOrNull;
    if (userId == null) {
      yield {};
      return;
    }

    await for (final doc in _firestore.collection('chats').doc(chatId).snapshots()) {
      final chat = doc.data() ?? {};

      final members = List<String>.from(chat['members'] ?? []);

      if (members.isEmpty) {
        yield chat;
        continue;
      }

      final otherUserId = members.firstWhere(
        (id) => id != userId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) {
        yield chat;
        continue;
      }

      final userDoc = await _firestore.collection('users').doc(otherUserId).get();

      yield {
        ...chat,
        'otherUser': userDoc.data() ?? {},
      };
    }
  }

  Stream<int> getUnreadChatsCount() {
    return _firestore
        .collection('chats')
        .where('unreadBy', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}