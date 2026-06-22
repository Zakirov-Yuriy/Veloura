import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/home_provider.dart';
import '../../../core/i18n/bot_localization.dart';
import '../../../core/utils/presence.dart';
import '../../../l10n/app_localizations.dart';
import '../../safety/presentation/providers/safety_provider.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileDetailsScreen({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState
    extends ConsumerState<ProfileDetailsScreen> {
  final pageController = PageController();

  int currentPhotoIndex = 0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photos =
        List<String>.from(widget.profile['photoUrls'] ?? []);

    final isOnline = isUserOnline(widget.profile);

    // Локализованные данные анкеты (для живых юзеров — как есть).
    final name = context.botField(widget.profile, 'name');
    final city = context.botField(widget.profile, 'city');
    final bio = context.botField(widget.profile, 'bio');
    final age = widget.profile['age'] ?? '';

    Future<void> passUser() async {
      await ref
          .read(homeRepositoryProvider)
          .passUser(widget.profile['uid']);

      ref.invalidate(profilesProvider);

      if (context.mounted) {
        context.pop();
      }
    }

    Future<void> likeUser() async {
      final isMatch = await ref
          .read(homeRepositoryProvider)
          .likeUser(widget.profile['uid']);

      ref.invalidate(profilesProvider);

      if (context.mounted) {
        context.pop();

        if (isMatch) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.newMatchExcited),
            ),
          );
        }
      }
    }

    Future<void> reportUser() async {
      await ref.read(safetyRepositoryProvider).reportUser(
            reportedUserId: widget.profile['uid'],
            reason: 'inappropriate_profile',
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.complaintSent),
          ),
        );
      }
    }

    Future<void> blockUser() async {
      await ref
          .read(safetyRepositoryProvider)
          .blockUser(widget.profile['uid']);

      ref.invalidate(profilesProvider);

      if (context.mounted) {
        context.pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.userBlocked),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                reportUser();
              }

              if (value == 'block') {
                blockUser();
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'report',
                  child: Text(l10n.report),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Text(l10n.block),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height:
                        MediaQuery.of(context).size.height *
                            0.62,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: pageController,
                          itemCount:
                              photos.isEmpty ? 1 : photos.length,
                          onPageChanged: (index) {
                            setState(() {
                              currentPhotoIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            if (photos.isEmpty) {
                              return const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 120,
                                ),
                              );
                            }

                            return CachedNetworkImage(
                              imageUrl: photos[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          },
                        ),
                        if (photos.length > 1)
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 12,
                            child: Row(
                              children: List.generate(
                                photos.length,
                                (index) {
                                  final isActive =
                                      index == currentPhotoIndex;

                                  return Expanded(
                                    child: Container(
                                      height: 4,
                                      margin:
                                          const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.white38,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${name.isNotEmpty ? name : l10n.user}, $age',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          city,
                          style:
                              const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? l10n.online : l10n.offline,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          bio,
                          style:
                              const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: passUser,
                      icon: const Icon(Icons.close),
                      label: Text(l10n.skip),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: likeUser,
                      icon: const Icon(Icons.favorite),
                      label: Text(l10n.like),
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
