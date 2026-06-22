// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Veloura';

  @override
  String get online => 'Онлайн';

  @override
  String get offline => 'Не в сети';

  @override
  String get user => 'Пользователь';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get refresh => 'Обновить';

  @override
  String get search => 'Поиск';

  @override
  String get skip => 'Пропустить';

  @override
  String get like => 'Лайк';

  @override
  String get signIn => 'Войти';

  @override
  String get next => 'Далее';

  @override
  String get start => 'Начать';

  @override
  String get save => 'Сохранить';

  @override
  String get tryAgain => 'Попробуйте ещё раз';

  @override
  String get matchesTitle => 'Матчи';

  @override
  String get noMatchesYet => 'Матчей пока нет';

  @override
  String get newMatchTitle => 'У вас новый матч';

  @override
  String get noProfilesYet => 'Анкет пока нет';

  @override
  String get newMatchExcited => 'У вас новый матч 🔥';

  @override
  String get complaintSent => 'Жалоба отправлена';

  @override
  String get userBlocked => 'Пользователь заблокирован';

  @override
  String get profileTitle => 'Анкета';

  @override
  String get report => 'Пожаловаться';

  @override
  String get block => 'Заблокировать';

  @override
  String get chatsTitle => 'Чаты';

  @override
  String get noChatsYet => 'Чатов пока нет';

  @override
  String get deleteChatTitle => 'Удалить чат?';

  @override
  String get deleteChatBody =>
      'Чат исчезнет у вас. Если собеседник его не удалит — у него останется.';

  @override
  String deleteFailed(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String get typing => 'Печатает...';

  @override
  String get newMatchShort => 'Новый матч';

  @override
  String get yesterday => 'Вчера';

  @override
  String get weekdayMon => 'Пн';

  @override
  String get weekdayTue => 'Вт';

  @override
  String get weekdayWed => 'Ср';

  @override
  String get weekdayThu => 'Чт';

  @override
  String get weekdayFri => 'Пт';

  @override
  String get weekdaySat => 'Сб';

  @override
  String get weekdaySun => 'Вс';

  @override
  String get userNotFound => 'Пользователь не найден';

  @override
  String get profileNotFound => 'Профиль не найден';

  @override
  String get premiumAccount => 'Премиум аккаунт';

  @override
  String get myPhotos => 'Мои фото';

  @override
  String get favorites => 'Избранные';

  @override
  String get blockedUsers => 'Заблокированные';

  @override
  String get signOut => 'Выйти';

  @override
  String get likesCount => 'Лайков';

  @override
  String get matchesCount => 'Матчей';

  @override
  String get friendsCount => 'Друзей';

  @override
  String get welcomeBack => 'С возвращением!';

  @override
  String get gladToSeeYou => 'Мы рады видеть вас снова';

  @override
  String get emailOrPhone => 'Email или телефон';

  @override
  String get password => 'Пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get or => 'или';

  @override
  String get noAccount => 'Нет аккаунта? ';

  @override
  String get signUp => 'Зарегистрироваться';

  @override
  String get createAccount => 'Создайте аккаунт';

  @override
  String get startYourJourney => 'Начните своё путешествие';

  @override
  String get name => 'Имя';

  @override
  String get acceptTerms =>
      'Я принимаю условия использования и политику конфиденциальности';

  @override
  String get haveAccount => 'Уже есть аккаунт? ';

  @override
  String get resetSubtitle =>
      'Укажите email, и мы отправим ссылку для сброса пароля';

  @override
  String get sendLink => 'Отправить ссылку';

  @override
  String get rememberedPassword => 'Вспомнили пароль? ';

  @override
  String get checkEmailTitle => 'Проверьте почту';

  @override
  String checkEmailBody(String email) {
    return 'Если аккаунт с адресом $email существует, мы отправили на него письмо со ссылкой для сброса пароля. Не забудьте заглянуть в папку «Спам».';
  }

  @override
  String get backToSignIn => 'Вернуться ко входу';

  @override
  String get sendAgain => 'Отправить ещё раз';

  @override
  String get validationEnterEmail => 'Введите email';

  @override
  String get validationInvalidEmail => 'Некорректный email';

  @override
  String get validationEnterPassword => 'Введите пароль';

  @override
  String get validationPasswordTooShort =>
      'Пароль должен быть не короче 6 символов';

  @override
  String get validationEnterName => 'Введите имя';

  @override
  String get validationNameTooShort => 'Имя слишком короткое';

  @override
  String get validationUserNotFound => 'Пользователь с таким email не найден';

  @override
  String get validationWrongPassword => 'Неправильный пароль';

  @override
  String get validationInvalidCredentials => 'Неверный email или пароль';

  @override
  String get validationAccountDisabled => 'Этот аккаунт заблокирован';

  @override
  String get validationEmailInUse => 'Этот email уже зарегистрирован';

  @override
  String get validationWeakPassword =>
      'Слишком простой пароль, минимум 6 символов';

  @override
  String get validationTooManyAttempts =>
      'Слишком много попыток. Попробуйте позже';

  @override
  String get validationNoInternet => 'Нет соединения с интернетом';

  @override
  String get validationMethodUnavailable =>
      'Этот способ входа сейчас недоступен';

  @override
  String get validationRequestFailed =>
      'Не удалось выполнить запрос. Проверьте данные и попробуйте снова';

  @override
  String get validationAuthError => 'Ошибка авторизации. Попробуйте ещё раз';

  @override
  String get validationSomethingWrong =>
      'Что-то пошло не так. Попробуйте ещё раз';

  @override
  String get onboard1Title => 'Премиальные знакомства';

  @override
  String get onboard1Body => 'Мы создаём пространство для успешных людей';

  @override
  String get onboard2Title => 'Безопасность и приватность';

  @override
  String get onboard2Body =>
      'Мы проверяем каждый профиль для вашего спокойствия';

  @override
  String get onboard3Title => 'Качество превыше всего';

  @override
  String get onboard3Body => 'Только реальные люди и настоящие знакомства';

  @override
  String get myProfile => 'Мой профиль';

  @override
  String get photos => 'Фотографии';

  @override
  String get nameCaps => 'ИМЯ';

  @override
  String get ageCaps => 'ВОЗРАСТ';

  @override
  String get ageField => 'Возраст';

  @override
  String get gender => 'Пол';

  @override
  String get male => 'Мужчина';

  @override
  String get female => 'Женщина';

  @override
  String get lookingForCaps => 'ИЩУ';

  @override
  String get lookingForField => 'Кого ищу';

  @override
  String get manAccusative => 'Мужчину';

  @override
  String get womanAccusative => 'Женщину';

  @override
  String get partnerAgeCaps => 'ВОЗРАСТ ПАРТНЁРА';

  @override
  String get yourCityCaps => 'ВАШ ГОРОД';

  @override
  String get cityField => 'Город';

  @override
  String get aboutCaps => 'О СЕБЕ';

  @override
  String get aboutField => 'О себе';

  @override
  String get saveProfile => 'Сохранить профиль';

  @override
  String get blockedTitle => 'Заблокированные';

  @override
  String get noBlockedUsers => 'Заблокированных пользователей нет';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get splashTagline => 'найди свою половину';

  @override
  String get iAmCaps => 'Я';

  @override
  String get copy => 'Копировать';

  @override
  String get copied => 'Скопировано';

  @override
  String get deleteMessageTitle => 'Удалить сообщение?';

  @override
  String get deleteMessageBody =>
      'Сообщение будет удалено без возможности восстановления.';

  @override
  String get photoFromGallery => 'Фото из галереи';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get videoFromGallery => 'Видео из галереи';

  @override
  String get videoTooLarge => 'Видео слишком большое (максимум ~95 МБ)';

  @override
  String sendFailed(String error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String sendVoiceFailed(String error) {
    return 'Не удалось отправить голосовое: $error';
  }

  @override
  String get today => 'Сегодня';

  @override
  String get chatTitle => 'Чат';

  @override
  String get writeFirstMessage => 'Напишите первое сообщение';

  @override
  String get noMicAccess => 'Нет доступа к микрофону';

  @override
  String get recordingTooShort => 'Слишком короткая запись';

  @override
  String get messageHint => 'Сообщение';

  @override
  String get recording => 'Идёт запись…';

  @override
  String get voiceLoadFailed => 'Не удалось загрузить голосовое';

  @override
  String get month1 => 'января';

  @override
  String get month2 => 'февраля';

  @override
  String get month3 => 'марта';

  @override
  String get month4 => 'апреля';

  @override
  String get month5 => 'мая';

  @override
  String get month6 => 'июня';

  @override
  String get month7 => 'июля';

  @override
  String get month8 => 'августа';

  @override
  String get month9 => 'сентября';

  @override
  String get month10 => 'октября';

  @override
  String get month11 => 'ноября';

  @override
  String get month12 => 'декабря';
}
