import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/safety_repository.dart';

final safetyRepositoryProvider =
    Provider<SafetyRepository>((ref) {
  return SafetyRepository();
});

final blockedUsersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .read(safetyRepositoryProvider)
      .getBlockedUsers();
});

// Реактивный набор id заблокированных пользователей для фильтрации
// чатов и матчей.
final blockedUserIdsProvider = StreamProvider<Set<String>>((ref) {
  return ref.read(safetyRepositoryProvider).blockedUserIds();
});