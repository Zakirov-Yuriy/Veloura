# Veloura

Многоплатформенное приложение для общения и поиска интересных людей с интеграцией Firebase и AI-ботов.

## Описание

Veloura — это Flutter приложение, которое предоставляет:
- Аутентификацию через Firebase
- Облачное хранилище данных (Firestore)
- Встроенных AI-ботов для взаимодействия
- Кроссплатформенную поддержку (iOS, Android, Web, Windows, macOS, Linux)

## Требования

### Для мобильной разработки
- **Flutter SDK**: 3.0.0 или выше
- **Dart SDK**: 3.0.0 или выше
- **Java Development Kit (JDK)**: 11 или выше
- **Android Studio** или **Xcode** (для iOS)
- **Node.js**: 16.0.0 или выше (для скриптов ботов)

### Для бэкенда (скрипты ботов)
- **Node.js**: 16.0.0 или выше
- **npm** или **yarn**
- Firebase Admin SDK ключ (JSON файл)
- OpenRouter API ключи

## Установка и запуск

### 1. Клонирование и подготовка

```bash
# Перейти в директорию проекта
cd C:\Users\zakco\VS Code\veloura

# Получить зависимости Flutter
flutter pub get

# Генерировать код для Firebase
dart run build_runner build
```

### 2. Запуск приложения

#### На Android
```bash
flutter run -d android
```

#### На iOS
```bash
flutter run -d ios
```

#### На Web
```bash
flutter run -d chrome
```

#### На Windows/macOS/Linux
```bash
flutter run -d windows    # или macos, linux
```

## Работа с ботами

### Переменные окружения

Перед запуском скриптов ботов установите переменную окружения с путем до Firebase Admin SDK ключа:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\zakco\OneDrive\Desktop\VOLE\veloura-21064-firebase-adminsdk-fbsvc-7a55998839.json"
```

### Создание ботов

Создаёт 200 новых ботов в базе данных:

```powershell
cd "C:\Users\zakco\VS Code\veloura\functions"
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\zakco\OneDrive\Desktop\VOLE\veloura-21064-firebase-adminsdk-fbsvc-7a55998839.json"
node seed_bots_bulk.js 200
```

### Улучшение фотографий ботов

Увеличивает качество фотографий ботов с помощью AI:

```powershell
cd "C:\Users\zakco\VS Code\veloura\functions"
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\zakco\OneDrive\Desktop\VOLE\veloura-21064-firebase-adminsdk-fbsvc-7a55998839.json"
node upscale_bot_photos.js
```

### Запуск воркера ботов

Запускает фоновый воркер для обработки сообщений и лайков:

```powershell
# Подготовка файла .env (замена ключа)
(Get-Content .env) -replace 'OPENROUTER_API_KEY=', 'OPENROUTER_API_KEYS=' | Set-Content .env

# Запуск воркера
cd "C:\Users\zakco\VS Code\veloura\functions"
node --env-file=.env bot_worker.js
```

**Ожидаемый результат:**
```
============================================================
Воркер ботов Veloura запущен
Модель: openai/gpt-oss-120b:free, ключей OpenRouter: 2
Слушаю likes и messages... (Ctrl+C для остановки)
============================================================
```

## Структура проекта

```
.
├── lib/                    # Исходный код Flutter
│   ├── main.dart          # Точка входа приложения
│   ├── app.dart           # Конфигурация приложения
│   ├── firebase_options.dart  # Настройки Firebase
│   ├── core/              # Основные классы и утилиты
│   ├── features/          # Функциональные модули
│   ├── screens/           # UI экраны
│   └── shared/            # Общие компоненты
├── android/               # Код для Android
├── ios/                   # Код для iOS
├── web/                   # Код для Web
├── windows/               # Код для Windows
├── macos/                 # Код для macOS
├── linux/                 # Код для Linux
├── functions/             # Node.js скрипты для ботов
│   ├── bot_worker.js     # Воркер ботов
│   ├── seed_bots.js      # Создание ботов
│   ├── seed_bots_bulk.js # Массовое создание ботов
│   ├── upscale_bot_photos.js  # Улучшение фото
│   └── package.json      # Зависимости Node.js
├── assets/                # Изображения, иконки, ресурсы
├── test/                  # Тесты
├── pubspec.yaml          # Зависимости Dart/Flutter
├── firebase.json         # Конфигурация Firebase
└── README.md             # Этот файл
```

## Основные зависимости

### Flutter
- **firebase_core** — инициализация Firebase
- **cloud_firestore** — база данных Firestore
- **firebase_auth** — аутентификация
- **firebase_messaging** — push-уведомления
- **google_sign_in** — вход через Google
- **image_picker** — выбор изображений
- **shared_preferences** — локальное хранилище

### Node.js
- **firebase-admin** — Firebase Admin SDK
- Другие зависимости указаны в `functions/package.json`

## Разработка

### Включение dev-режима
```bash
flutter run --debug
```

### Профилирование (Release режим)
```bash
flutter run --profile
```

### Production сборка
```bash
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
```

## Отладка

### Просмотр логов
```bash
flutter logs
```

### Подключение к DevTools
```bash
flutter pub global activate devtools
devtools
```

## Решение проблем

### Проблемы с зависимостями Flutter
```bash
flutter clean
flutter pub get
```

### Проблемы с Android
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Проблемы с iOS
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

## Документация

- [Flutter документация](https://docs.flutter.dev/)
- [Firebase документация](https://firebase.google.com/docs)
- [Dart документация](https://dart.dev/guides)

## Лицензия

Проприетарное приложение. Все права защищены.

---

**Последнее обновление:** 2026-06-11



создания ботов 

cd "C:\Users\zakco\VS Code\veloura\functions"
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\zakco\OneDrive\Desktop\VOLE\veloura-21064-firebase-adminsdk-fbsvc-7a55998839.json"
node seed_bots_bulk.js 200

улучшить фото ботов  

cd "C:\Users\zakco\VS Code\veloura\functions"
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\zakco\OneDrive\Desktop\VOLE\veloura-21064-firebase-adminsdk-fbsvc-7a55998839.json"
node upscale_bot_photos.js

запуск вокера  

(Get-Content .env) -replace 'OPENROUTER_API_KEY=', 'OPENROUTER_API_KEYS=' | Set-Content .env
node --env-file=.env bot_worker.js

ответ должен быть 
============================================================
Воркер ботов Veloura запущен
Модель: openai/gpt-oss-120b:free, ключей OpenRouter: 2
Слушаю likes и messages... (Ctrl+C для остановки)
============================================================

