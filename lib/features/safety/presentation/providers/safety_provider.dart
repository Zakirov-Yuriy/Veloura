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
