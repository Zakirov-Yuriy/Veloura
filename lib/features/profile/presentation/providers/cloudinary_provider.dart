import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloudinary_service.dart';

final cloudinaryServiceProvider =
    Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});