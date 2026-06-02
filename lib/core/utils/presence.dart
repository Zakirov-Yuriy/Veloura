import 'package:cloud_firestore/cloud_firestore.dart';

/// Сколько времени после последнего «удара пульса» пользователь
/// всё ещё считается онлайн. Должно быть заметно больше интервала
/// heartbeat (45 секунд), чтобы пропуск одного удара не «гасил» статус.
const presenceTimeout = Duration(minutes: 2);

/// Возвращает true, только если пользователь помечен онлайн И его
/// активность была недавно (lastSeen в пределах [presenceTimeout]).
///
/// Это защищает от «вечного онлайн», когда приложение закрыли, оно
/// упало или пропала сеть, и флаг isOnline не успел стать false.
bool isUserOnline(Map<String, dynamic>? user) {
  if (user == null) return false;
  if (user['isOnline'] != true) return false;

  final lastSeen = user['lastSeen'];
  if (lastSeen is! Timestamp) return false;

  final diff = DateTime.now().difference(lastSeen.toDate());
  return diff < presenceTimeout;
}