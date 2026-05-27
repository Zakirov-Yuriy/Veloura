import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/safety_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pink = Color(0xFFFF4F7B);

    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Заблокированные',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.8,
        foregroundColor: Colors.black,
      ),
      body: blockedUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'Заблокированных пользователей нет',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color(0xFFF0F0F0),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFFF2F2F2),
                  child: Icon(
                    Icons.block,
                    color: Colors.black54,
                  ),
                ),
                title: Text(
                  user['name'] ?? 'Пользователь',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  user['city'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 13,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await ref
                        .read(safetyRepositoryProvider)
                        .unblockUser(user['blockId']);

                    ref.invalidate(blockedUsersProvider);
                  },
                  child: const Text(
                    'Разблокировать',
                    style: TextStyle(
                      color: pink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
