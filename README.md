# VK Z

**VK Z** — кроссплатформенный клиент музыки ВКонтакте без ограничений. Доступен на iOS, Android и Windows.

## Возможности

- 🎵 **Прослушивание музыки** — все аудиозаписи пользователя
- 📋 **Плейлисты** — просмотр и прослушивание плейлистов
- 🔍 **Поиск** — поиск по каталогу VK
- 🔥 **Популярное** — чарты и рекомендации
- 🎛 **VK Mix** — умные миксы на основе треков
- 📱 **Кроссплатформенность** — единый код для iOS, Android и Windows
- 🎨 **Тёмная тема** — стильный дизайн в тёмных тонах

## Авторизация

Приложение поддерживает два способа входа:

### 1. По токену
- **Через OAuth WebView** — стандартная авторизация через браузер VK
- **Ручной ввод токена** — для продвинутых пользователей

### 2. По номеру телефона
- Ввод номера телефона и пароля
- Поддержка двухфакторной авторизации (2FA)
- Используется `auth.login` API с `client_secret` (как в Kate Mobile)

> **Важно**: Вход по телефону работает через API VK с использованием `client_id` и `client_secret` приложения Kate Mobile. VK может блокировать такие запросы — в этом случае используйте вход по токену.

## Платформы

### iOS
- **Язык**: Swift 5.9+
- **Фреймворк**: SwiftUI + UIKit (WKWebView)
- **Минимальная версия**: iOS 17.0
- **Зависимости**: Alamofire, Kingfisher, JWTDecode
- **Сборка**: Xcode 15+

### Android
- **Язык**: Kotlin
- **Фреймворк**: Jetpack Compose
- **Минимальная версия**: Android 7.0 (API 24)
- **Зависимости**: Retrofit, OkHttp, Coil, Accompanist WebView
- **Сборка**: Android Studio Hedgehog+


## Сборка

### iOS

```bash
# Открыть проект в Xcode
open VK-Z/Package.swift

# Или собрать через xcodebuild
xcodebuild -scheme VK-Z -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Android

```bash
cd android
./gradlew assembleDebug
```


## CI/CD

Проект использует GitHub Actions для автоматической сборки всех платформ:

- **iOS** — macOS runner, сборка через xcodebuild
- **Android** — ubuntu runner, сборка через Gradle

### Запуск вручную

1. Перейти в **Actions** → **Build VK Z**
2. Нажать **Run workflow**
3. Заполнить параметры:
   - `namevers` — версия сборки (например, `1.0.0`)
   - `descr` — описание релиза
   - `release` — создать релиз (`true`/`false`)
   - `prerelease` — пререлиз (`true`/`false`)

## Структура проекта

```
VK-Z/
├── VK-Z/                    # iOS приложение (SwiftUI)
│   ├── Models/              # Модели данных
│   ├── Services/            # API сервис, аудио плеер
│   ├── Views/               # Экраны (Auth, Player, Search, Playlists, Mix)
│   └── Resources/           # Ресурсы (иконки, Info.plist)
├── android/                 # Android приложение (Kotlin + Compose)
│   └── app/src/main/java/com/werhes/vkz/
│       ├── data/api/        # API сервис, AuthManager
│       ├── data/model/      # Модели данных
│       ├── ui/screens/      # Экраны (Auth, Player, Search, Playlists, Mix)
│       └── ui/theme/        # Тёмная тема
```

## Технические детали

### VK API
- Используется VK API версии 5.199
- На iOS/Android — прямые HTTP-запросы к `api.vk.com/method/`
- Аутентификация через OAuth 2.0 (Implicit Flow) или `auth.login` с `client_secret`

### Аудио плеер
- **iOS**: AVAudioPlayer + AVPlayer
- **Android**: MediaPlayer (ExoPlayer)

### Дизайн
- Тёмная тема: `#1A1B1E` фон, `#0077FF` акцент, `#232529` поверхности

## Лицензия

MIT License

## Автор

**Werhes** — VK Z Project
