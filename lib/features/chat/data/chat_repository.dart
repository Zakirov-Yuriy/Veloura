import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  Stream<List<Map<String, dynamic>>> getMyChats() async* {
    await for (final snapshot in _firestore
        .collection('chats')
        .where('members', arrayContains: currentUserId)
        .snapshots()) {
      final chats = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final members =
            List<String>.from(data['members']);

        final otherUserId = members.firstWhere(
          (id) => id != currentUserId,
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
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) => doc.data()).toList();

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

    final chatDoc =
        await _firestore.collection('chats').doc(chatId).get();

    final chatData = chatDoc.data() ?? {};

    final members =
        List<String>.from(chatData['members'] ?? []);

    final receiverId = members.firstWhere(
      (id) => id != currentUserId,
    );

    await _firestore.collection('messages').add({
      'chatId': chatId,
      'senderId': currentUserId,
      'receiverId': receiverId,
      'text': text.trim(),
      'createdAt': Timestamp.now(),
      'readBy': [currentUserId],
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text.trim(),
      'lastMessageSenderId': currentUserId,
      'unreadCount': FieldValue.increment(1),
      'unreadBy': FieldValue.arrayUnion([receiverId]),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final messagesSnapshot = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .get();

    for (final doc in messagesSnapshot.docs) {
      final data = doc.data();

      final readBy =
          List<String>.from(data['readBy'] ?? []);

      if (!readBy.contains(currentUserId)) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([
            currentUserId,
          ]),
        });
      }
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount': 0,
      'unreadBy': FieldValue.arrayRemove([currentUserId]),
    });
  }

  Future<void> setTyping({
    required String chatId,
    required bool isTyping,
  }) async {
    await _firestore.collection('chats').doc(chatId).update({
      'typingUsers': isTyping
          ? FieldValue.arrayUnion([currentUserId])
          : FieldValue.arrayRemove([currentUserId]),
    });
  }

  Stream<Map<String, dynamic>> getChat(String chatId) async* {
    await for (final doc in _firestore.collection('chats').doc(chatId).snapshots()) {
      final chat = doc.data() ?? {};

      final members = List<String>.from(chat['members'] ?? []);

      if (members.isEmpty) {
        yield chat;
        continue;
      }

      final otherUserId = members.firstWhere(
        (id) => id != currentUserId,
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
