import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // google_sign_in 7.x требует разовой инициализации до первого вызова.
  // На Web пропускаем (там вход идёт через FirebaseAuth.signInWithPopup),
  // иначе без clientId плагин зависает на пустом экране.
  if (!kIsWeb) {
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '536073911138-2hbulpjk9klvqavqe4m1d2nr12kbgfk0.apps.googleusercontent.com',
  );
}

  runApp(
    const ProviderScope(
      child: VelouraApp(),
    ),
  );
}