import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/home_provider.dart';
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
    final photos =
        List<String>.from(widget.profile['photoUrls'] ?? []);

    final isOnline = widget.profile['isOnline'] == true;

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
            const SnackBar(
              content: Text('У вас новый матч 🔥'),
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
          const SnackBar(
            content: Text('Жалоба отправлена'),
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
          const SnackBar(
            content: Text('Пользователь заблокирован'),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Анкета'),
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
                          '${widget.profile['name']}, ${widget.profile['age']}',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.profile['city'] ?? '',
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
                              isOnline ? 'Онлайн' : 'Не в сети',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.profile['bio'] ?? '',
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
                      label: const Text('Пропустить'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: likeUser,
                      icon: const Icon(Icons.favorite),
                      label: const Text('Лайк'),
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
