import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/app_localizations.dart';

/// Валидаторы полей и перевод ошибок Firebase Auth.
/// Возвращают null, если значение корректно, иначе локализованный текст.
/// У файла нет своего context, поэтому строки приходят через [l10n],
/// который экраны берут из AppLocalizations.of(context).

final RegExp _emailRegExp = RegExp(
  r'^[\w\.\-\+]+@([\w\-]+\.)+[A-Za-z]{2,}$',
);

String? validateEmail(String value, AppLocalizations l10n) {
  final v = value.trim();
  if (v.isEmpty) return l10n.validationEnterEmail;
  if (!_emailRegExp.hasMatch(v)) return l10n.validationInvalidEmail;
  return null;
}

String? validatePassword(String value, AppLocalizations l10n) {
  final v = value.trim();
  if (v.isEmpty) return l10n.validationEnterPassword;
  if (v.length < 6) return l10n.validationPasswordTooShort;
  return null;
}

String? validateName(String value, AppLocalizations l10n) {
  final v = value.trim();
  if (v.isEmpty) return l10n.validationEnterName;
  if (v.length < 2) return l10n.validationNameTooShort;
  return null;
}

/// Переводит исключение Firebase Auth в понятное пользователю сообщение.
String mapAuthError(Object error, AppLocalizations l10n) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return l10n.validationInvalidEmail;
      case 'user-not-found':
        return l10n.validationUserNotFound;
      case 'wrong-password':
        return l10n.validationWrongPassword;
      case 'invalid-credential':
        return l10n.validationInvalidCredentials;
      case 'user-disabled':
        return l10n.validationAccountDisabled;
      case 'email-already-in-use':
        return l10n.validationEmailInUse;
      case 'weak-password':
        return l10n.validationWeakPassword;
      case 'too-many-requests':
        return l10n.validationTooManyAttempts;
      case 'network-request-failed':
        return l10n.validationNoInternet;
      case 'operation-not-allowed':
        return l10n.validationMethodUnavailable;
      case 'channel-error':
        return l10n.validationRequestFailed;
      default:
        return l10n.validationAuthError;
    }
  }
  return l10n.validationSomethingWrong;
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
