import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
                        final bubble = Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: hasMedia
                                ? const EdgeInsets.all(4)
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
                            child: hasMedia
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      _isSendingMedia
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: LuxuryColors.gold, strokeWidth: 2),
                            )
                          : IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24),
                              onPressed: _showAttachmentSheet,
                              icon: const Icon(Icons.attach_file, color: Colors.white),
                            ),
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