import 'dart:async';
import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/utils/presence.dart';
import '../../profile/presentation/providers/cloudinary_provider.dart';
import '../../safety/presentation/providers/safety_provider.dart';
import 'providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final messageController = TextEditingController();
  final _picker = ImagePicker();
  bool _isSendingMedia = false;

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

  Future<void> reportUser(String otherUserId) async {
    await ref.read(safetyRepositoryProvider).reportUser(
          reportedUserId: otherUserId,
          reason: 'inappropriate_profile',
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Жалоба отправлена')),
      );
    }
  }

  Future<void> blockUser(String otherUserId) async {
    await ref.read(safetyRepositoryProvider).blockUser(otherUserId);

    if (!mounted) return;

    // Сохраняем messenger до выхода с экрана, чтобы показать уведомление.
    final messenger = ScaffoldMessenger.of(context);

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Пользователь заблокирован')),
    );
  }

  // -------------------------------------------------------------------------
  // Профиль собеседника
  // -------------------------------------------------------------------------

  void _showUserProfileSheet(Map<String, dynamic> user) {
    if (user.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserProfileSheet(user: user),
    );
  }

  // -------------------------------------------------------------------------
  // Действия с сообщением (долгое нажатие)
  // -------------------------------------------------------------------------

  void _showMessageActions(Map<String, dynamic> message, bool isMe) {
    final text = (message['text'] as String?) ?? '';
    final hasText = text.trim().isNotEmpty;
    final messageId = message['id'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1B1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (hasText)
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white70),
                title: const Text('Копировать', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Скопировано'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(sheetContext);
                if (messageId != null) _confirmDeleteMessage(messageId);
              },
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: const Text('Удалить сообщение?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Сообщение будет удалено без возможности восстановления.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(chatRepositoryProvider).deleteMessage(
                      chatId: widget.chatId,
                      messageId: messageId,
                    );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Не удалось удалить: $e')),
                  );
                }
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    await ref.read(chatRepositoryProvider).sendMessage(chatId: widget.chatId, text: messageController.text.trim());
    messageController.clear();
    await ref.read(chatRepositoryProvider).setTyping(chatId: widget.chatId, isTyping: false);
  }

  // -------------------------------------------------------------------------
  // Прикрепление медиа
  // -------------------------------------------------------------------------

  void _showAttachmentSheet() {
    if (_isSendingMedia) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1B1B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo, color: LuxuryColors.gold),
              title: const Text('Фото из галереи', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: LuxuryColors.gold),
              title: const Text('Сделать фото', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: LuxuryColors.gold),
              title: const Text('Видео из галереи', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndSendVideo();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked == null) return;

    await _uploadAndSend(File(picked.path), 'image');
  }

  Future<void> _pickAndSendVideo() async {
    final XFile? picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 1),
    );
    if (picked == null) return;

    final file = File(picked.path);

    // Cloudinary на бесплатном тарифе принимает видео до 100 МБ.
    final sizeMb = await file.length() / (1024 * 1024);
    if (sizeMb > 95) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Видео слишком большое (максимум ~95 МБ)')),
        );
      }
      return;
    }

    await _uploadAndSend(file, 'video');
  }

  Future<void> _uploadAndSend(File file, String mediaType) async {
    setState(() => _isSendingMedia = true);

    try {
      final url = await ref.read(cloudinaryServiceProvider).uploadChatMedia(file);

      await ref.read(chatRepositoryProvider).sendMediaMessage(
            chatId: widget.chatId,
            mediaUrl: url,
            mediaType: mediaType,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingMedia = false);
    }
  }

  Future<void> _uploadAndSendVoice(File file, int durationMs) async {
    setState(() => _isSendingMedia = true);

    try {
      final url = await ref.read(cloudinaryServiceProvider).uploadChatMedia(file);

      await ref.read(chatRepositoryProvider).sendVoiceMessage(
            chatId: widget.chatId,
            audioUrl: url,
            durationMs: durationMs,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить голосовое: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingMedia = false);
      // Удаляем временный файл записи.
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Превью-кадр видео из Cloudinary: меняем расширение на .jpg.
  String _videoThumbnail(String videoUrl) {
    final dot = videoUrl.lastIndexOf('.');
    if (dot == -1) return videoUrl;
    return '${videoUrl.substring(0, dot)}.jpg';
  }

  // -------------------------------------------------------------------------
  // Время и даты сообщений
  // -------------------------------------------------------------------------

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    final dt = (createdAt as Timestamp).toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  String _formatDay(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);

    if (day == today) return 'Сегодня';
    if (day == today.subtract(const Duration(days: 1))) return 'Вчера';

    final base = '${dt.day} ${_months[dt.month - 1]}';
    return dt.year == now.year ? base : '$base ${dt.year}';
  }

  bool _isNewDay(dynamic current, dynamic previous) {
    if (current == null) return false;
    if (previous == null) return true;
    final c = (current as Timestamp).toDate();
    final p = (previous as Timestamp).toDate();
    return c.year != p.year || c.month != p.month || c.day != p.day;
  }

  Widget _dateChip(DateTime dt) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _formatDay(dt),
          style: const TextStyle(color: Colors.white60, fontSize: 11.5),
        ),
      ),
    );
  }

  Widget _buildMediaBubble(Map<String, dynamic> message) {
    final mediaUrl = message['mediaUrl'] as String;
    final mediaType = message['mediaType'] as String? ?? 'image';
    final isVideo = mediaType == 'video';

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _VideoViewerScreen(url: mediaUrl),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _ImageViewerScreen(url: mediaUrl),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: isVideo ? _videoThumbnail(mediaUrl) : mediaUrl,
              width: 220,
              height: 260,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 220,
                height: 260,
                color: Colors.white10,
                child: const Center(
                  child: CircularProgressIndicator(color: LuxuryColors.gold, strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 220,
                height: 160,
                color: Colors.white10,
                child: const Icon(Icons.broken_image, color: Colors.white38),
              ),
            ),
            if (isVideo)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 34),
              ),
          ],
        ),
      ),
    );
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
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: chatAsync.when(
                        data: (chat) {
                          final otherUser = Map<String, dynamic>.from(chat['otherUser'] ?? {});
                          final photos = List<String>.from(otherUser['photoUrls'] ?? []);
                          final photoUrl = photos.isNotEmpty ? photos.first : null;
                          return Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showUserProfileSheet(otherUser),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: LuxuryColors.gold, width: 2.0)),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                                    child: photoUrl == null ? const Icon(Icons.person) : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showUserProfileSheet(otherUser),
                                  behavior: HitTestBehavior.opaque,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(otherUser['name'] ?? 'Пользователь', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Builder(builder: (_) {
                                        final online = isUserOnline(otherUser);
                                        return Text(
                                          online ? 'Онлайн' : 'Не в сети',
                                          style: TextStyle(color: online ? LuxuryColors.online : Colors.white54, fontSize: 11),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Text('Чат'),
                        error: (_, __) => const Text('Чат'),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        final chat = chatAsync.value;
                        final otherUser = chat != null
                            ? Map<String, dynamic>.from(chat['otherUser'] ?? {})
                            : <String, dynamic>{};
                        final otherUserId = otherUser['uid'] as String?;
                        if (otherUserId == null) return;

                        if (value == 'report') {
                          reportUser(otherUserId);
                        }

                        if (value == 'block') {
                          blockUser(otherUserId);
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: 'report',
                            child: Text('Пожаловаться'),
                          ),
                          PopupMenuItem(
                            value: 'block',
                            child: Text('Заблокировать'),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) return const Center(child: Text('Напишите первое сообщение'));
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        final msgIndex = messages.length - 1 - index;
                        final prevMessage = msgIndex > 0 ? messages[msgIndex - 1] : null;
                        final showDateChip = _isNewDay(message['createdAt'], prevMessage?['createdAt']);
                        final timeText = _formatTime(message['createdAt']);
                        final isMe = message['senderId'] == currentUserId;
                        final readBy = List<String>.from(message['readBy'] ?? []);
                        final isReadByOther = readBy.length > 1;
                        // Статус: одна галочка — отправлено (ещё не подтверждено
                        // сервером), две серые — доставлено, две голубые — прочитано.
                        final isPending = message['_pending'] == true;
                        final tickIcon = isPending ? Icons.done : Icons.done_all;
                        final tickColor = isReadByOther ? const Color(0xFF6CD7FF) : Colors.white60;
                        final hasMedia = (message['mediaUrl'] as String?)?.isNotEmpty == true;
                        final isAudio = message['mediaType'] == 'audio';
                        final isVisualMedia = hasMedia && !isAudio;
                        final bubble = GestureDetector(
                          onLongPress: () => _showMessageActions(message, isMe),
                          child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: isVisualMedia
                                ? const EdgeInsets.all(4)
                                : isAudio
                                    ? const EdgeInsets.fromLTRB(8, 8, 12, 8)
                                    : const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
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
                            child: isAudio
                                ? _VoiceMessageBubble(
                                    key: ValueKey(message['mediaUrl']),
                                    url: message['mediaUrl'] as String,
                                    durationMs: (message['audioDurationMs'] as num?)?.toInt() ?? 0,
                                    isMe: isMe,
                                    timeText: timeText,
                                    tickIcon: tickIcon,
                                    tickColor: tickColor,
                                  )
                                : isVisualMedia
                                ? Stack(
                                    children: [
                                      _buildMediaBubble(message),
                                      Positioned(
                                        right: 8,
                                        bottom: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.55),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(timeText, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
                                              if (isMe) ...[
                                                const SizedBox(width: 4),
                                                Icon(tickIcon, size: 13, color: tickColor),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Flexible(child: Text(message['text'] ?? '', style: const TextStyle(color: Colors.white, height: 1.35))),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeText,
                                        style: TextStyle(
                                          color: isMe ? Colors.white70 : Colors.white38,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(tickIcon, size: 15, color: tickColor),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                        );
                        if (!showDateChip) return bubble;
                        return Column(
                          children: [
                            _dateChip((message['createdAt'] as Timestamp).toDate()),
                            bubble,
                          ],
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
                child: _ChatInputBar(
                  controller: messageController,
                  isSendingMedia: _isSendingMedia,
                  onAttach: _showAttachmentSheet,
                  onSendText: sendMessage,
                  onSendVoice: _uploadAndSendVoice,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Полноэкранный просмотр фото
// ---------------------------------------------------------------------------

class _ImageViewerScreen extends StatelessWidget {
  final String url;

  const _ImageViewerScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder: (_, __) =>
                const CircularProgressIndicator(color: LuxuryColors.gold),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Полноэкранный просмотр видео
// ---------------------------------------------------------------------------

class _VideoViewerScreen extends StatefulWidget {
  final String url;

  const _VideoViewerScreen({required this.url});

  @override
  State<_VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<_VideoViewerScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: !_initialized
            ? const CircularProgressIndicator(color: LuxuryColors.gold)
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      if (!_controller.value.isPlaying)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 42),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Шит с профилем собеседника (фото + информация)
// ---------------------------------------------------------------------------

class _UserProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;

  const _UserProfileSheet({required this.user});

  @override
  State<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<_UserProfileSheet> {
  final _pageController = PageController();
  int _photoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final photos = List<String>.from(user['photoUrls'] ?? []);
    final name = (user['name'] ?? 'Пользователь').toString();
    final age = user['age'];
    final city = (user['city'] ?? '').toString();
    final bio = (user['bio'] ?? '').toString();
    final online = isUserOnline(user);

    final title = age != null && age.toString().isNotEmpty ? '$name, $age' : name;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: LuxuryColors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: LuxuryColors.gold, width: 1.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Полоска-ручка
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Галерея фото
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photos.isEmpty)
                          Container(
                            color: LuxuryColors.card,
                            child: const Icon(Icons.person,
                                size: 80, color: Colors.white24),
                          )
                        else
                          PageView.builder(
                            controller: _pageController,
                            itemCount: photos.length,
                            onPageChanged: (i) =>
                                setState(() => _photoIndex = i),
                            itemBuilder: (_, i) => CachedNetworkImage(
                              imageUrl: photos[i],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: LuxuryColors.card,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: LuxuryColors.gold,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: LuxuryColors.card,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.white24),
                              ),
                            ),
                          ),

                        // Индикаторы фото
                        if (photos.length > 1)
                          Positioned(
                            top: 10,
                            left: 10,
                            right: 10,
                            child: Row(
                              children: List.generate(
                                photos.length,
                                (i) => Expanded(
                                  child: Container(
                                    height: 3,
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: i == _photoIndex
                                          ? LuxuryColors.gold
                                          : Colors.white38,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Затемнение снизу для читаемости статуса
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 70,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Статус онлайн
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: online
                                      ? LuxuryColors.online
                                      : Colors.white38,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                online ? 'Онлайн' : 'Не в сети',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Имя + возраст
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              // Город
              if (city.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: LuxuryColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: const TextStyle(
                          color: LuxuryColors.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Bio
              if (bio.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 6),
                  child: Text(
                    'О себе',
                    style: TextStyle(
                      color: LuxuryColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  child: Text(
                    bio,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Поле ввода с записью голосовых сообщений (стиль Telegram)
// ===========================================================================

class _ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSendingMedia;
  final VoidCallback onAttach;
  final VoidCallback onSendText;
  final Future<void> Function(File file, int durationMs) onSendVoice;

  const _ChatInputBar({
    required this.controller,
    required this.isSendingMedia,
    required this.onAttach,
    required this.onSendText,
    required this.onSendVoice,
  });

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  final _recorder = AudioRecorder();

  bool _hasText = false;
  bool _isRecording = false;
  bool _isPreview = false;
  bool _showEmoji = false;

  final _focusNode = FocusNode();

  String? _recordPath;
  DateTime? _recordStart;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  // Длительность готовой записи (фиксируется при паузе).
  Duration _recordedDuration = Duration.zero;

  // Плеер для предпрослушивания записи.
  AudioPlayer? _previewPlayer;
  bool _previewPlaying = false;
  Duration _previewPosition = Duration.zero;
  StreamSubscription<Duration>? _previewPosSub;
  StreamSubscription<PlayerState>? _previewStateSub;

  // Псевдо-волна для предпросмотра (фиксированный рисунок).
  final List<double> _previewBars = List.generate(
    30,
    (i) => 0.3 + ((i * 37) % 70) / 100,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    // При фокусе на поле ввода прячем панель эмодзи.
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
    });
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  // Переключение панели эмодзи.
  void _toggleEmoji() {
    if (_showEmoji) {
      // Скрываем панель и возвращаем клавиатуру.
      setState(() => _showEmoji = false);
      _focusNode.requestFocus();
    } else {
      // Прячем клавиатуру и показываем панель.
      _focusNode.unfocus();
      setState(() => _showEmoji = true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _timer?.cancel();
    _recorder.dispose();
    _previewPosSub?.cancel();
    _previewStateSub?.cancel();
    _previewPlayer?.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Запись
  // --------------------------------------------------------------------------

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет доступа к микрофону')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: path,
    );

    _recordPath = path;
    _recordStart = DateTime.now();
    _elapsed = Duration.zero;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _recordStart == null) return;
      setState(() => _elapsed = DateTime.now().difference(_recordStart!));
    });

    setState(() {
      _isRecording = true;
      _isPreview = false;
    });
  }

  // Остановка записи и переход в предпросмотр (без отправки).
  Future<void> _pauseRecording() async {
    _timer?.cancel();
    final duration = _elapsed;
    final path = await _recorder.stop();

    // Слишком короткая запись — отменяем целиком.
    if (path == null || duration.inMilliseconds < 800) {
      _safeDelete(path ?? _recordPath);
      setState(() {
        _isRecording = false;
        _isPreview = false;
      });
      if (mounted && duration.inMilliseconds < 800) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Слишком короткая запись')),
        );
      }
      return;
    }

    _recordPath = path;
    _recordedDuration = duration;

    // Готовим плеер для прослушивания.
    await _preparePreviewPlayer(path);

    setState(() {
      _isRecording = false;
      _isPreview = true;
      _previewPosition = Duration.zero;
      _previewPlaying = false;
    });
  }

  Future<void> _preparePreviewPlayer(String path) async {
    _previewPosSub?.cancel();
    _previewStateSub?.cancel();
    await _previewPlayer?.dispose();

    final player = AudioPlayer();
    _previewPlayer = player;

    _previewPosSub = player.positionStream.listen((p) {
      if (mounted) setState(() => _previewPosition = p);
    });
    _previewStateSub = player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        player.pause();
        player.seek(Duration.zero);
        setState(() {
          _previewPlaying = false;
          _previewPosition = Duration.zero;
        });
      } else {
        setState(() => _previewPlaying = state.playing);
      }
    });

    try {
      await player.setFilePath(path);
    } catch (_) {}
  }

  Future<void> _togglePreviewPlay() async {
    final player = _previewPlayer;
    if (player == null) return;
    if (_previewPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  // Отправка записи из предпросмотра.
  Future<void> _sendPreview() async {
    final path = _recordPath;
    final duration = _recordedDuration;
    await _disposePreviewPlayer();

    setState(() {
      _isPreview = false;
      _isRecording = false;
    });

    if (path == null) return;
    await widget.onSendVoice(File(path), duration.inMilliseconds);
  }

  // Удаление записи из предпросмотра.
  Future<void> _discardPreview() async {
    final path = _recordPath;
    await _disposePreviewPlayer();
    setState(() {
      _isPreview = false;
      _isRecording = false;
    });
    _safeDelete(path);
  }

  Future<void> _disposePreviewPlayer() async {
    await _previewPosSub?.cancel();
    await _previewStateSub?.cancel();
    await _previewPlayer?.dispose();
    _previewPlayer = null;
    _previewPlaying = false;
  }

  // Отмена прямо во время записи (корзина на панели записи).
  Future<void> _cancelRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isPreview = false;
    });
    _safeDelete(path ?? _recordPath);
  }

  void _safeDelete(String? path) {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final cs = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s,$cs';
  }

  String _fmtShort(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: _isPreview
              ? _buildPreviewBar()
              : _isRecording
                  ? _buildRecordingBar()
                  : _buildIdleBar(),
        ),
        // Панель эмодзи (показывается под полем ввода).
        Offstage(
          offstage: !_showEmoji,
          child: SizedBox(
            height: 280,
            child: EmojiPicker(
              textEditingController: widget.controller,
              config: Config(
                height: 280,
                checkPlatformCompatibility: true,
                emojiViewConfig: const EmojiViewConfig(
                  backgroundColor: Color(0xFF1B1B1B),
                  columns: 8,
                  emojiSizeMax: 28,
                ),
                categoryViewConfig: const CategoryViewConfig(
                  backgroundColor: Color(0xFF1B1B1B),
                  indicatorColor: LuxuryColors.gold,
                  iconColorSelected: LuxuryColors.gold,
                  iconColor: Colors.white38,
                  backspaceColor: LuxuryColors.gold,
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  backgroundColor: Color(0xFF151515),
                  buttonColor: Color(0xFF1B1B1B),
                  buttonIconColor: Colors.white54,
                ),
                searchViewConfig: const SearchViewConfig(
                  backgroundColor: Color(0xFF1B1B1B),
                  buttonIconColor: Colors.white54,
                  hintText: 'Поиск',
                ),
                skinToneConfig: const SkinToneConfig(
                  dialogBackgroundColor: Color(0xFF1B1B1B),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Обычная панель ввода.
  Widget _buildIdleBar() {
    final showSend = _hasText;

    return Row(
      children: [
        widget.isSendingMedia
            ? const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: LuxuryColors.gold, strokeWidth: 2),
                  ),
                ),
              )
            : IconButton(
                onPressed: widget.onAttach,
                icon: const Icon(Icons.attach_file, color: Colors.white70),
              ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white),
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    onTap: () {
                      if (_showEmoji) setState(() => _showEmoji = false);
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Сообщение',
                      hintStyle: TextStyle(color: LuxuryColors.muted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleEmoji,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      _showEmoji
                          ? Icons.keyboard_outlined
                          : Icons.emoji_emotions_outlined,
                      color: _showEmoji
                          ? LuxuryColors.gold
                          : Colors.white.withOpacity(0.55),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Кнопка: отправка текста ИЛИ микрофон.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: showSend
              ? GestureDetector(
                  key: const ValueKey('send'),
                  onTap: widget.onSendText,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: luxuryGradient,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 21),
                  ),
                )
              : GestureDetector(
                  key: const ValueKey('mic'),
                  onTap: _startRecording,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: luxuryGradient,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 22),
                  ),
                ),
        ),
      ],
    );
  }

  // Панель во время записи.
  Widget _buildRecordingBar() {
    return Row(
      children: [
        // Кнопка отмены (удалить запись).
        GestureDetector(
          onTap: _cancelRecording,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
          ),
        ),
        const SizedBox(width: 10),
        // Красная мигающая точка + таймер.
        _BlinkingDot(),
        const SizedBox(width: 10),
        Text(
          _fmt(_elapsed),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text(
              'Идёт запись…',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Кнопка паузы (тап — остановить и перейти к предпросмотру).
        GestureDetector(
          onTap: _pauseRecording,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: luxuryGradient,
              boxShadow: [
                BoxShadow(
                  color: LuxuryColors.gold.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.pause, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }

  // Панель предпросмотра записи: удалить — прослушать — отправить.
  Widget _buildPreviewBar() {
    final total = _recordedDuration.inMilliseconds > 0
        ? _recordedDuration
        : const Duration(milliseconds: 1);
    final progress =
        (_previewPosition.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final shown = _previewPlaying || _previewPosition > Duration.zero
        ? _previewPosition
        : _recordedDuration;

    return Row(
      children: [
        // Удалить запись.
        GestureDetector(
          onTap: _discardPreview,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
          ),
        ),
        const SizedBox(width: 8),
        // Плеер: play/pause + волна + время.
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _togglePreviewPlay,
                  child: Icon(
                    _previewPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: LuxuryColors.gold,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: CustomPaint(
                      size: const Size(double.infinity, 24),
                      painter: _WaveformPainter(
                        bars: _previewBars,
                        progress: progress,
                        activeColor: LuxuryColors.gold,
                        inactiveColor: Colors.white24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmtShort(shown),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Отправить.
        GestureDetector(
          onTap: _sendPreview,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: luxuryGradient,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 21),
          ),
        ),
      ],
    );
  }
}

// Мигающая красная точка во время записи.
class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.2).animate(_c),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.redAccent,
        ),
      ),
    );
  }
}

// ===========================================================================
// Плеер голосового сообщения (волна + play/pause + время)
// ===========================================================================

class _VoiceMessageBubble extends StatefulWidget {
  final String url;
  final int durationMs;
  final bool isMe;
  final String timeText;
  final IconData tickIcon;
  final Color tickColor;

  const _VoiceMessageBubble({
    super.key,
    required this.url,
    required this.durationMs,
    required this.isMe,
    required this.timeText,
    required this.tickIcon,
    required this.tickColor,
  });

  @override
  State<_VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<_VoiceMessageBubble> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _prepared = false;

  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  // Псевдо-волна: стабильный набор высот, детерминированный от URL,
  // чтобы у одного сообщения волна не менялась между перерисовками.
  late final List<double> _bars = _generateBars(widget.url);

  static List<double> _generateBars(String seedStr) {
    final seed = seedStr.hashCode;
    final rnd = (int i) {
      final x = ((seed ^ (i * 2654435761)) & 0x7fffffff) / 0x7fffffff;
      return x;
    };
    return List.generate(34, (i) {
      final v = rnd(i);
      return 0.25 + v * 0.75; // от 0.25 до 1.0
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.durationMs > 0) {
      _total = Duration(milliseconds: widget.durationMs);
    }
  }

  Future<void> _ensurePrepared() async {
    if (_prepared) return;
    _player = AudioPlayer();
    _prepared = true;

    _posSub = _player!.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _stateSub = _player!.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing &&
            state.processingState != ProcessingState.completed;
        _isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
      if (state.processingState == ProcessingState.completed) {
        _player!.pause();
        _player!.seek(Duration.zero);
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      }
    });

    setState(() => _isLoading = true);
    try {
      final dur = await _player!.setUrl(widget.url);
      if (dur != null && mounted) setState(() => _total = dur);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить голосовое')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle() async {
    await _ensurePrepared();
    if (_player == null) return;
    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_total.inMilliseconds > 0)
        ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final activeColor = widget.isMe ? Colors.white : LuxuryColors.gold;
    final inactiveColor =
        widget.isMe ? Colors.white.withOpacity(0.4) : Colors.white24;

    final shownDuration = _isPlaying || _position > Duration.zero
        ? _position
        : (_total > Duration.zero ? _total : Duration.zero);

    return SizedBox(
      width: 220,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Кнопка play/pause.
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isMe ? Colors.white.withOpacity(0.22) : LuxuryColors.gold,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: widget.isMe ? Colors.white : Colors.black,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // Волна + время.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 26,
                  child: GestureDetector(
                    onTapDown: (d) async {
                      await _ensurePrepared();
                      final box = context.findRenderObject() as RenderBox?;
                      if (box == null || _total == Duration.zero) return;
                      final local = d.localPosition.dx;
                      final ratio = (local / box.size.width).clamp(0.0, 1.0);
                      await _player?.seek(_total * ratio);
                    },
                    child: CustomPaint(
                      size: const Size(double.infinity, 26),
                      painter: _WaveformPainter(
                        bars: _bars,
                        progress: progress,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _fmt(shownDuration),
                      style: TextStyle(
                        color: widget.isMe ? Colors.white70 : Colors.white54,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.timeText,
                      style: TextStyle(
                        color: widget.isMe ? Colors.white60 : Colors.white38,
                        fontSize: 10.5,
                      ),
                    ),
                    if (widget.isMe) ...[
                      const SizedBox(width: 4),
                      Icon(widget.tickIcon, size: 13, color: widget.tickColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const gap = 2.0;
    final barWidth = (size.width - gap * (bars.length - 1)) / bars.length;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    final activeBars = (bars.length * progress).round();

    for (var i = 0; i < bars.length; i++) {
      final h = bars[i] * size.height;
      final x = i * (barWidth + gap);
      final top = (size.height - h) / 2;
      paint.color = i < activeBars ? activeColor : inactiveColor;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, h),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor;
}