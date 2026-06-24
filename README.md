# 🎵 VK Z

> Flutter клиент для VK Музыки с красивым интерфейсом и поддержкой VK Микса

[![Flutter](https://img.shields.io/badge/Flutter-3.24-blue?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows-brightgreen)](https://github.com/yourusername/vk_z)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## 📸 Скриншоты

| Авторизация | Главный экран | Плеер | Микс |
|:-----------:|:-------------:|:-----:|:----:|
| VK ID OAuth | Треки, плейлисты, рекомендации | Полноэкранный плеер | Персональный микс |

---

## ✨ Возможности

- 🔐 **Авторизация через VK ID** — безопасный вход через WebView
- 🎵 **Мои треки** — список всех аудиозаписей
- 📋 **Плейлисты** — просмотр и прослушивание плейлистов
- 🔀 **VK Микс** — персональные рекомендации на главном экране
- 🔍 **Поиск** — поиск треков по названию
- 🎧 **Полноэкранный плеер** — с обложкой, прогресс-баром, управлением
- 📱 **Мини-плеер** — всегда под рукой внизу экрана
- ⏭️ **Очередь треков** — последовательное воспроизведение

---

[!Tip] А ещё, подпишись на нашу тележеньку, и не парься - t.me/vkzplayer


## 🚀 Быстрый старт

### 1. Клонирование

```bash
git clone https://github.com/yourusername/vk_z.git
cd vk_z
```

### 2. Установка зависимостей

```bash
flutter pub get
```

### 3. Запуск

```bash
flutter run
```

---

## 📦 Сборка

### Windows

```bash
flutter build windows --release
```

Или запусти скрипт: [`scripts/build_windows.bat`](scripts/build_windows.bat)

### Android (APK)

```bash
flutter build apk --release --split-per-abi
```

### Android (AppBundle)

```bash
flutter build appbundle --release
```

---

## 🤖 GitHub Actions (автосборка)

Workflow автоматически собирает приложение при пуше в `main` или при ручном запуске.

### 🔹 Ручной запуск

1. Перейди в **Actions** → **VK Music Build & Release**
2. Нажми **Run workflow**
3. Заполни параметры:

| Параметр | Описание | Пример |
|----------|----------|--------|
| `version_name` | Название версии | `v1.0.1` |
| `release_title` | Заголовок релиза | `VK Music v1.0.1` |
| `release_notes` | Что нового | `• Исправлены баги` |
| `release_type` | `prerelease` или `release` | `prerelease` |
| `send_telegram` | Отправить в Telegram? | `true` |

### 🔹 Что собирается

| Платформа | Формат | Файл |
|-----------|--------|------|
| 📱 Android | APK (ARM64) | `app-arm64-v8a-release.apk` |
| 📱 Android | APK (ARM32) | `app-armeabi-v7a-release.apk` |
| 📱 Android | APK (x86_64) | `app-x86_64-release.apk` |
| 📦 Android | AAB (Bundle) | `app-release.aab` |
| 🪟 Windows | ZIP архив | `vk_z_windows_*.zip` |

### 🔹 Настройка Telegram

Добавь **Secrets** в настройках репозитория:
- `Settings` → `Secrets and variables` → `Actions`
- `TELEGRAM_BOT_TOKEN` — токен бота от [@BotFather](https://t.me/BotFather)
- `TELEGRAM_CHAT_ID` — ID чата (можно узнать у [@userinfobot](https://t.me/userinfobot))

---

## 🗂 Структура проекта

```
lib/
├── main.dart                    # Точка входа
├── models/
│   ├── track.dart               # Модель трека
│   ├── playlist.dart            # Модель плейлиста
│   └── mix.dart                 # Модель VK Микса
├── services/
│   ├── vk_config.dart           # Конфигурация VK API
│   └── vk_api_service.dart      # VK API клиент
├── providers/
│   └── music_provider.dart      # State management (Provider)
├── screens/
│   ├── login_screen.dart        # Экран авторизации
│   ├── home_screen.dart         # Главный экран
│   ├── player_screen.dart       # Полноэкранный плеер
│   ├── mix_screen.dart          # Экран VK Микса
│   └── playlist_detail_screen.dart  # Детали плейлиста
└── widgets/
    ├── track_tile.dart          # Элемент трека
    ├── playlist_card.dart       # Карточка плейлиста
    └── mini_player.dart         # Мини-плеер
```

---

## 🛠 Технологии

| Технология | Назначение |
|-----------|------------|
| [Flutter](https://flutter.dev) | Фреймворк |
| [Provider](https://pub.dev/packages/provider) | State management |
| [webview_flutter](https://pub.dev/packages/webview_flutter) | VK OAuth |
| [http](https://pub.dev/packages/http) | HTTP клиент |
| [just_audio](https://pub.dev/packages/just_audio) | Аудиоплеер |
| [cached_network_image](https://pub.dev/packages/cached_network_image) | Кэширование обложек |
| [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) | Иконки приложения |

---

## 📄 Лицензия

MIT License. Подробнее в файле [LICENSE](LICENSE).

---

<div align="center">
  <sub>Сделано с ❤️ для VK Музыки</sub>
</div>
