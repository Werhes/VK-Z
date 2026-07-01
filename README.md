# VK Z — Музыкальный плеер ВКонтакте

**VK Z** — кроссплатформенное приложение для прослушивания музыки из ВКонтакте. Доступно для Android и iOS.

## Возможности

- 🎵 Прослушивание музыки из ВКонтакте
- 🔍 Поиск треков, альбомов и исполнителей
- 📂 Плейлисты и рекомендации
- 🎨 Material Design / iOS-native интерфейс
- 📱 Оптимизировано для Android и iOS
- 🔄 Автосборка через GitHub Actions

## Технологии

- **Платформа:** Xamarin.Android, Xamarin.iOS
- **API:** VkNet, VkNet.AudioBypassService
- **Плеер:** Plugin.MediaManager
- **Логирование:** NLog
- **Аналитика:** Microsoft AppCenter
- **CI/CD:** GitHub Actions

## Структура проекта

```
Werhes.Vkz.AndroidApp/          # Android-приложение
├── Activities/                  # Activity (экраны)
├── Adapters/                    # Адаптеры для списков
├── Converters/                  # Конвертеры данных
├── Models/                      # Модели данных
├── Resources/                   # Ресурсы (layout, drawable, etc.)
├── Services/                    # Сервисы (авторизация, плеер, etc.)
└── ViewHolders/                 # ViewHolder для списков

Werhes.Vkz.iOS/                  # iOS-приложение
├── Converters/                  # Конвертеры данных
├── Models/                      # Модели данных
├── Resources/                   # Ресурсы (storyboard, xcassets)
├── Services/                    # Сервисы (авторизация, плеер, etc.)
├── ViewControllers/             # ViewController (экраны)
└── Views/                       # Кастомные UI-элементы (ячейки, мини-плеер)

Werhes.Vkz.Core/                 # Общая библиотека
├── Interfaces/                  # Интерфейсы
├── Models/                      # Модели данных
├── VKontakte/                   # VK API клиент
└── LastFM/                      # Last.fm скробблинг
```

## Сборка

### Локальная сборка через PowerShell

```powershell
# Собрать Android
.\build.ps1 -Platform android -VersionName "1.0.0" -VersionCode 1 -ReleaseType prerelease

# Собрать iOS
.\build.ps1 -Platform ios -VersionName "1.0.0" -VersionCode 1 -ReleaseType prerelease

# Собрать всё сразу
.\build.ps1 -Platform both -VersionName "1.0.0" -VersionCode 1 -ReleaseType prerelease

# Собрать с описанием релиза и Telegram уведомлением
.\build.ps1 -Platform both -VersionName "1.0.0" -VersionCode 1 -ReleaseType release -ReleaseNotes "Исправлены баги, улучшена производительность" -TelegramBotToken "YOUR_BOT_TOKEN" -TelegramChatId "YOUR_CHAT_ID"
```

**Параметры:**
| Параметр | Описание |
|----------|----------|
| `-Platform` | Платформа: `android`, `ios`, `both` |
| `-VersionName` | Название версии (например, `1.0.0`) |
| `-VersionCode` | Код версии (число) |
| `-ReleaseNotes` | Описание релиза (опционально) |
| `-ReleaseType` | Тип: `release` или `prerelease` |
| `-Configuration` | Конфигурация: `Debug` или `Release` |
| `-TelegramBotToken` | Токен Telegram бота (опционально) |
| `-TelegramChatId` | ID чата Telegram (опционально) |

### Сборка в Visual Studio

1. Откройте `Werhes.Vkz.sln` в Visual Studio 2022+
2. Установите необходимые SDK (Xamarin.Android, Xamarin.iOS, .NET Framework)
3. Выберите конфигурацию **Debug** или **Release**
4. Соберите нужный проект (Werhes.Vkz.AndroidApp / Werhes.Vkz.iOS)

### Требования

- Visual Studio 2022 с рабочей нагрузкой **Mobile development with .NET (Xamarin)**
- Android SDK (API 28+)
- Xcode (для iOS сборки на macOS)
- .NET Framework 4.7.2+

## Автосборка (GitHub Actions)

При пуше в ветки `main`, `master` или `develop` автоматически запускается сборка Android.

### Ручной запуск сборки

1. Перейдите в **Actions** → **VK Z Full CI/CD**
2. Нажмите **Run workflow**
3. Заполните параметры:
   - **Version name** — название версии
   - **Version code** — код версии
   - **Release notes** — описание релиза
   - **Release type** — `release` или `prerelease`
   - **Build Android** / **Build iOS** — какие платформы собирать

### Настройка Telegram уведомлений

Для получения уведомлений в Telegram добавьте в **Settings → Secrets and variables → Actions**:

| Secret | Описание |
|--------|----------|
| `TELEGRAM_BOT_TOKEN` | Токен вашего Telegram бота (получить у [@BotFather](https://t.me/BotFather)) |
| `TELEGRAM_CHAT_ID` | ID чата для уведомлений (узнать у [@userinfobot](https://t.me/userinfobot)) |

После настройки при каждой сборке будет приходить уведомление с результатом.

## Лицензия

Проект распространяется под лицензией MIT.
