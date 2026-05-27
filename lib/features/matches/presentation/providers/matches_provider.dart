import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/matches_repository.dart';

final matchesRepositoryProvider =
    Provider<MatchesRepository>((ref) {
  return MatchesRepository();
});

final myMatchesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .read(matchesRepositoryProvider)
      .getMyMatches();
});
