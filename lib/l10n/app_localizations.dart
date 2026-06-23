import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @general_yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get general_yes;

  /// No description provided for @general_no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get general_no;

  /// No description provided for @general_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get general_save;

  /// No description provided for @general_reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get general_reset;

  /// No description provided for @general_clear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get general_clear;

  /// No description provided for @general_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get general_cancel;

  /// No description provided for @general_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get general_close;

  /// No description provided for @general_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get general_loading;

  /// No description provided for @general_restore.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть'**
  String get general_restore;

  /// No description provided for @general_continue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get general_continue;

  /// No description provided for @general_shuffle.
  ///
  /// In ru, this message translates to:
  /// **'Перемешать'**
  String get general_shuffle;

  /// No description provided for @general_play.
  ///
  /// In ru, this message translates to:
  /// **'Воспроизвести'**
  String get general_play;

  /// No description provided for @general_pause.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get general_pause;

  /// No description provided for @general_resume.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get general_resume;

  /// No description provided for @general_enable.
  ///
  /// In ru, this message translates to:
  /// **'Включить'**
  String get general_enable;

  /// No description provided for @general_edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get general_edit;

  /// No description provided for @general_logout.
  ///
  /// In ru, this message translates to:
  /// **'Выход'**
  String get general_logout;

  /// No description provided for @general_exit.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get general_exit;

  /// No description provided for @general_title.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get general_title;

  /// No description provided for @general_artist.
  ///
  /// In ru, this message translates to:
  /// **'Исполнитель'**
  String get general_artist;

  /// No description provided for @general_genre.
  ///
  /// In ru, this message translates to:
  /// **'Жанр'**
  String get general_genre;

  /// No description provided for @general_share.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get general_share;

  /// No description provided for @general_nothing_found.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get general_nothing_found;

  /// No description provided for @general_copy_to_downloads.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать в «Загрузки»'**
  String get general_copy_to_downloads;

  /// No description provided for @general_open_folder.
  ///
  /// In ru, this message translates to:
  /// **'Открыть папку'**
  String get general_open_folder;

  /// No description provided for @general_select.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get general_select;

  /// No description provided for @general_details.
  ///
  /// In ru, this message translates to:
  /// **'Подробности'**
  String get general_details;

  /// No description provided for @general_install.
  ///
  /// In ru, this message translates to:
  /// **'Установить'**
  String get general_install;

  /// No description provided for @general_show.
  ///
  /// In ru, this message translates to:
  /// **'Показать'**
  String get general_show;

  /// No description provided for @general_settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get general_settings;

  /// No description provided for @general_filesize_mb.
  ///
  /// In ru, this message translates to:
  /// **'{value} МБ'**
  String general_filesize_mb({required int value});

  /// No description provided for @general_filesize_gb.
  ///
  /// In ru, this message translates to:
  /// **'{value} ГБ'**
  String general_filesize_gb({required double value});

  /// No description provided for @general_favorites_playlist.
  ///
  /// In ru, this message translates to:
  /// **'Любимая музыка'**
  String get general_favorites_playlist;

  /// No description provided for @general_search_playlist.
  ///
  /// In ru, this message translates to:
  /// **'Музыка из результатов поиска'**
  String get general_search_playlist;

  /// No description provided for @general_owned_playlist.
  ///
  /// In ru, this message translates to:
  /// **'Ваш плейлист'**
  String get general_owned_playlist;

  /// No description provided for @general_saved_playlist.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённый плейлист'**
  String get general_saved_playlist;

  /// No description provided for @general_recommended_playlist.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемый плейлист'**
  String get general_recommended_playlist;

  /// No description provided for @general_audios_count.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} трек} few{{count} трека} other{{count} треков}}'**
  String general_audios_count({required int count});

  /// No description provided for @dislike_track_action.
  ///
  /// In ru, this message translates to:
  /// **'Не нравится'**
  String get dislike_track_action;

  /// No description provided for @enable_shuffle_action.
  ///
  /// In ru, this message translates to:
  /// **'Включить перемешку'**
  String get enable_shuffle_action;

  /// No description provided for @disable_shuffle_action.
  ///
  /// In ru, this message translates to:
  /// **'Выключить перемешку'**
  String get disable_shuffle_action;

  /// No description provided for @previous_track_action.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий'**
  String get previous_track_action;

  /// No description provided for @play_track_action.
  ///
  /// In ru, this message translates to:
  /// **'Воспроизвести'**
  String get play_track_action;

  /// No description provided for @pause_track_action.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get pause_track_action;

  /// No description provided for @next_track_action.
  ///
  /// In ru, this message translates to:
  /// **'Следующий'**
  String get next_track_action;

  /// No description provided for @enable_repeat_action.
  ///
  /// In ru, this message translates to:
  /// **'Включить повтор'**
  String get enable_repeat_action;

  /// No description provided for @disable_repeat_action.
  ///
  /// In ru, this message translates to:
  /// **'Выключить повтор'**
  String get disable_repeat_action;

  /// No description provided for @favorite_track_action.
  ///
  /// In ru, this message translates to:
  /// **'Нравится'**
  String get favorite_track_action;

  /// No description provided for @remove_favorite_track_action.
  ///
  /// In ru, this message translates to:
  /// **'Не нравится'**
  String get remove_favorite_track_action;

  /// No description provided for @not_yet_implemented.
  ///
  /// In ru, this message translates to:
  /// **'Не реализовано'**
  String get not_yet_implemented;

  /// No description provided for @not_yet_implemented_desc.
  ///
  /// In ru, this message translates to:
  /// **'Данный функционал ещё не был реализован. Пожалуйста, ожидайте обновлений приложения в будущем!'**
  String get not_yet_implemented_desc;

  /// No description provided for @error_dialog.
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка'**
  String get error_dialog;

  /// No description provided for @error_dialog_desc.
  ///
  /// In ru, this message translates to:
  /// **'Что-то очень сильно пошло не так. Что-то поломалось. Всё очень плохо.'**
  String get error_dialog_desc;

  /// No description provided for @player_playback_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка воспроизведения: {error}'**
  String player_playback_error({required String error});

  /// No description provided for @player_playback_error_stopped.
  ///
  /// In ru, this message translates to:
  /// **'Воспроизведение остановлено ввиду большого количества ошибок: {error}'**
  String player_playback_error_stopped({required String error});

  /// No description provided for @track_added_to_queue.
  ///
  /// In ru, this message translates to:
  /// **'Трек добавлен в очередь.'**
  String get track_added_to_queue;

  /// No description provided for @app_restart_required.
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, перезагрузите приложение.'**
  String get app_restart_required;

  /// No description provided for @option_unavailable_with_light_theme.
  ///
  /// In ru, this message translates to:
  /// **'Эта опция недоступна, поскольку сейчас используется светлая тема.'**
  String get option_unavailable_with_light_theme;

  /// No description provided for @option_unavailable_without_recommendations.
  ///
  /// In ru, this message translates to:
  /// **'Настройка недоступна, поскольку у Вас не подключены рекомендации ВКонтакте.'**
  String get option_unavailable_without_recommendations;

  /// No description provided for @option_unavailable_without_audio_playing.
  ///
  /// In ru, this message translates to:
  /// **'Изменения данной настройки не будут видны сейчас, поскольку Вы не запустили воспроизведение музыки.'**
  String get option_unavailable_without_audio_playing;

  /// No description provided for @thumbnails_unavailable_without_recommendations.
  ///
  /// In ru, this message translates to:
  /// **'Вы не видите обложек треков, поскольку у Вас не подключены рекомендации ВКонтакте.'**
  String get thumbnails_unavailable_without_recommendations;

  /// No description provided for @app_minimized_message.
  ///
  /// In ru, this message translates to:
  /// **'VK Z свернулся.\nВоспользуйтесь треем или откройте приложение ещё раз, чтобы вернуть окошко.'**
  String get app_minimized_message;

  /// No description provided for @tray_show_hide.
  ///
  /// In ru, this message translates to:
  /// **'Открыть/Свернуть'**
  String get tray_show_hide;

  /// Описание README-файла, поясняющий почему в папке с загруженными треками используется такая структура файлов, а так же напоминание того, что делиться загруженными треками нельзя.
  ///
  /// In ru, this message translates to:
  /// **'Хей-хей-хей! А ну, постой! 🤚\n\nДа, в этой папке хранятся загруженные приложением «VK Z» треки.\nЕсли ты обратил внимание, эти треки сохранены в очень необычном формате, и на то есть причина.\nЯ, разработчик приложения, не хочу, чтобы пользователи (вроде тебя!) могли легко получить доступ к этим трекам.\n\nЕсли ты сильно постараешься, рано или поздно найдешь нужный трек. Однако я бы предпочел, чтобы ты этого не делал.\nЕсли выяснится, что кто-то использует приложение для загрузки треков, мне придется добавить дополнительные уровни обфускации или шифрования, вроде AES.\n\nПожалуйста, уважай труд исполнителей, которые вкладывают много времени в создание своих треков. Распространяя их таким образом, ты наносишь им серьёзный вред.\nЕсли ты все же решишь распространять треки в виде .mp3-файлов, то, по крайней мере, делай это без корыстных целей, только для личного использования.\n\nСпасибо за внимание, fren :)'**
  String get music_readme_contents;

  /// No description provided for @internet_required_title.
  ///
  /// In ru, this message translates to:
  /// **'Нет подключения'**
  String get internet_required_title;

  /// No description provided for @internet_required_desc.
  ///
  /// In ru, this message translates to:
  /// **'Данное действие можно выполнить лишь при подключении к интернету. Пожалуйста, подключитесь к сети и попробуйте ещё раз.'**
  String get internet_required_desc;

  /// No description provided for @demo_mode_enabled_title.
  ///
  /// In ru, this message translates to:
  /// **'Недоступно в демо-версии'**
  String get demo_mode_enabled_title;

  /// No description provided for @demo_mode_enabled_desc.
  ///
  /// In ru, this message translates to:
  /// **'Данный функционал недоступен в демо-версии VK Z.\nВы можете загрузить полноценную версию приложение, перейдя в «профиль».'**
  String get demo_mode_enabled_desc;

  /// No description provided for @prerelease_app_version_warning.
  ///
  /// In ru, this message translates to:
  /// **'Бета-версия'**
  String get prerelease_app_version_warning;

  /// No description provided for @prerelease_app_version_warning_desc.
  ///
  /// In ru, this message translates to:
  /// **'Тс-с-с! Вы ступили на опасную территорию, установив бета-версию VK Z. Бета-версии менее стабильны, и обычным пользователям устанавливать их не рекомендуется.\n\nПродолжая, Вы осознаёте риски использования бета-версии приложения, в ином случае Вас может скушать дракоша.\nДанное уведомление будет показано только один раз.'**
  String get prerelease_app_version_warning_desc;

  /// No description provided for @demo_mode_welcome_warning.
  ///
  /// In ru, this message translates to:
  /// **'Демо-версия'**
  String get demo_mode_welcome_warning;

  /// No description provided for @demo_mode_welcome_warning_desc.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать в демо-версию VK Z! Здесь вы можете ознакомиться с основными возможностями приложения.\n\nВ полной версии будут доступны: авторизация во ВКонтакте, прослушивание рекомендаций, скачивание плейлистов и многое другое.\n\nДля загрузки полной версии перейдите в «профиль».'**
  String get demo_mode_welcome_warning_desc;

  /// No description provided for @welcome_title.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать! 😎'**
  String get welcome_title;

  /// <bold>...</bold> делает текст жирным, а <link>...</link> превращает текст внутри в ссылку на репозиторий проекта.
  ///
  /// In ru, this message translates to:
  /// **'<bold>VK Z</bold> — это экспериментальный неофициальный клиент ВКонтакте, построенный при помощи фреймворка Flutter с <link>открытым исходным кодом</link> для прослушивания музыки без необходимости приобретать подписку VK Music.'**
  String get welcome_desc;

  /// No description provided for @login_title.
  ///
  /// In ru, this message translates to:
  /// **'Авторизация'**
  String get login_title;

  /// <link>...</link> превращает текст внутри в ссылку на страницу с авторизацией.
  ///
  /// In ru, this message translates to:
  /// **'Для авторизации <link>🔗 перейдите по ссылке</link> и предоставьте приложению доступ к аккаунту ВКонтакте.\nНажав на «разрешить», скопируйте адрес сайта из адресной строки браузера и вставьте в поле ниже:'**
  String get login_desktop_desc;

  /// No description provided for @login_connect_recommendations_title.
  ///
  /// In ru, this message translates to:
  /// **'Подключение рекомендаций'**
  String get login_connect_recommendations_title;

  /// <link>...</link> превращает текст внутри в ссылку на страницу с авторизацией.
  ///
  /// In ru, this message translates to:
  /// **'Для подключения рекомендаций <link>🔗 перейдите по ссылке</link> и предоставьте приложению доступ к аккаунту ВКонтакте.\nНажав на «разрешить», скопируйте адрес сайта из адресной строки браузера и вставьте в поле ниже:'**
  String get login_connect_recommendations_desc;

  /// No description provided for @login_authorize.
  ///
  /// In ru, this message translates to:
  /// **'Авторизоваться'**
  String get login_authorize;

  /// No description provided for @login_mobile_alternate_auth.
  ///
  /// In ru, this message translates to:
  /// **'Альтернативный метод авторизации'**
  String get login_mobile_alternate_auth;

  /// No description provided for @login_no_token_error.
  ///
  /// In ru, this message translates to:
  /// **'Access-токен не был найден в переданной ссылке.'**
  String get login_no_token_error;

  /// No description provided for @login_no_music_access_desc.
  ///
  /// In ru, this message translates to:
  /// **'VK Z не смог получить доступ к специальным разделам музыки, необходимых для функционирования приложения.\nЧаще всего, такая ошибка происходит в случае, если Вы по-ошибке попытались авторизоваться при помощи приложения Kate Mobile вместо приложения VK Admin.\n\nПожалуйста, внимательно проследуйте инструкциям для авторизации, и попробуйте снова.'**
  String get login_no_music_access_desc;

  /// No description provided for @login_wrong_user_id.
  ///
  /// In ru, this message translates to:
  /// **'VK Z обнаружил, что Вы подключили другую страницу ВКонтакте, которая отличается от той, которая подключена сейчас.\nПожалуйста, авторизуйтесь как {name} во ВКонтакте и попробуйте снова.'**
  String login_wrong_user_id({required String name});

  /// No description provided for @login_success_auth.
  ///
  /// In ru, this message translates to:
  /// **'Авторизация успешна!'**
  String get login_success_auth;

  /// No description provided for @music_label.
  ///
  /// In ru, this message translates to:
  /// **'Музыка'**
  String get music_label;

  /// No description provided for @music_label_offline.
  ///
  /// In ru, this message translates to:
  /// **'Музыка (оффлайн)'**
  String get music_label_offline;

  /// No description provided for @search_label.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get search_label;

  /// No description provided for @search_label_offline.
  ///
  /// In ru, this message translates to:
  /// **'Поиск (оффлайн)'**
  String get search_label_offline;

  /// No description provided for @music_library_label.
  ///
  /// In ru, this message translates to:
  /// **'Библиотека'**
  String get music_library_label;

  /// No description provided for @profile_label.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile_label;

  /// No description provided for @profile_labelOffline.
  ///
  /// In ru, this message translates to:
  /// **'Профиль (оффлайн)'**
  String get profile_labelOffline;

  /// No description provided for @downloads_label.
  ///
  /// In ru, this message translates to:
  /// **'Загрузки'**
  String get downloads_label;

  /// No description provided for @downloads_label_offline.
  ///
  /// In ru, this message translates to:
  /// **'Загрузки (оффлайн)'**
  String get downloads_label_offline;

  /// No description provided for @music_welcome_title.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать, {name}! 👋'**
  String music_welcome_title({required String name});

  /// No description provided for @category_closed.
  ///
  /// In ru, this message translates to:
  /// **'Вы закрыли раздел «{category}». Вы можете вернуть его, нажав на кнопку в «активных разделах».'**
  String category_closed({required String category});

  /// No description provided for @my_music_chip.
  ///
  /// In ru, this message translates to:
  /// **'Моя музыка'**
  String get my_music_chip;

  /// No description provided for @my_playlists_chip.
  ///
  /// In ru, this message translates to:
  /// **'Ваши плейлисты'**
  String get my_playlists_chip;

  /// No description provided for @realtime_playlists_chip.
  ///
  /// In ru, this message translates to:
  /// **'В реальном времени'**
  String get realtime_playlists_chip;

  /// No description provided for @vk_mix_chip.
  ///
  /// In ru, this message translates to:
  /// **'VK Mix'**
  String get vk_mix_chip;

  /// No description provided for @recommended_playlists_chip.
  ///
  /// In ru, this message translates to:
  /// **'Плейлисты для Вас'**
  String get recommended_playlists_chip;

  /// No description provided for @simillar_music_chip.
  ///
  /// In ru, this message translates to:
  /// **'Совпадения по вкусам'**
  String get simillar_music_chip;

  /// No description provided for @by_vk_chip.
  ///
  /// In ru, this message translates to:
  /// **'Собрано редакцией'**
  String get by_vk_chip;

  /// No description provided for @connect_recommendations_chip.
  ///
  /// In ru, this message translates to:
  /// **'Подключить рекомендации ВКонтакте'**
  String get connect_recommendations_chip;

  /// No description provided for @connect_recommendations_title.
  ///
  /// In ru, this message translates to:
  /// **'Подключение рекомендаций'**
  String get connect_recommendations_title;

  /// No description provided for @connect_recommendations_desc.
  ///
  /// In ru, this message translates to:
  /// **'Подключив рекомендации, Вы получите доступ к разделам музыки «Плейлисты для Вас», «VK Mix» и другие, а так же Вы начнёте видеть обложки треков.\n\nДля подключения рекомендаций, Вам будет необходимо повторно авторизоваться.'**
  String get connect_recommendations_desc;

  /// No description provided for @all_tracks.
  ///
  /// In ru, this message translates to:
  /// **'Все треки'**
  String get all_tracks;

  /// No description provided for @track_unavailable_offline_title.
  ///
  /// In ru, this message translates to:
  /// **'Трек недоступен оффлайн'**
  String get track_unavailable_offline_title;

  /// No description provided for @track_unavailable_offline_desc.
  ///
  /// In ru, this message translates to:
  /// **'Вы не можете прослушать данный трек в оффлайн-режиме, поскольку Вы не загрузили его ранее.'**
  String get track_unavailable_offline_desc;

  /// No description provided for @track_restricted_title.
  ///
  /// In ru, this message translates to:
  /// **'Аудиозапись недоступна'**
  String get track_restricted_title;

  /// No description provided for @track_restricted_desc.
  ///
  /// In ru, this message translates to:
  /// **'Сервера ВКонтакте сообщили, что эта аудиозапись недоступна. Вероятнее всего, так решил исполнитель трека либо его лейбл.\nПоскольку Вы не загрузили этот трек ранее, воспроизведение невозможно.\n\nВоспользуйтесь опцией «локальная замена трека» при наличии загруженного аудио в формате .mp3.'**
  String get track_restricted_desc;

  /// No description provided for @search_tracks_in_playlist.
  ///
  /// In ru, this message translates to:
  /// **'Поиск среди {count, plural, one{{count} трека} other{{count} треков}} здесь'**
  String search_tracks_in_playlist({required int count});

  /// No description provided for @playlist_is_empty.
  ///
  /// In ru, this message translates to:
  /// **'В данном плейлисте пусто.'**
  String get playlist_is_empty;

  /// <click>...</click> очищает результаты поиска.
  ///
  /// In ru, this message translates to:
  /// **'По Вашему запросу ничего не найдено. Попробуйте <click>очистить свой запрос</click>.'**
  String get playlist_search_zero_results;

  /// No description provided for @enable_download_title.
  ///
  /// In ru, this message translates to:
  /// **'Включение загрузки треков'**
  String get enable_download_title;

  /// No description provided for @enable_download_desc.
  ///
  /// In ru, this message translates to:
  /// **'Включив загрузку треков, VK Z будет автоматически загружать все треки в данном плейлисте, делая их доступных для прослушивания даже оффлайн, а так же после удаления правообладателем.\n\nПродолжив, будет {count, plural, one{загружен {count} трек} few{загружено {count} трека} other{загружено {count} треков}}, что потребует ~{downloadSize} интернет трафика.\nПожалуйста, не запускайте этот процесс, если у Вас лимитированный интернет.'**
  String enable_download_desc(
      {required int count, required String downloadSize});

  /// No description provided for @disable_download_title.
  ///
  /// In ru, this message translates to:
  /// **'Удаление загруженных треков'**
  String get disable_download_title;

  /// No description provided for @disable_download_desc.
  ///
  /// In ru, this message translates to:
  /// **'Очистив загруженные треки этого плейлиста, VK Z удалит из памяти {count, plural, one{{count} сохранённый трек} few{{count} сохранённых трека} other{{count} сохранённых треков}}, что занимает {size} на Вашем устройстве.\n\nПосле удаления Вы не сможете слушать данный плейлист оффлайн.\nУверены, что хотите продолжить?'**
  String disable_download_desc({required int count, required String size});

  /// No description provided for @stop_downloading_button.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get stop_downloading_button;

  /// No description provided for @delete_downloaded_button.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete_downloaded_button;

  /// No description provided for @playlist_downloading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка плейлиста «{title}»'**
  String playlist_downloading({required String title});

  /// No description provided for @playlist_download_removal.
  ///
  /// In ru, this message translates to:
  /// **'Удаление треков плейлиста «{title}»'**
  String playlist_download_removal({required String title});

  /// No description provided for @search_music_global.
  ///
  /// In ru, this message translates to:
  /// **'Поиск музыки ВКонтакте'**
  String get search_music_global;

  /// No description provided for @type_to_search.
  ///
  /// In ru, this message translates to:
  /// **'Введите название песни сверху чтобы начать поиск.'**
  String get type_to_search;

  /// No description provided for @audio_restore_too_late_desc.
  ///
  /// In ru, this message translates to:
  /// **'Трек не может быть восстановлен, поскольку прошло немало времени с момента его удаления.\nВоспользуйтесь поиском, чтобы найти этот трек и добавить снова.'**
  String get audio_restore_too_late_desc;

  /// No description provided for @add_track_as_liked.
  ///
  /// In ru, this message translates to:
  /// **'Добавить как «любимый» трек'**
  String get add_track_as_liked;

  /// No description provided for @remove_track_as_liked.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из «любимых» треков'**
  String get remove_track_as_liked;

  /// No description provided for @open_track_playlist.
  ///
  /// In ru, this message translates to:
  /// **'Открыть плейлист'**
  String get open_track_playlist;

  /// No description provided for @add_track_to_playlist.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в плейлист'**
  String get add_track_to_playlist;

  /// No description provided for @play_track_next.
  ///
  /// In ru, this message translates to:
  /// **'Сыграть следующим'**
  String get play_track_next;

  /// No description provided for @go_to_track_album.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к альбому'**
  String get go_to_track_album;

  /// No description provided for @go_to_track_album_desc.
  ///
  /// In ru, this message translates to:
  /// **'Откроет страницу альбома «{title}»'**
  String go_to_track_album_desc({required String title});

  /// No description provided for @search_track_on_genius.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по Genius'**
  String get search_track_on_genius;

  /// No description provided for @search_track_on_genius_desc.
  ///
  /// In ru, this message translates to:
  /// **'Текст песни, и прочая информация с Genius'**
  String get search_track_on_genius_desc;

  /// No description provided for @download_this_track.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить'**
  String get download_this_track;

  /// No description provided for @download_this_track_desc.
  ///
  /// In ru, this message translates to:
  /// **'Позволяет прослушать трек даже без подключения к интернету'**
  String get download_this_track_desc;

  /// No description provided for @change_track_thumbnail.
  ///
  /// In ru, this message translates to:
  /// **'Заменить обложку'**
  String get change_track_thumbnail;

  /// No description provided for @change_track_thumbnail_desc.
  ///
  /// In ru, this message translates to:
  /// **'Устанавливает обложку, выполняя поиск с сервиса Deezer'**
  String get change_track_thumbnail_desc;

  /// No description provided for @reupload_track_from_youtube.
  ///
  /// In ru, this message translates to:
  /// **'Перезалить с Youtube'**
  String get reupload_track_from_youtube;

  /// No description provided for @reupload_track_from_youtube_desc.
  ///
  /// In ru, this message translates to:
  /// **'Локально заменяет этот трек на версию с Youtube'**
  String get reupload_track_from_youtube_desc;

  /// No description provided for @replace_track_with_local.
  ///
  /// In ru, this message translates to:
  /// **'Локальная замена трека'**
  String get replace_track_with_local;

  /// No description provided for @replace_track_with_local_desc.
  ///
  /// In ru, this message translates to:
  /// **'Локально заменяет это аудио на другое, загруженное на Вашем устройстве'**
  String get replace_track_with_local_desc;

  /// No description provided for @replace_track_with_local_filepicker_title.
  ///
  /// In ru, this message translates to:
  /// **'Выберите трек для замены'**
  String get replace_track_with_local_filepicker_title;

  /// No description provided for @replace_track_with_local_success.
  ///
  /// In ru, this message translates to:
  /// **'Трек был успешно заменён на этом устройстве.'**
  String get replace_track_with_local_success;

  /// No description provided for @remove_local_track_version.
  ///
  /// In ru, this message translates to:
  /// **'Удалить локальную версию трека'**
  String get remove_local_track_version;

  /// No description provided for @remove_local_track_success.
  ///
  /// In ru, this message translates to:
  /// **'Трек был успешно восстановлен.'**
  String get remove_local_track_success;

  /// No description provided for @remove_local_track_is_restricted_title.
  ///
  /// In ru, this message translates to:
  /// **'Трек ограничен'**
  String get remove_local_track_is_restricted_title;

  /// No description provided for @remove_local_track_is_restricted_desc.
  ///
  /// In ru, this message translates to:
  /// **'Данный трек недоступен для прослушивания со стороны ВКонтакте, поскольку так решил его исполнитель. Продолжив, Вы удалите этот трек со своего устройства, и более Вы не сможете его прослушивать здесь.\n\nВы уверены, что хотите потерять доступ к этому треку?'**
  String get remove_local_track_is_restricted_desc;

  /// No description provided for @track_details.
  ///
  /// In ru, this message translates to:
  /// **'Детали трека'**
  String get track_details;

  /// No description provided for @change_track_thumbnail_search_text.
  ///
  /// In ru, this message translates to:
  /// **'Запрос для Deezer'**
  String get change_track_thumbnail_search_text;

  /// No description provided for @change_track_thumbnail_type_to_search.
  ///
  /// In ru, this message translates to:
  /// **'Введите название трека сверху, чтобы выполнить поиск по обложкам.'**
  String get change_track_thumbnail_type_to_search;

  /// No description provided for @icon_tooltip_downloaded.
  ///
  /// In ru, this message translates to:
  /// **'Загружен'**
  String get icon_tooltip_downloaded;

  /// No description provided for @icon_tooltip_replaced_locally.
  ///
  /// In ru, this message translates to:
  /// **'Заменён локально'**
  String get icon_tooltip_replaced_locally;

  /// No description provided for @icon_tooltip_restricted.
  ///
  /// In ru, this message translates to:
  /// **'Недоступен'**
  String get icon_tooltip_restricted;

  /// No description provided for @icon_tooltip_restricted_playable.
  ///
  /// In ru, this message translates to:
  /// **'Ограничен с возможностью воспроизведения'**
  String get icon_tooltip_restricted_playable;

  /// No description provided for @track_info_edit_error_restricted.
  ///
  /// In ru, this message translates to:
  /// **'Вы не можете отредактировать данный трек, поскольку это официальный релиз.'**
  String get track_info_edit_error_restricted;

  /// No description provided for @track_info_edit_error.
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка при редактировании трека: {error}'**
  String track_info_edit_error({required String error});

  /// No description provided for @all_blocks_disabled.
  ///
  /// In ru, this message translates to:
  /// **'Ой! Похоже, тут ничего нет.'**
  String get all_blocks_disabled;

  /// No description provided for @all_blocks_disabled_desc.
  ///
  /// In ru, this message translates to:
  /// **'Соскучились по музыке? Включите что-то, нажав на нужный переключатель сверху.'**
  String get all_blocks_disabled_desc;

  /// Используется в строке вида '[плейлист имеет] 95% совпадения с Вами'. <bold> ... </bold> делает текст жирным.
  ///
  /// In ru, this message translates to:
  /// **'<bold>{simillarity}%</bold> совпадения с Вами'**
  String simillarity_percent({required int simillarity});

  /// В случае, если запущен полноэкранный плеер, однако ничего на самом деле не играет. В таком случае, в интерфейсе показывается изображение спящей собачки. Эта надпись располагается под этой собачкой. <bold>....</bold> делает текст жирным, <exit>...</exit> закрывает полноэкранный плеер.
  ///
  /// In ru, this message translates to:
  /// **'<bold>Тс-с-с, тишину! Собачка спит!</bold>\n\nПлеер сейчас ничего не воспроизводит.\nНажмите <exit>сюда</exit>, чтобы закрыть этот экран.'**
  String get fullscreen_no_audio;

  /// No description provided for @logout_desc.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите выйти из аккаунта {name} приложения VK Z?'**
  String logout_desc({required String name});

  /// No description provided for @no_recommendations_warning.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендации ВКонтакте не подключены'**
  String get no_recommendations_warning;

  /// No description provided for @no_recommendations_warning_desc.
  ///
  /// In ru, this message translates to:
  /// **'Из-за этого у треков нет обложек, а так же Вы теряете доступ к \"умным\" плейлистам с новыми треками.\n\nНажмите на это поле, чтобы подключить рекомендации и исправить это.'**
  String get no_recommendations_warning_desc;

  /// No description provided for @demo_mode_warning.
  ///
  /// In ru, this message translates to:
  /// **'Запущена демо-версия VK Z'**
  String get demo_mode_warning;

  /// No description provided for @demo_mode_warning_desc.
  ///
  /// In ru, this message translates to:
  /// **'Из-за этого отключена огромная часть функционала, не работает авторизация, есть проблемы с производительностью и стабильностью.\n\nНажмите на это поле, чтобы загрузить полноценную версию приложения на Ваше устройство.'**
  String get demo_mode_warning_desc;

  /// No description provided for @player_queue_header.
  ///
  /// In ru, this message translates to:
  /// **'Воспроизведение плейлиста'**
  String get player_queue_header;

  /// No description provided for @player_lyrics_header.
  ///
  /// In ru, this message translates to:
  /// **'Источник текста песни'**
  String get player_lyrics_header;

  /// No description provided for @lyrics_vk_source.
  ///
  /// In ru, this message translates to:
  /// **'ВКонтакте'**
  String get lyrics_vk_source;

  /// No description provided for @lyrics_lrclib_source.
  ///
  /// In ru, this message translates to:
  /// **'LRCLib'**
  String get lyrics_lrclib_source;

  /// No description provided for @global_search_query.
  ///
  /// In ru, this message translates to:
  /// **'Что ты хочешь найти?'**
  String get global_search_query;

  /// No description provided for @search_history.
  ///
  /// In ru, this message translates to:
  /// **'История поиска'**
  String get search_history;

  /// No description provided for @visual_settings.
  ///
  /// In ru, this message translates to:
  /// **'Стиль и внешний вид'**
  String get visual_settings;

  /// No description provided for @visual_settings_desc.
  ///
  /// In ru, this message translates to:
  /// **'Изменение внешнего вида и стиля приложения'**
  String get visual_settings_desc;

  /// No description provided for @app_theme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get app_theme;

  /// No description provided for @app_theme_desc.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема делает интерфейс более приятным для глаз, особенно при использовании в тёмное время суток.\n\nДополнительно, Вы можете включить OLED-тему, что сделает фон приложения максимально чёрным для экономии заряда батареи на некоторых устройствах.'**
  String get app_theme_desc;

  /// No description provided for @app_theme_system.
  ///
  /// In ru, this message translates to:
  /// **'Системная'**
  String get app_theme_system;

  /// No description provided for @app_theme_light.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get app_theme_light;

  /// No description provided for @app_theme_dark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get app_theme_dark;

  /// No description provided for @oled_theme.
  ///
  /// In ru, this message translates to:
  /// **'OLED-тема'**
  String get oled_theme;

  /// No description provided for @oled_theme_desc.
  ///
  /// In ru, this message translates to:
  /// **'При OLED-теме будет использоваться по-настоящему чёрный цвет для фона. Это может сэкономить заряд батареи на некоторых устройствах.'**
  String get oled_theme_desc;

  /// No description provided for @enable_oled_theme.
  ///
  /// In ru, this message translates to:
  /// **'Использовать OLED-тему'**
  String get enable_oled_theme;

  /// No description provided for @use_player_colors_appwide.
  ///
  /// In ru, this message translates to:
  /// **'Цвета трека по всему приложению'**
  String get use_player_colors_appwide;

  /// No description provided for @use_player_colors_appwide_desc.
  ///
  /// In ru, this message translates to:
  /// **'Если включить эту настройку, то цвета обложки играющего трека будут показаны не только в плеере снизу, но и по всему приложению.'**
  String get use_player_colors_appwide_desc;

  /// No description provided for @enable_player_colors_appwide.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить использование цветов трека по всему приложению'**
  String get enable_player_colors_appwide;

  /// No description provided for @player_dynamic_color_scheme_type.
  ///
  /// In ru, this message translates to:
  /// **'Палитра цветовой темы'**
  String get player_dynamic_color_scheme_type;

  /// No description provided for @player_dynamic_color_scheme_type_desc.
  ///
  /// In ru, this message translates to:
  /// **'Эта настройка диктует то, насколько яркими будут отображаться цвета в плеере снизу при воспроизведнии музыки.\n\nДанная настройка так же может работать с настройкой «Цвета трека по всему приложению», благодаря чему весь интерфейс приложения может меняться, в зависимости от цветов обложки трека, а так же яркости, указанной здесь.'**
  String get player_dynamic_color_scheme_type_desc;

  /// No description provided for @player_dynamic_color_scheme_type_tonalSpot.
  ///
  /// In ru, this message translates to:
  /// **'По-умолчанию'**
  String get player_dynamic_color_scheme_type_tonalSpot;

  /// No description provided for @player_dynamic_color_scheme_type_neutral.
  ///
  /// In ru, this message translates to:
  /// **'Нейтральный'**
  String get player_dynamic_color_scheme_type_neutral;

  /// No description provided for @player_dynamic_color_scheme_type_content.
  ///
  /// In ru, this message translates to:
  /// **'Яркий'**
  String get player_dynamic_color_scheme_type_content;

  /// No description provided for @player_dynamic_color_scheme_type_monochrome.
  ///
  /// In ru, this message translates to:
  /// **'Монохромный'**
  String get player_dynamic_color_scheme_type_monochrome;

  /// No description provided for @alternate_slider.
  ///
  /// In ru, this message translates to:
  /// **'Альтернативный слайдер'**
  String get alternate_slider;

  /// No description provided for @alternate_slider_desc.
  ///
  /// In ru, this message translates to:
  /// **'Определяет то, где будет располагаться слайдер («полосочка») для отображения прогресса вопроизведения трека в мини-плеере снизу: над плеером, либо внутри.'**
  String get alternate_slider_desc;

  /// No description provided for @enable_alternate_slider.
  ///
  /// In ru, this message translates to:
  /// **'Переместить слайдер над плеером'**
  String get enable_alternate_slider;

  /// No description provided for @spoiler_next_audio.
  ///
  /// In ru, this message translates to:
  /// **'Спойлер следующего трека'**
  String get spoiler_next_audio;

  /// No description provided for @spoiler_next_audio_desc.
  ///
  /// In ru, this message translates to:
  /// **'Данная настройка указывает то, будет ли отображено название для следующего трека перед тем, как закончить воспроизведение текущего. Название трека отображается над мини-плеером снизу.\n\nДополнительно, Вы можете включить настройку «Кроссфейд цветов плеера», что сделает плавный переход цветов плеера перед началом следующего трека.'**
  String get spoiler_next_audio_desc;

  /// No description provided for @enable_spoiler_next_audio.
  ///
  /// In ru, this message translates to:
  /// **'Показывать следующий трек'**
  String get enable_spoiler_next_audio;

  /// No description provided for @crossfade_audio_colors.
  ///
  /// In ru, this message translates to:
  /// **'Кроссфейд цветов плеера'**
  String get crossfade_audio_colors;

  /// No description provided for @crossfade_audio_colors_desc.
  ///
  /// In ru, this message translates to:
  /// **'Определяет, будет ли происходить плавный переход между цветами текущего трекам, а так же цветов последующего прямо перед началом следующего.'**
  String get crossfade_audio_colors_desc;

  /// No description provided for @enable_crossfade_audio_colors.
  ///
  /// In ru, this message translates to:
  /// **'Включить кроссфейд цветов плеера'**
  String get enable_crossfade_audio_colors;

  /// No description provided for @show_audio_thumbs.
  ///
  /// In ru, this message translates to:
  /// **'Отображение обложек'**
  String get show_audio_thumbs;

  /// No description provided for @show_audio_thumbs_desc.
  ///
  /// In ru, this message translates to:
  /// **'Если включить эту настройку, то приложение будет отображать обложки треков в плейлистах.\n\nИзменения данной настройки не затрагивают мини-плеер, располагаемый снизу.'**
  String get show_audio_thumbs_desc;

  /// No description provided for @enable_show_audio_thumbs.
  ///
  /// In ru, this message translates to:
  /// **'Включить отображение обложек треков'**
  String get enable_show_audio_thumbs;

  /// No description provided for @fullscreen_player.
  ///
  /// In ru, this message translates to:
  /// **'Полнооконный плеер'**
  String get fullscreen_player;

  /// No description provided for @fullscreen_player_desc.
  ///
  /// In ru, this message translates to:
  /// **'Изменение внешнего вида полнооконного плеера'**
  String get fullscreen_player_desc;

  /// No description provided for @use_track_thumb_as_player_background.
  ///
  /// In ru, this message translates to:
  /// **'Обложка трека как фон'**
  String get use_track_thumb_as_player_background;

  /// No description provided for @playback.
  ///
  /// In ru, this message translates to:
  /// **'Воспроизведение'**
  String get playback;

  /// No description provided for @playback_desc.
  ///
  /// In ru, this message translates to:
  /// **'Управение поведением, настройками воспроизведения'**
  String get playback_desc;

  /// No description provided for @track_title_in_window_bar.
  ///
  /// In ru, this message translates to:
  /// **'Название трека в заголовке окна'**
  String get track_title_in_window_bar;

  /// No description provided for @close_action.
  ///
  /// In ru, this message translates to:
  /// **'Действие при закрытии'**
  String get close_action;

  /// No description provided for @close_action_desc.
  ///
  /// In ru, this message translates to:
  /// **'Определяет, закроется ли приложение при закрытии окна'**
  String get close_action_desc;

  /// No description provided for @close_action_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыться'**
  String get close_action_close;

  /// No description provided for @close_action_minimize.
  ///
  /// In ru, this message translates to:
  /// **'Свернуться'**
  String get close_action_minimize;

  /// No description provided for @close_action_minimize_if_playing.
  ///
  /// In ru, this message translates to:
  /// **'Свернуться, если играет музыка'**
  String get close_action_minimize_if_playing;

  /// No description provided for @android_keep_playing_on_close.
  ///
  /// In ru, this message translates to:
  /// **'Игра после смахивания приложения'**
  String get android_keep_playing_on_close;

  /// No description provided for @android_keep_playing_on_close_desc.
  ///
  /// In ru, this message translates to:
  /// **'Определяет, продолжится ли воспроизведение после \"закрытия\" приложения в списке \"недавних\"'**
  String get android_keep_playing_on_close_desc;

  /// No description provided for @shuffle_on_play.
  ///
  /// In ru, this message translates to:
  /// **'Перемешка при воспроизведении'**
  String get shuffle_on_play;

  /// No description provided for @shuffle_on_play_desc.
  ///
  /// In ru, this message translates to:
  /// **'Перемешивает треки в плейлисте при запуске воспроизведения'**
  String get shuffle_on_play_desc;

  /// No description provided for @profile_pauseOnMuteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Пауза при минимальной громкости'**
  String get profile_pauseOnMuteTitle;

  /// No description provided for @profile_pauseOnMuteDescription.
  ///
  /// In ru, this message translates to:
  /// **'Поставив громкость на минимум, воспроизведение приостановится'**
  String get profile_pauseOnMuteDescription;

  /// No description provided for @stop_on_long_pause.
  ///
  /// In ru, this message translates to:
  /// **'Остановка при неактивности'**
  String get stop_on_long_pause;

  /// No description provided for @stop_on_long_pause_desc.
  ///
  /// In ru, this message translates to:
  /// **'Плеер перестанет играть при долгой паузе, экономя ресурсы устройства'**
  String get stop_on_long_pause_desc;

  /// No description provided for @rewind_on_previous.
  ///
  /// In ru, this message translates to:
  /// **'Перемотка при запуске предыдущего трека'**
  String get rewind_on_previous;

  /// No description provided for @rewind_on_previous_desc.
  ///
  /// In ru, this message translates to:
  /// **'В каких случаях попытка запуска предыдущего трека будет перематывать в начало вместо запуска предыдущего.\nПовторная попытка перемотки в течении небольшого времени запустит предыдущий трек вне зависимости от значения настройки'**
  String get rewind_on_previous_desc;

  /// No description provided for @rewind_on_previous_always.
  ///
  /// In ru, this message translates to:
  /// **'Всегда'**
  String get rewind_on_previous_always;

  /// No description provided for @rewind_on_previous_only_via_ui.
  ///
  /// In ru, this message translates to:
  /// **'Только через интерфейс'**
  String get rewind_on_previous_only_via_ui;

  /// No description provided for @rewind_on_previous_only_via_notification.
  ///
  /// In ru, this message translates to:
  /// **'Только через уведомление/наушники'**
  String get rewind_on_previous_only_via_notification;

  /// No description provided for @rewind_on_previous_only_via_disabled.
  ///
  /// In ru, this message translates to:
  /// **'Никогда'**
  String get rewind_on_previous_only_via_disabled;

  /// No description provided for @check_for_duplicates.
  ///
  /// In ru, this message translates to:
  /// **'Защита от создания дубликатов'**
  String get check_for_duplicates;

  /// No description provided for @check_for_duplicates_desc.
  ///
  /// In ru, this message translates to:
  /// **'Вы увидите предупреждение о том, что трек уже лайкнут, чтобы не сохранить его дважды'**
  String get check_for_duplicates_desc;

  /// No description provided for @track_duplicate_found_title.
  ///
  /// In ru, this message translates to:
  /// **'Обнаружен дубликат трека'**
  String get track_duplicate_found_title;

  /// No description provided for @track_duplicate_found_desc.
  ///
  /// In ru, this message translates to:
  /// **'Похоже, что этот трек уже лайкнут Вами. Сохранив этот трек, у Вас будет ещё одна копия этого трека.\nВы уверены, что хотите сделать дубликат данного трека?'**
  String get track_duplicate_found_desc;

  /// No description provided for @integrations.
  ///
  /// In ru, this message translates to:
  /// **'Интеграции'**
  String get integrations;

  /// No description provided for @integrations_desc.
  ///
  /// In ru, this message translates to:
  /// **'Работа со сторонними сервисами'**
  String get integrations_desc;

  /// No description provided for @status_broadcast.
  ///
  /// In ru, this message translates to:
  /// **'Трансляция в статус'**
  String get status_broadcast;

  /// No description provided for @status_broadcast_desc.
  ///
  /// In ru, this message translates to:
  /// **'Отображает трек в статусе ВКонтакте'**
  String get status_broadcast_desc;

  /// No description provided for @discord_rpc.
  ///
  /// In ru, this message translates to:
  /// **'Discord Rich Presence'**
  String get discord_rpc;

  /// No description provided for @discord_rpc_desc.
  ///
  /// In ru, this message translates to:
  /// **'Транслирует играющий трек в Discord'**
  String get discord_rpc_desc;

  /// No description provided for @deezer_thumbnails.
  ///
  /// In ru, this message translates to:
  /// **'Обложки Deezer'**
  String get deezer_thumbnails;

  /// No description provided for @deezer_thumbnails_desc.
  ///
  /// In ru, this message translates to:
  /// **'Загружает недостающие обложки из Deezer'**
  String get deezer_thumbnails_desc;

  /// No description provided for @lrclib_lyrics.
  ///
  /// In ru, this message translates to:
  /// **'Тексты песен через LRCLIB'**
  String get lrclib_lyrics;

  /// No description provided for @lrclib_lyrics_desc.
  ///
  /// In ru, this message translates to:
  /// **'Берёт тексты песен из LRCLIB если они недоступны во ВКонтакте, либо они не являются синхронизированными'**
  String get lrclib_lyrics_desc;

  /// No description provided for @apple_music_animated_covers.
  ///
  /// In ru, this message translates to:
  /// **'Анимированные обложки Apple Music'**
  String get apple_music_animated_covers;

  /// No description provided for @apple_music_animated_covers_desc.
  ///
  /// In ru, this message translates to:
  /// **'Загружает анимированные обложки из Apple Music, которые отображаются в полнооконном плеере'**
  String get apple_music_animated_covers_desc;

  /// No description provided for @experimental_options.
  ///
  /// In ru, this message translates to:
  /// **'Экспериментальные функции'**
  String get experimental_options;

  /// No description provided for @experimental_options_desc.
  ///
  /// In ru, this message translates to:
  /// **'Раздел, в котором могут обитать страшные драконы'**
  String get experimental_options_desc;

  /// No description provided for @experimental_no_options_available.
  ///
  /// In ru, this message translates to:
  /// **'В данной версии приложения нет доступных экспериментальных функций.'**
  String get experimental_no_options_available;

  /// No description provided for @volume_normalization.
  ///
  /// In ru, this message translates to:
  /// **'Нормализация громкости'**
  String get volume_normalization;

  /// No description provided for @volume_normalization_desc.
  ///
  /// In ru, this message translates to:
  /// **'Автоматически изменяет громкость треков, чтобы их уровень громкости был схож друг с другом'**
  String get volume_normalization_desc;

  /// No description provided for @volume_normalization_dialog_desc.
  ///
  /// In ru, this message translates to:
  /// **'При значениях «средне» или «громко» может происходить искажение звука.'**
  String get volume_normalization_dialog_desc;

  /// No description provided for @volume_normalization_disabled.
  ///
  /// In ru, this message translates to:
  /// **'Выключено'**
  String get volume_normalization_disabled;

  /// No description provided for @volume_normalization_quiet.
  ///
  /// In ru, this message translates to:
  /// **'Тихо'**
  String get volume_normalization_quiet;

  /// No description provided for @volume_normalization_normal.
  ///
  /// In ru, this message translates to:
  /// **'Средне'**
  String get volume_normalization_normal;

  /// No description provided for @volume_normalization_loud.
  ///
  /// In ru, this message translates to:
  /// **'Громко'**
  String get volume_normalization_loud;

  /// No description provided for @silence_removal.
  ///
  /// In ru, this message translates to:
  /// **'Устранение тишины'**
  String get silence_removal;

  /// No description provided for @silence_removal_desc.
  ///
  /// In ru, this message translates to:
  /// **'Избавляется от тишины в начале и конце трека'**
  String get silence_removal_desc;

  /// No description provided for @updates.
  ///
  /// In ru, this message translates to:
  /// **'Обновления'**
  String get updates;

  /// No description provided for @updates_desc.
  ///
  /// In ru, this message translates to:
  /// **'Параметры системы обновлений'**
  String get updates_desc;

  /// No description provided for @app_updates_policy.
  ///
  /// In ru, this message translates to:
  /// **'Вид новых обновлений'**
  String get app_updates_policy;

  /// No description provided for @app_updates_policy_desc.
  ///
  /// In ru, this message translates to:
  /// **'Определяет то, как приложение будет раздражать Вас, напоминая о новом обновлении'**
  String get app_updates_policy_desc;

  /// No description provided for @app_updates_policy_dialog.
  ///
  /// In ru, this message translates to:
  /// **'Диалог'**
  String get app_updates_policy_dialog;

  /// No description provided for @app_updates_policy_popup.
  ///
  /// In ru, this message translates to:
  /// **'Надпись снизу'**
  String get app_updates_policy_popup;

  /// No description provided for @app_updates_policy_disabled.
  ///
  /// In ru, this message translates to:
  /// **'Отключено'**
  String get app_updates_policy_disabled;

  /// No description provided for @disable_updates_warning.
  ///
  /// In ru, this message translates to:
  /// **'Отключение обновлений'**
  String get disable_updates_warning;

  /// No description provided for @disable_updates_warning_desc.
  ///
  /// In ru, this message translates to:
  /// **'Похоже, что Вы пытаетесь отключить обновления приложения. Делать это не рекомендуется, поскольку в будущих версиях могут быть исправлены баги, а так же могут добавляться новые функции.\n\nЕсли Вас раздражает полноэкранный диалог, мешающий пользованию приложения, то попробуйте поменять эту настройку на значение \"Надпись снизу\": Такой вариант не будет мешать Вам.'**
  String get disable_updates_warning_desc;

  /// No description provided for @disable_updates_warning_disable.
  ///
  /// In ru, this message translates to:
  /// **'Всё равно отключить'**
  String get disable_updates_warning_disable;

  /// No description provided for @updates_are_disabled.
  ///
  /// In ru, this message translates to:
  /// **'Обновления приложения отключены. Вы можете проверять на наличие обновлений вручную, нажав на кнопку \"О приложении\" на странице профиля.'**
  String get updates_are_disabled;

  /// No description provided for @updates_channel.
  ///
  /// In ru, this message translates to:
  /// **'Канал обновлений'**
  String get updates_channel;

  /// No description provided for @updates_channel_desc.
  ///
  /// In ru, this message translates to:
  /// **'Бета-канал имеет более частые, но менее стабильные билды'**
  String get updates_channel_desc;

  /// No description provided for @updates_channel_releases.
  ///
  /// In ru, this message translates to:
  /// **'Основные (по-умолчанию)'**
  String get updates_channel_releases;

  /// No description provided for @updates_channel_prereleases.
  ///
  /// In ru, this message translates to:
  /// **'Бета'**
  String get updates_channel_prereleases;

  /// No description provided for @show_changelog.
  ///
  /// In ru, this message translates to:
  /// **'Список изменений'**
  String get show_changelog;

  /// No description provided for @show_changelog_desc.
  ///
  /// In ru, this message translates to:
  /// **'Показывает список изменений в этой версии приложения'**
  String get show_changelog_desc;

  /// No description provided for @changelog_dialog.
  ///
  /// In ru, this message translates to:
  /// **'Список изменений в {version}'**
  String changelog_dialog({required String version});

  /// No description provided for @force_update_check.
  ///
  /// In ru, this message translates to:
  /// **'Проверить на наличие обновлений'**
  String get force_update_check;

  /// No description provided for @force_update_check_desc.
  ///
  /// In ru, this message translates to:
  /// **'Текущая версия: {version}'**
  String force_update_check_desc({required String version});

  /// No description provided for @data_control.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт, импорт и удаление данных'**
  String get data_control;

  /// No description provided for @data_control_desc.
  ///
  /// In ru, this message translates to:
  /// **'Позволяет управлять данными, хранящимися в приложении'**
  String get data_control_desc;

  /// No description provided for @export_settings.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт настроек'**
  String get export_settings;

  /// No description provided for @export_settings_desc.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняет изменения настроек приложения и треков в файл, чтобы восстановить их на другом устройстве'**
  String get export_settings_desc;

  /// No description provided for @import_settings.
  ///
  /// In ru, this message translates to:
  /// **'Импорт настроек'**
  String get import_settings;

  /// No description provided for @import_settings_desc.
  ///
  /// In ru, this message translates to:
  /// **'Загружает файл, ранее созданный при помощи «экспорта настроек»'**
  String get import_settings_desc;

  /// No description provided for @export_settings_title.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт настроек'**
  String get export_settings_title;

  /// No description provided for @export_settings_tip.
  ///
  /// In ru, this message translates to:
  /// **'Об экспорте настроек'**
  String get export_settings_tip;

  /// No description provided for @export_settings_tip_desc.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт настроек — функция, которая позволяет сохранить настройки приложения и треков в специальный файл для ручного переноса на другое устройство.\n\nПосле экспорта Вам будет нужно перенести файл на другое устройство и воспользоваться функцией <importSettings><importSettingsIcon></importSettingsIcon> Импорт настроек</importSettings>, чтобы загрузить изменения.'**
  String get export_settings_tip_desc;

  /// No description provided for @export_settings_modified_settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки VK Z'**
  String get export_settings_modified_settings;

  /// No description provided for @export_settings_modified_settings_desc.
  ///
  /// In ru, this message translates to:
  /// **'Изменен{count, plural, one{а {count} настройка} few{о {count} настройки} other{о {count} настроек}}'**
  String export_settings_modified_settings_desc({required int count});

  /// No description provided for @export_settings_modified_thumbnails.
  ///
  /// In ru, this message translates to:
  /// **'Изменённые обложки треков'**
  String get export_settings_modified_thumbnails;

  /// No description provided for @export_settings_modified_thumbnails_desc.
  ///
  /// In ru, this message translates to:
  /// **'Опцией <colored><icon></icon> Заменить обложку</colored> было изменен{count, plural, one{а {count} обложка} few{о {count} обложки} other{о {count} обложек}}'**
  String export_settings_modified_thumbnails_desc({required int count});

  /// No description provided for @export_settings_modified_lyrics.
  ///
  /// In ru, this message translates to:
  /// **'Изменённые тексты песен'**
  String get export_settings_modified_lyrics;

  /// No description provided for @export_settings_modified_lyrics_desc.
  ///
  /// In ru, this message translates to:
  /// **'Измен{count, plural, one{ён {count} текст песни} few{ено {count} текста песен} other{ено {count} текстов песен}}'**
  String export_settings_modified_lyrics_desc({required int count});

  /// No description provided for @export_settings_modified_metadata.
  ///
  /// In ru, this message translates to:
  /// **'Изменённые параметры треков'**
  String get export_settings_modified_metadata;

  /// No description provided for @export_settings_modified_metadata_desc.
  ///
  /// In ru, this message translates to:
  /// **'Измен{count, plural, one{ён {count} трек} few{ено {count} трека} other{ено {count} треков}}'**
  String export_settings_modified_metadata_desc({required int count});

  /// No description provided for @export_settings_downloaded_restricted.
  ///
  /// In ru, this message translates to:
  /// **'Загруженные, но ограниченные треки'**
  String get export_settings_downloaded_restricted;

  /// No description provided for @export_settings_downloaded_restricted_desc.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} трек доступен} few{{count} трека доступно} other{{count} треков доступно}} для прослушивания несмотря на ограниченный доступ благодаря скачиванию'**
  String export_settings_downloaded_restricted_desc({required int count});

  /// No description provided for @export_settings_locally_replaced.
  ///
  /// In ru, this message translates to:
  /// **'Локально заменённые треки'**
  String get export_settings_locally_replaced;

  /// No description provided for @export_settings_locally_replaced_desc.
  ///
  /// In ru, this message translates to:
  /// **'Замен{count, plural, one{ён {count} трек} few{ено {count} трека} other{ено {count} .mp3-файлов треков}} при помощи <colored><icon></icon> Локальной замены трека</colored>'**
  String export_settings_locally_replaced_desc({required int count});

  /// No description provided for @export_settings_export.
  ///
  /// In ru, this message translates to:
  /// **'Экспортировать'**
  String get export_settings_export;

  /// No description provided for @export_settings_success.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт завершён'**
  String get export_settings_success;

  /// No description provided for @export_settings_success_desc.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт завершён успешно! Вручную перенесите файл на другое устройство и воспользуйтесь опцией «импорт настроек» что бы восстановить изменения.'**
  String get export_settings_success_desc;

  /// No description provided for @copy_to_downloads_success.
  ///
  /// In ru, this message translates to:
  /// **'Файл был успешно скопирован в папку «Загрузки».'**
  String get copy_to_downloads_success;

  /// No description provided for @settings_import.
  ///
  /// In ru, this message translates to:
  /// **'Импорт настроек'**
  String get settings_import;

  /// No description provided for @settings_import_tip.
  ///
  /// In ru, this message translates to:
  /// **'Об импорте настроек'**
  String get settings_import_tip;

  /// No description provided for @settings_import_tip_desc.
  ///
  /// In ru, this message translates to:
  /// **'Импорт настроек — функций, синхронизирующая настройки приложения VK Z а так же изменения треков, совершённые на другом устройстве.\n\nНе понимаете с чего начать? Обратитесь к функции <exportSettings><exportSettingsIcon></exportSettingsIcon> Экспорт настроек</exportSettings>.'**
  String get settings_import_tip_desc;

  /// No description provided for @settings_import_select_file.
  ///
  /// In ru, this message translates to:
  /// **'Файл для импорта настроек не выбран.'**
  String get settings_import_select_file;

  /// No description provided for @settings_import_select_file_dialog_title.
  ///
  /// In ru, this message translates to:
  /// **'Выберите файл для импорта настроек и треков'**
  String get settings_import_select_file_dialog_title;

  /// No description provided for @settings_import_version_missmatch.
  ///
  /// In ru, this message translates to:
  /// **'Проблема совместимости'**
  String get settings_import_version_missmatch;

  /// No description provided for @settings_import_version_missmatch_desc.
  ///
  /// In ru, this message translates to:
  /// **'Этот файл был создан в предыдущей версии VK Z (v{version}), ввиду чего могут быть проблемы с импортом.\n\nУверены, что хотите продолжить?'**
  String settings_import_version_missmatch_desc({required String version});

  /// No description provided for @settings_import_import.
  ///
  /// In ru, this message translates to:
  /// **'Импортировать'**
  String get settings_import_import;

  /// No description provided for @settings_import_success.
  ///
  /// In ru, this message translates to:
  /// **'Импорт настроек успешен'**
  String get settings_import_success;

  /// No description provided for @settings_import_success_desc_with_delete.
  ///
  /// In ru, this message translates to:
  /// **'Импорт настроек и треков был завершён успешно.\n\nВозможно, Вам понадобится перезагрузить приложение, что бы некоторые из настроек успешно сохранились и применились.\n\nПосле импорта, файл экспорта уже не нужен. Хотите удалить его?'**
  String get settings_import_success_desc_with_delete;

  /// No description provided for @settings_import_success_desc_no_delete.
  ///
  /// In ru, this message translates to:
  /// **'Импорт настроек и треков был завершён успешно. Возможно, Вам понадобится перезагрузить приложение, что бы некоторые из настроек успешно сохранились и применились.'**
  String get settings_import_success_desc_no_delete;

  /// No description provided for @export_music_list.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт списка треков'**
  String get export_music_list;

  /// No description provided for @export_music_list_desc.
  ///
  /// In ru, this message translates to:
  /// **'Список из {count, plural, one{{count} лайкнутого трека} other{{count} лайкнутых треков}}:'**
  String export_music_list_desc({required int count});

  /// No description provided for @reset_db.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить базу треков'**
  String get reset_db;

  /// No description provided for @reset_db_desc.
  ///
  /// In ru, this message translates to:
  /// **'Очищает локальную копию базы данных треков, хранимую на этом устройстве'**
  String get reset_db_desc;

  /// No description provided for @reset_db_dialog.
  ///
  /// In ru, this message translates to:
  /// **'Сброс базы данных треков'**
  String get reset_db_dialog;

  /// No description provided for @reset_db_dialog_desc.
  ///
  /// In ru, this message translates to:
  /// **'Продолжив, VK Z удалит базу данных треков, хранимую на этом устройстве. Пожалуйста, не делайте этого без острой необходимости.\n\nВаши треки (как лайкнутые, так и загруженные) не будут удалены, однако Вам придётся по-новой запустить процесс загрузки на ранее загруженных плейлистах.'**
  String get reset_db_dialog_desc;

  /// No description provided for @debug_options.
  ///
  /// In ru, this message translates to:
  /// **'Отладочные опции'**
  String get debug_options;

  /// No description provided for @debug_options_desc.
  ///
  /// In ru, this message translates to:
  /// **'Опции, необходимые для изучения и исправления технических проблем'**
  String get debug_options_desc;

  /// No description provided for @share_logs.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться файлом логов'**
  String get share_logs;

  /// No description provided for @share_logs_desc.
  ///
  /// In ru, this message translates to:
  /// **'Техническая информация для отладки ошибок'**
  String get share_logs_desc;

  /// No description provided for @share_logs_desc_no_logs.
  ///
  /// In ru, this message translates to:
  /// **'Недоступно, поскольку файл логов пуст'**
  String get share_logs_desc_no_logs;

  /// No description provided for @player_debug_logging.
  ///
  /// In ru, this message translates to:
  /// **'Debug-логирование плеера'**
  String get player_debug_logging;

  /// No description provided for @player_debug_logging_desc.
  ///
  /// In ru, this message translates to:
  /// **'Включает вывод технических данных плеера, ухудшая при этом производительность'**
  String get player_debug_logging_desc;

  /// No description provided for @about_flutter_vk.
  ///
  /// In ru, this message translates to:
  /// **'О VK Z'**
  String get about_flutter_vk;

  /// No description provided for @app_telegram.
  ///
  /// In ru, this message translates to:
  /// **'Telegram-канал'**
  String get app_telegram;

  /// No description provided for @app_telegram_desc.
  ///
  /// In ru, this message translates to:
  /// **'Откроет Telegram-канал с CI-билдами, а так же информацией о разработке приложения'**
  String get app_telegram_desc;

  /// No description provided for @app_github.
  ///
  /// In ru, this message translates to:
  /// **'Исходный код проекта'**
  String get app_github;

  /// No description provided for @app_github_desc.
  ///
  /// In ru, this message translates to:
  /// **'Нажав сюда, мы отправим Вас в прекрасный Github-репозиторий приложения VK Z'**
  String get app_github_desc;

  /// No description provided for @app_version.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get app_version;

  /// No description provided for @app_version_desc.
  ///
  /// In ru, this message translates to:
  /// **'Установленная версия приложения: {version}.\nНажмите сюда, чтобы проверить на наличие новых обновлений'**
  String app_version_desc({required Object version});

  /// No description provided for @app_version_prerelease.
  ///
  /// In ru, this message translates to:
  /// **'бета'**
  String get app_version_prerelease;

  /// No description provided for @development_options.
  ///
  /// In ru, this message translates to:
  /// **'Опции разработки'**
  String get development_options;

  /// No description provided for @development_options_desc.
  ///
  /// In ru, this message translates to:
  /// **'Эти опции предназначены лишь для разработчиков'**
  String get development_options_desc;

  /// No description provided for @download_manager_current_tasks.
  ///
  /// In ru, this message translates to:
  /// **'Загружаются сейчас'**
  String get download_manager_current_tasks;

  /// No description provided for @download_manager_old_tasks.
  ///
  /// In ru, this message translates to:
  /// **'Загружено ранее'**
  String get download_manager_old_tasks;

  /// No description provided for @download_manager_all_tasks.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} задача} few{{count} задачи} other{{count} задач}} всего'**
  String download_manager_all_tasks({required int count});

  /// No description provided for @download_manager_no_tasks.
  ///
  /// In ru, this message translates to:
  /// **'Пусто...'**
  String get download_manager_no_tasks;

  /// No description provided for @update_available.
  ///
  /// In ru, this message translates to:
  /// **'Доступно обновление VK Z'**
  String get update_available;

  /// Информация о доступном обновлении приложения. <arrow></arrow> - иконка стрелочки.
  ///
  /// In ru, this message translates to:
  /// **'v{oldVersion} <arrow></arrow> v{newVersion}, {date}, {time}. {badges}'**
  String update_available_desc(
      {required String oldVersion,
      required String newVersion,
      required DateTime date,
      required DateTime time,
      required String badges});

  /// <debug></debug> иконка бета-версии.
  ///
  /// In ru, this message translates to:
  /// **'<debug></debug> бета'**
  String get update_prerelease_type;

  /// Длинное название заголовка окна загрузки обновления приложения. Данное название отображается в менеджере загрузок.
  ///
  /// In ru, this message translates to:
  /// **'Обновление VK Z v{version}'**
  String app_update_download_long_title({required String version});

  /// No description provided for @update_available_popup.
  ///
  /// In ru, this message translates to:
  /// **'Доступно обновление VK Z до версии {version}.'**
  String update_available_popup({required Object version});

  /// No description provided for @update_check_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при проверке на наличие обновлений: {error}'**
  String update_check_error({required String error});

  /// No description provided for @update_pending.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка обновления начата. Дождитесь окончания загрузки, затем проследуйте инструкциям.'**
  String get update_pending;

  /// No description provided for @update_install_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при установке обновления'**
  String get update_install_error;

  /// No description provided for @no_updates_available.
  ///
  /// In ru, this message translates to:
  /// **'Установлена актуальная версия приложения.'**
  String get no_updates_available;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
