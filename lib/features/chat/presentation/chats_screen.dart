import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/bot_localization.dart';
import '../../../core/theme/luxury_theme.dart';
import '../../../core/utils/presence.dart';
import '../../../core/widgets/glow_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../safety/presentation/providers/safety_provider.dart';
import 'providers/chat_provider.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chatsAsync = ref.watch(myChatsProvider);
    final currentUserId = ref.read(chatRepositoryProvider).currentUserId;

    return Scaffold(
      extendBody: true,
      body: LuxuryScreen(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.chatsTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    SvgPicture.asset('assets/icons/king.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(LuxuryColors.gold, BlendMode.srcIn)),
                  ],
                ),
                const SizedBox(height: 16),
                GlowField(
                  builder: (focusNode) => TextField(
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: luxuryInputDecoration(l10n.search, suffixIcon: Icons.tune).copyWith(
                      prefixIcon: const Icon(Icons.search, color: LuxuryColors.muted, size: 19),
                      enabledBorder: transparentInputBorder(),
                      focusedBorder: transparentInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: chatsAsync.when(
                    data: (chats) {
                      final blocked = ref.watch(blockedUserIdsProvider).value ?? <String>{};
                      final visibleChats = chats.where((c) {
                        final ou = Map<String, dynamic>.from(c['otherUser'] ?? {});
                        return !blocked.contains(ou['uid']);
                      }).toList();

                      // Сортировка: сначала самые свежие (по updatedAt).
                      // Страховка для чатов, у которых updatedAt ещё не выставлен.
                      visibleChats.sort((a, b) {
                        final aTs = a['updatedAt'];
                        final bTs = b['updatedAt'];
                        if (aTs == null && bTs == null) return 0;
                        if (aTs == null) return 1;
                        if (bTs == null) return -1;
                        final aTime = (aTs as Timestamp).toDate();
                        final bTime = (bTs as Timestamp).toDate();
                        return bTime.compareTo(aTime);
                      });
                      if (visibleChats.isEmpty) return Center(child: Text(l10n.noChatsYet));
                      return ListView.separated(
                        padding: EdgeInsets.only(
                          bottom: 104 + MediaQuery.of(context).padding.bottom,
                        ),
                        itemCount: visibleChats.length,
                        separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.06), indent: 72),
                        itemBuilder: (context, index) {
                          final chat = visibleChats[index];
                          final otherUser = chat['otherUser'] as Map<String, dynamic>;
                          final photos = List<String>.from(otherUser['photoUrls'] ?? []);
                          final photoUrl = photos.isNotEmpty ? photos.first : null;
                          final isOnline = isUserOnline(otherUser);
                          final unreadBy = List<String>.from(chat['unreadBy'] ?? []);
                          final hasUnread = unreadBy.contains(currentUserId);
                          final unreadCount = chat['unreadCount'] ?? 0;
                          final typingUsers = List<String>.from(chat['typingUsers'] ?? []);
                          final isOtherTyping = typingUsers.any((id) => id != currentUserId);
                          final name = context.botField(otherUser, 'name');

                          return Dismissible(
                            key: ValueKey(chat['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.redAccent.withOpacity(0.15),
                              child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1B1B1B),
                                  title: Text(l10n.deleteChatTitle, style: const TextStyle(color: Colors.white)),
                                  content: Text(
                                    l10n.deleteChatBody,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel, style: const TextStyle(color: Colors.white70)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              ) ?? false;
                            },
                            onDismissed: (_) async {
                              try {
                                await ref.read(chatRepositoryProvider).deleteChat(chat['id'] as String);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.deleteFailed(e.toString()))),
                                  );
                                }
                              }
                            },
                            child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: LuxuryColors.gold.withOpacity(0.8), width: 2.0)),
                                  child: CircleAvatar(
                                    radius: 27,
                                    backgroundColor: LuxuryColors.black2,
                                    backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                                    child: photoUrl == null ? const Icon(Icons.person, color: LuxuryColors.gold) : null,
                                  ),
                                ),
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: isOnline ? LuxuryColors.online : LuxuryColors.muted,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF0B0B0B), width: 2.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name.isNotEmpty ? name : l10n.user,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isOnline ? l10n.online : l10n.offline,
                                  style: TextStyle(
                                    color: isOnline ? LuxuryColors.online : LuxuryColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              isOtherTyping ? l10n.typing : chat['lastMessage'].toString().isEmpty ? l10n.newMatchShort : chat['lastMessage'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isOtherTyping ? LuxuryColors.gold : LuxuryColors.muted, fontSize: 12),
                            ),
                            trailing: hasUnread && unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(color: LuxuryColors.gold, shape: BoxShape.circle),
                                    child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                                  )
                                : Text(_formatChatTime(chat['updatedAt'], l10n), style: const TextStyle(color: LuxuryColors.muted, fontSize: 11)),
                            onTap: () => context.push('/chat/${chat['id']}'),
                          ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: LuxuryColors.gold)),
                    error: (error, _) => Center(child: Text(error.toString())),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatChatTime(dynamic timestamp, AppLocalizations l10n) {
    if (timestamp == null) return '';
    final dt = (timestamp as Timestamp).toDate().toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff == 1) {
      return l10n.yesterday;
    } else if (diff < 7) {
      final days = [
        l10n.weekdayMon,
        l10n.weekdayTue,
        l10n.weekdayWed,
        l10n.weekdayThu,
        l10n.weekdayFri,
        l10n.weekdaySat,
        l10n.weekdaySun,
      ];
      return days[dt.weekday - 1];
    } else {
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$d.$mo';
    }
  }
}
