# План миграции VK Z на WinUI 3

## Цель
Переписать Windows приложение VK Z с WPF на WinUI 3, сделав UI и авторизацию как в Music-M.

## Архитектура Music-M (для референса)

### Технологии
- **WinUI 3** (Microsoft.WindowsAppSDK 1.6)
- **.NET 8** (`net8.0-windows10.0.22000.0`)
- **VkNet.AudioBypassService** (локальный проект) — экосистемная авторизация VK
- **VkNet.Extensions.DependencyInjection** (локальный проект)
- **Microsoft.Extensions.DependencyInjection / Hosting**
- **NAudio** — аудиоплеер
- **FFmpegInteropX** — декодирование аудио

### Ключевые особенности UI Music-M
1. **DesktopAcrylicBackdrop** — акриловый фон (Mica/акрил)
2. **Кастомный TitleBar** — своя строка заголовка с кнопками навигации
3. **Навигация** — `NavMenuController` (кастомное боковое меню)
4. **Экосистемная авторизация VK** — `IVkApiAuthAsync.AuthorizeAsync(new AndroidApiAuthParams())` с выбором способа (push, sms, звонок, пароль, генератор кодов)
5. **Тёмная тема** — `Application.Current.RequestedTheme = ApplicationTheme.Dark`
6. **VK Sans Display шрифты** — Bold, DemiBold, Medium, Regular
7. **Акриловые кисти** — `AcrylicBrush` с настройками прозрачности

## План работ

### Этап 1: Создание проекта WinUI 3

**Файлы:**
- `windows/VKZ-WinUI/VKZ-WinUI.csproj` — новый проект WinUI 3
- `windows/VKZ-WinUI/App.xaml` + `App.xaml.cs` — точка входа с DI
- `windows/VKZ-WinUI/app.manifest` — манифест с Win11 поддержкой
- `windows/VKZ-WinUI/Package.appxmanifest` — для packaged сборки

**Ключевые настройки csproj:**
```xml
<TargetFramework>net8.0-windows10.0.22000.0</TargetFramework>
<UseWinUI>true</UseWinUI>
<WindowsAppSDKSelfContained>true</WindowsAppSDKSelfContained>
<WindowsPackageType>None</WindowsPackageType>
```

**NuGet пакеты:**
- `Microsoft.WindowsAppSDK` 1.6+
- `Microsoft.Windows.SDK.BuildTools`
- `Microsoft.Extensions.DependencyInjection`
- `Microsoft.Extensions.Hosting`
- `VkNet` 1.68.0 (NuGet)
- `VkNet.AudioBypassService` 1.7.2 (NuGet)
- `NAudio` 2.2.1
- `Newtonsoft.Json` 13.0.3

### Этап 2: Перенос сервисов

**Из WPF в WinUI (адаптация):**

| WPF (старый) | WinUI (новый) | Изменения |
|---|---|---|
| `VKApiService.cs` | `VKApiService.cs` | Адаптировать под DI (убрать Singleton.Instance) |
| `AudioPlayerService.cs` | `AudioPlayerService.cs` | NAudio остаётся, адаптировать под WinUI |
| `Settings.cs` | `SettingsService.cs` | Заменить `Properties.Settings` на `Microsoft.UI.Xaml.ApplicationData` или JSON-файл |
| `ValueConverters.cs` | `Converters/` | WinUI использует `Microsoft.UI.Xaml.Data.IValueConverter` |

**VKApiService — ключевые изменения:**
- Убрать `IVkApiInvoke` cast — Music-M использует `IVkApiCategories` напрямую
- Добавить экосистемную авторизацию через `IVkApiAuthAsync`
- Использовать DI: `IVkApi`, `IVkApiCategories`, `IVkApiInvoke` регистрируются через `AddVkNet()`

### Этап 3: Экосистемная авторизация VK

**Как в Music-M:**
```csharp
services.AddAudioBypass();
services.AddVkNet();
services.AddSingleton<IVkTokenStore, RegistryTokenStore>();
services.AddSingleton<IDeviceIdStore, RegistryTokenStore>();
services.AddSingleton<IExchangeTokenStore, RegistryTokenStore>();
```

**Авторизация:**
```csharp
await container.GetRequiredService<IVkApiAuthAsync>()
    .AuthorizeAsync(new AndroidApiAuthParams());
```

**AndroidApiAuthParams** — использует экосистемную авторизацию VK ID:
- Автоматически определяет доступные методы (push, sms, звонок, пароль, генератор кодов)
- Показывает UI для выбора метода
- Обрабатывает 2FA

**Нужно будет создать:**
- `Services/VkAuthService.cs` — обёртка над `IVkApiAuthAsync`
- `Views/LoginWindow/` — окно авторизации с выбором способа
- `Views/LoginWindow/LoginWayControl.xaml` — контрол для отображения способа входа

### Этап 4: UI — MainWindow

**Структура MainWindow (как в Music-M):**
```
Window
├── SystemBackdrop: DesktopAcrylicBackdrop
├── Grid
│   ├── Row 0: Custom TitleBar (30px)
│   │   ├── Back button
│   │   ├── Title
│   │   └── Drag region
│   ├── Row 1: Content (*)
│   │   ├── NavMenu (слева, 200px)
│   │   └── MainContent (справа)
│   │       ├── AuthView
│   │       ├── PlaylistsView
│   │       ├── SearchView
│   │       ├── MixView
│   │       └── PopularView
│   └── Row 2: MiniPlayer (Auto)
│       ├── Track info
│       ├── Controls (play/pause, prev, next)
│       └── Progress slider + volume
```

### Этап 5: UI — Страницы

**Каждая страница — UserControl WinUI:**
- `Views/PlaylistsPage.xaml` — список плейлистов (GridView с WrapLayout)
- `Views/SearchPage.xaml` — поиск с TextBox + результаты
- `Views/MixPage.xaml` — VK Mix карточки
- `Views/PopularPage.xaml` — популярные треки
- `Views/AuthPage.xaml` — авторизация (токен / экосистемная)

**Стилизация:**
- Тёмная тема: `#1A1B1E` фон, `#0077FF` акцент
- Шрифты VK Sans Display (Bold, Medium, Regular)
- Акриловые поверхности для карточек

### Этап 6: Аудиоплеер

**Перенос AudioPlayerService:**
- NAudio остаётся (MediaFoundationReader)
- Адаптировать события под WinUI `DispatcherQueue`
- Добавить `ITrackMediaSource` интерфейс (как в Music-M)

### Этап 7: Сборка и CI/CD

**Обновить `.github/workflows/ios-build.yml`:**
- Добавить шаг `windows-build-winui` или заменить существующий
- Установка WinAppSDK через NuGet
- `dotnet publish` с `-p:WindowsPackageType=None -p:WindowsAppSDKSelfContained=true`

## Структура нового проекта

```
windows/VKZ-WinUI/
├── VKZ-WinUI.csproj
├── App.xaml / App.xaml.cs
├── app.manifest
├── MainWindow.xaml / MainWindow.xaml.cs
├── Services/
│   ├── VKApiService.cs
│   ├── AudioPlayerService.cs
│   ├── SettingsService.cs
│   └── VkAuthService.cs
├── Models/
│   └── VKMusicModels.cs
├── Views/
│   ├── AuthPage.xaml / AuthPage.xaml.cs
│   ├── PlaylistsPage.xaml / PlaylistsPage.xaml.cs
│   ├── SearchPage.xaml / SearchPage.xaml.cs
│   ├── MixPage.xaml / MixPage.xaml.cs
│   ├── PopularPage.xaml / PopularPage.xaml.cs
│   └── LoginWindow/
│       ├── LoginWindow.xaml / LoginWindow.xaml.cs
│       └── LoginWayControl.xaml / LoginWayControl.xaml.cs
├── Converters/
│   └── ValueConverters.cs
├── Themes/
│   └── Generic.xaml
├── Fonts/
│   ├── VKSansDisplay-Bold.ttf
│   ├── VKSansDisplay-Medium.ttf
│   └── VKSansDisplay-Regular.ttf
└── Assets/
    └── icon.ico
```

## Todo List

- [ ] Создать проект WinUI 3 (`VKZ-WinUI.csproj`)
- [ ] Настроить `App.xaml` + `App.xaml.cs` с DI (VkNet, AudioBypass, сервисы)
- [ ] Перенести `VKApiService.cs` — адаптировать под DI и экосистемную авторизацию
- [ ] Перенести `AudioPlayerService.cs` — адаптировать под WinUI DispatcherQueue
- [ ] Создать `SettingsService.cs` — замена `Properties.Settings`
- [ ] Создать `VkAuthService.cs` — экосистемная авторизация VK
- [ ] Создать `MainWindow.xaml` + `.cs` — с акриловым фоном, кастомным TitleBar, навигацией
- [ ] Создать `AuthPage.xaml` + `.cs` — авторизация (токен + экосистемная)
- [ ] Создать `PlaylistsPage.xaml` + `.cs` — список плейлистов
- [ ] Создать `SearchPage.xaml` + `.cs` — поиск
- [ ] Создать `MixPage.xaml` + `.cs` — VK Mix
- [ ] Создать `PopularPage.xaml` + `.cs` — популярное
- [ ] Создать `LoginWindow/` — окно экосистемной авторизации
- [ ] Перенести конвертеры
- [ ] Добавить шрифты VK Sans Display
- [ ] Настроить тёмную тему и стили
- [ ] Обновить CI/CD для WinUI 3 сборки
- [ ] Удалить старый WPF проект (опционально)