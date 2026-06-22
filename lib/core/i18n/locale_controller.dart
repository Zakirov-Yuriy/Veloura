import 'dart:ui' show PlatformDispatcher;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Языки, которые поддерживает приложение.
/// Чтобы добавить новый — добавьте Locale сюда и заведите app_<код>.arb.
const supportedLocales = <Locale>[
  Locale('ru'),
  Locale('en'),
];

/// Ключ хранения выбранного языка в shared_preferences.
/// Пусто/отсутствует → следуем за языком системы (телефона).
const _kLocalePrefKey = 'app_locale_code';

/// Состояние локали (Riverpod 3, Notifier API):
///  - null  → «как в телефоне» (системный язык)
///  - Locale('en') / Locale('ru') → ручной выбор пользователя.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    // Подтягиваем сохранённый выбор и синхронизируем язык в Firestore.
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocalePrefKey);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
    // При старте синхронизируем фактический язык с документом пользователя,
    // чтобы бот-воркер знал, на каком языке отвечать.
    _syncToFirestore(effectiveLocale.languageCode);
  }

  /// Фактически применяемый язык: ручной выбор либо язык системы,
  /// приведённый к ближайшему поддерживаемому (фолбэк — русский).
  Locale get effectiveLocale {
    final current = state;
    if (current != null) return current;
    final system = PlatformDispatcher.instance.locale;
    return supportedLocales.firstWhere(
      (l) => l.languageCode == system.languageCode,
      orElse: () => const Locale('ru'),
    );
  }

  /// Установить язык вручную. [locale] == null → вернуться к системному.
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_kLocalePrefKey);
    } else {
      await prefs.setString(_kLocalePrefKey, locale.languageCode);
    }
    _syncToFirestore(effectiveLocale.languageCode);
  }

  /// Пишем код языка в users/{uid}.language — это читает bot_worker.js,
  /// чтобы боты отвечали на нужном языке. Тихо игнорируем, если не вошли.
  Future<void> _syncToFirestore(String languageCode) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'language': languageCode}, SetOptions(merge: true));
    } catch (_) {
      // Сеть/права — не критично для UI, просто пропускаем.
    }
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
