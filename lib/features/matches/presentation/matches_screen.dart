import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/matches_provider.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(myMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Матчи'),
      ),
      body: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return const Center(
              child: Text('Матчей пока нет'),
            );
          }

          return ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final match = matches[index];
              final otherUser =
                  match['otherUser'] as Map<String, dynamic>;

              final photos =
                  List<String>.from(otherUser['photoUrls'] ?? []);

              final photoUrl =
                  photos.isNotEmpty ? photos.first : null;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(otherUser['name'] ?? 'Пользователь'),
                subtitle: Text(otherUser['city'] ?? ''),
                trailing: const Icon(Icons.chat),
                onTap: () {
                  context.go('/chat/${match['id']}');
                },
              );
            },
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(error.toString()),
          );
        },
      ),
    );
  }
}
