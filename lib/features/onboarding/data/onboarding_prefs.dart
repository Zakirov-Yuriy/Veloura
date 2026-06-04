import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранит флаг «онбординг уже показан» локально на устройстве.
/// Ключ привязан к uid, поэтому онбординг показывается ровно один раз
/// на каждый зарегистрированный аккаунт.
class OnboardingPrefs {
  const OnboardingPrefs._();

  static String _key(String uid) => 'onboarding_seen_$uid';

  /// Был ли онбординг уже пройден текущим пользователем.
  static Future<bool> isCompletedForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(uid)) ?? false;
  }

  /// Отметить онбординг пройденным для текущего пользователя.
  static Future<void> markCompletedForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(uid), true);
  }
}
