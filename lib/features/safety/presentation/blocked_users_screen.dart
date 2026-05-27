import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/safety_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заблокированные'),
      ),
      body: blockedUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('Заблокированных пользователей нет'),
            );
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                title: Text(user['name'] ?? 'Пользователь'),
                subtitle: Text(user['city'] ?? ''),
                trailing: TextButton(
                  onPressed: () async {
                    await ref
                        .read(safetyRepositoryProvider)
                        .unblockUser(user['blockId']);

                    ref.invalidate(blockedUsersProvider);
                  },
                  child: const Text('Разблокировать'),
                ),
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
