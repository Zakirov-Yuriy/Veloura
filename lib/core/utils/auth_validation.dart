import 'package:firebase_auth/firebase_auth.dart';

/// Валидаторы полей и перевод ошибок Firebase Auth на русский.
/// Возвращают null, если значение корректно, иначе текст ошибки.

final RegExp _emailRegExp = RegExp(
  r'^[\w\.\-\+]+@([\w\-]+\.)+[A-Za-z]{2,}$',
);

String? validateEmail(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Введите email';
  if (!_emailRegExp.hasMatch(v)) return 'Некорректный email';
  return null;
}

String? validatePassword(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Введите пароль';
  if (v.length < 6) return 'Пароль должен быть не короче 6 символов';
  return null;
}

String? validateName(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Введите имя';
  if (v.length < 2) return 'Имя слишком короткое';
  return null;
}

/// Переводит исключение Firebase Auth в понятное пользователю сообщение.
String mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Некорректный email';
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неправильный пароль';
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'user-disabled':
        return 'Этот аккаунт заблокирован';
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'weak-password':
        return 'Слишком простой пароль, минимум 6 символов';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'network-request-failed':
        return 'Нет соединения с интернетом';
      case 'operation-not-allowed':
        return 'Этот способ входа сейчас недоступен';
      case 'channel-error':
        return 'Не удалось выполнить запрос. Проверьте данные и попробуйте снова';
      default:
        return 'Ошибка авторизации. Попробуйте ещё раз';
    }
  }
  return 'Что-то пошло не так. Попробуйте ещё раз';
}

/// Коды ошибок, которые логично показывать под полем email.
const emailErrorCodes = {
  'invalid-email',
  'user-not-found',
  'user-disabled',
  'email-already-in-use',
};

/// Коды ошибок, которые логично показывать под полем пароля.
const passwordErrorCodes = {
  'wrong-password',
  'weak-password',
  'invalid-credential',
};