import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart'; // сгенерируется flutter gen-l10n

/// Достаёт локализованное значение поля бота/анкеты из Firestore.
///
/// Схема документа в коллекции users:
/// {
///   "name": "Алиса",            // значение по умолчанию (обычно ru)
///   "city": "Москва",
///   "bio":  "...",
///   "i18n": {
///     "en": { "name": "Alisa", "city": "Moscow", "bio": "..." },
///     "ru": { "name": "Алиса", "city": "Москва", "bio": "..." }
///   }
/// }
///
/// Порядок поиска: i18n[lang][field] → верхнеуровневое data[field] → ''.
/// Так живые пользователи (без i18n) продолжают работать как раньше,
/// а у ботов подтягивается перевод под язык интерфейса.
String localizedField(
  Map<String, dynamic> data,
  String field,
  String languageCode,
) {
  final i18n = data['i18n'];
  if (i18n is Map) {
    final byLang = i18n[languageCode];
    if (byLang is Map) {
      final value = byLang[field];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
  }
  final fallback = data[field];
  return fallback is String ? fallback : '';
}

/// Удобная обёртка: берёт язык из контекста (текущей локали приложения).
extension LocalizedDoc on BuildContext {
  String botField(Map<String, dynamic> data, String field) {
    final lang = AppLocalizations.of(this).localeName; // 'en' / 'ru'
    return localizedField(data, field, lang);
  }
}
