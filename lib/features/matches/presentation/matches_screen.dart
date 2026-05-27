import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/matches_provider.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pink = Color(0xFFFF4F7B);

    final matchesAsync = ref.watch(myMatchesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Матчи',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.8,
        foregroundColor: Colors.black,
      ),
      body: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: Text(
                'Матчей пока нет',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color(0xFFF0F0F0),
              indent: 76,
            ),
            itemBuilder: (context, index) {
              final match = matches[index];
              final otherUser =
                  match['otherUser'] as Map<String, dynamic>;

              final photos =
                  List<String>.from(otherUser['photoUrls'] ?? []);
              final photoUrl = photos.isNotEmpty ? photos.first : null;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFF2F2F2),
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.black54,
                        )
                      : null,
                ),
                title: Text(
                  otherUser['name'] ?? 'Пользователь',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  otherUser['city'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 13,
                  ),
                ),
                trailing: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                onTap: () {
                  context.go('/chat/${match['id']}');
                },
              );
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(color: pink),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(
              error.toString(),
              style: const TextStyle(color: Colors.black),
            ),
          );
        },
      ),
    );
  }
}
