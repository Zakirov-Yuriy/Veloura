import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/home_repository.dart';

final homeRepositoryProvider =
    Provider<HomeRepository>((ref) {
  return HomeRepository();
});

final profilesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(homeRepositoryProvider).getProfiles();
});