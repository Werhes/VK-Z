// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get general_yes => 'Да';

  @override
  String get general_no => 'Нет';

  @override
  String get general_save => 'Сохранить';

  @override
  String get general_reset => 'Сбросить';

  @override
  String get general_clear => 'Очистить';

  @override
  String get general_cancel => 'Отменить';

  @override
  String get general_close => 'Закрыть';

  @override
  String get general_loading => 'Загрузка...';

  @override
  String get general_restore => 'Вернуть';

  @override
  String get general_continue => 'Продолжить';

  @override
  String get general_shuffle => 'Перемешать';

  @override
  String get general_play => 'Воспроизвести';

  @override
  String get general_pause => 'Пауза';

  @override
  String get general_resume => 'Продолжить';

  @override
  String get general_enable => 'Включить';

  @override
  String get general_edit => 'Редактировать';

  @override
  String get general_logout => 'Выход';

  @override
  String get general_exit => 'Выйти';

  @override
  String get general_title => 'Название';

  @override
  String get general_artist => 'Исполнитель';

  @override
  String get general_genre => 'Жанр';

  @override
  String get general_share => 'Поделиться';

  @override
  String get general_nothing_found => 'Ничего не найдено';

  @override
  String get general_copy_to_downloads => 'Скопировать в «Загрузки»';

  @override
  String get general_open_folder => 'Открыть папку';

  @override
  String get general_select => 'Выбрать';

  @override
  String get general_details => 'Подробности';

  @override
  String get general_install => 'Установить';

  @override
  String get general_show => 'Показать';

  @override
  String get general_settings => 'Настройки';

  @override
  String general_filesize_mb({required int value}) {
    return '$value МБ';
  }

  @override
  String general_filesize_gb({required double value}) {
    final intl.NumberFormat valueNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String valueString = valueNumberFormat.format(value);

    return '$valueString ГБ';
  }

  @override
  String get general_favorites_playlist => 'Любимая музыка';

  @override
  String get general_search_playlist => 'Музыка из результатов поиска';

  @override
  String get general_owned_playlist => 'Ваш плейлист';

  @override
  String get general_saved_playlist => 'Сохранённый плейлист';

  @override
  String get general_recommended_playlist => 'Рекомендуемый плейлист';

  @override
  String general_audios_count({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count треков',
      few: '$count трека',
      one: '$count трек',
    );
    return '$_temp0';
  }

  @override
  String get dislike_track_action => 'Не нравится';

  @override
  String get enable_shuffle_action => 'Включить перемешку';

  @override
  String get disable_shuffle_action => 'Выключить перемешку';

  @override
  String get previous_track_action => 'Предыдущий';

  @override
  String get play_track_action => 'Воспроизвести';

  @override
  String get pause_track_action => 'Пауза';

  @override
  String get next_track_action => 'Следующий';

  @override
  String get enable_repeat_action => 'Включить повтор';

  @override
  String get disable_repeat_action => 'Выключить повтор';

  @override
  String get favorite_track_action => 'Нравится';

  @override
  String get remove_favorite_track_action => 'Не нравится';

  @override
  String get not_yet_implemented => 'Не реализовано';

  @override
  String get not_yet_implemented_desc =>
      'Данный функционал ещё не был реализован. Пожалуйста, ожидайте обновлений приложения в будущем!';

  @override
  String get error_dialog => 'Произошла ошибка';

  @override
  String get error_dialog_desc =>
      'Что-то очень сильно пошло не так. Что-то поломалось. Всё очень плохо.';

  @override
  String player_playback_error({required String error}) {
    return 'Ошибка воспроизведения: $error';
  }

  @override
  String player_playback_error_stopped({required String error}) {
    return 'Воспроизведение остановлено ввиду большого количества ошибок: $error';
  }

  @override
  String get track_added_to_queue => 'Трек добавлен в очередь.';

  @override
  String get app_restart_required => 'Пожалуйста, перезагрузите приложение.';

  @override
  String get option_unavailable_with_light_theme =>
      'Эта опция недоступна, поскольку сейчас используется светлая тема.';

  @override
  String get option_unavailable_without_recommendations =>
      'Настройка недоступна, поскольку у Вас не подключены рекомендации ВКонтакте.';

  @override
  String get option_unavailable_without_audio_playing =>
      'Изменения данной настройки не будут видны сейчас, поскольку Вы не запустили воспроизведение музыки.';

  @override
  String get thumbnails_unavailable_without_recommendations =>
      'Вы не видите обложек треков, поскольку у Вас не подключены рекомендации ВКонтакте.';

  @override
  String get app_minimized_message =>
      'VK Z свернулся.\nВоспользуйтесь треем или откройте приложение ещё раз, чтобы вернуть окошко.';

  @override
  String get tray_show_hide => 'Открыть/Свернуть';

  @override
  String get music_readme_contents =>
      'Хей-хей-хей! А ну, постой! 🤚\n\nДа, в этой папке хранятся загруженные приложением «VK Z» треки.\nЕсли ты обратил внимание, эти треки сохранены в очень необычном формате, и на то есть причина.\nЯ, разработчик приложения, не хочу, чтобы пользователи (вроде тебя!) могли легко получить доступ к этим трекам.\n\nЕсли ты сильно постараешься, рано или поздно найдешь нужный трек. Однако я бы предпочел, чтобы ты этого не делал.\nЕсли выяснится, что кто-то использует приложение для загрузки треков, мне придется добавить дополнительные уровни обфускации или шифрования, вроде AES.\n\nПожалуйста, уважай труд исполнителей, которые вкладывают много времени в создание своих треков. Распространяя их таким образом, ты наносишь им серьёзный вред.\nЕсли ты все же решишь распространять треки в виде .mp3-файлов, то, по крайней мере, делай это без корыстных целей, только для личного использования.\n\nСпасибо за внимание, fren :)';

  @override
  String get internet_required_title => 'Нет подключения';

  @override
  String get internet_required_desc =>
      'Данное действие можно выполнить лишь при подключении к интернету. Пожалуйста, подключитесь к сети и попробуйте ещё раз.';

  @override
  String get demo_mode_enabled_title => 'Недоступно в демо-версии';

  @override
  String get demo_mode_enabled_desc =>
      'Данный функционал недоступен в демо-версии VK Z.\nВы можете загрузить полноценную версию приложение, перейдя в «профиль».';

  @override
  String get prerelease_app_version_warning => 'Бета-версия';

  @override
  String get prerelease_app_version_warning_desc =>
      'Тс-с-с! Вы ступили на опасную территорию, установив бета-версию VK Z. Бета-версии менее стабильны, и обычным пользователям устанавливать их не рекомендуется.\n\nПродолжая, Вы осознаёте риски использования бета-версии приложения, в ином случае Вас может скушать дракоша.\nДанное уведомление будет показано только один раз.';

  @override
  String get demo_mode_welcome_warning => 'Демо-версия';

  @override
  String get demo_mode_welcome_warning_desc =>
      'Добро пожаловать в демо-версию VK Z! Здесь вы можете ознакомиться с основными возможностями приложения.\n\nВ полной версии будут доступны: авторизация во ВКонтакте, прослушивание рекомендаций, скачивание плейлистов и многое другое.\n\nДля загрузки полной версии перейдите в «профиль».';

  @override
  String get welcome_title => 'Добро пожаловать! 😎';

  @override
  String get welcome_desc =>
      '<bold>VK Z</bold> — это экспериментальный неофициальный клиент ВКонтакте, построенный при помощи фреймворка Flutter с <link>открытым исходным кодом</link> для прослушивания музыки без необходимости приобретать подписку VK Music.';

  @override
  String get login_title => 'Авторизация';

  @override
  String get login_desktop_desc =>
      'Для авторизации <link>🔗 перейдите по ссылке</link> и предоставьте приложению доступ к аккаунту ВКонтакте.\nНажав на «разрешить», скопируйте адрес сайта из адресной строки браузера и вставьте в поле ниже:';

  @override
  String get login_connect_recommendations_title => 'Подключение рекомендаций';

  @override
  String get login_connect_recommendations_desc =>
      'Для подключения рекомендаций <link>🔗 перейдите по ссылке</link> и предоставьте приложению доступ к аккаунту ВКонтакте.\nНажав на «разрешить», скопируйте адрес сайта из адресной строки браузера и вставьте в поле ниже:';

  @override
  String get login_authorize => 'Авторизоваться';

  @override
  String get login_mobile_alternate_auth => 'Альтернативный метод авторизации';

  @override
  String get login_no_token_error =>
      'Access-токен не был найден в переданной ссылке.';

  @override
  String get login_no_music_access_desc =>
      'VK Z не смог получить доступ к специальным разделам музыки, необходимых для функционирования приложения.\nЧаще всего, такая ошибка происходит в случае, если Вы по-ошибке попытались авторизоваться при помощи приложения Kate Mobile вместо приложения VK Admin.\n\nПожалуйста, внимательно проследуйте инструкциям для авторизации, и попробуйте снова.';

  @override
  String login_wrong_user_id({required String name}) {
    return 'VK Z обнаружил, что Вы подключили другую страницу ВКонтакте, которая отличается от той, которая подключена сейчас.\nПожалуйста, авторизуйтесь как $name во ВКонтакте и попробуйте снова.';
  }

  @override
  String get login_success_auth => 'Авторизация успешна!';

  @override
  String get music_label => 'Музыка';

  @override
  String get music_label_offline => 'Музыка (оффлайн)';

  @override
  String get search_label => 'Поиск';

  @override
  String get search_label_offline => 'Поиск (оффлайн)';

  @override
  String get music_library_label => 'Библиотека';

  @override
  String get profile_label => 'Профиль';

  @override
  String get profile_labelOffline => 'Профиль (оффлайн)';

  @override
  String get downloads_label => 'Загрузки';

  @override
  String get downloads_label_offline => 'Загрузки (оффлайн)';

  @override
  String music_welcome_title({required String name}) {
    return 'Добро пожаловать, $name! 👋';
  }

  @override
  String category_closed({required String category}) {
    return 'Вы закрыли раздел «$category». Вы можете вернуть его, нажав на кнопку в «активных разделах».';
  }

  @override
  String get my_music_chip => 'Моя музыка';

  @override
  String get my_playlists_chip => 'Ваши плейлисты';

  @override
  String get realtime_playlists_chip => 'В реальном времени';

  @override
  String get vk_mix_chip => 'VK Mix';

  @override
  String get recommended_playlists_chip => 'Плейлисты для Вас';

  @override
  String get simillar_music_chip => 'Совпадения по вкусам';

  @override
  String get by_vk_chip => 'Собрано редакцией';

  @override
  String get connect_recommendations_chip =>
      'Подключить рекомендации ВКонтакте';

  @override
  String get connect_recommendations_title => 'Подключение рекомендаций';

  @override
  String get connect_recommendations_desc =>
      'Подключив рекомендации, Вы получите доступ к разделам музыки «Плейлисты для Вас», «VK Mix» и другие, а так же Вы начнёте видеть обложки треков.\n\nДля подключения рекомендаций, Вам будет необходимо повторно авторизоваться.';

  @override
  String get all_tracks => 'Все треки';

  @override
  String get track_unavailable_offline_title => 'Трек недоступен оффлайн';

  @override
  String get track_unavailable_offline_desc =>
      'Вы не можете прослушать данный трек в оффлайн-режиме, поскольку Вы не загрузили его ранее.';

  @override
  String get track_restricted_title => 'Аудиозапись недоступна';

  @override
  String get track_restricted_desc =>
      'Сервера ВКонтакте сообщили, что эта аудиозапись недоступна. Вероятнее всего, так решил исполнитель трека либо его лейбл.\nПоскольку Вы не загрузили этот трек ранее, воспроизведение невозможно.\n\nВоспользуйтесь опцией «локальная замена трека» при наличии загруженного аудио в формате .mp3.';

  @override
  String search_tracks_in_playlist({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count треков',
      one: '$count трека',
    );
    return 'Поиск среди $_temp0 здесь';
  }

  @override
  String get playlist_is_empty => 'В данном плейлисте пусто.';

  @override
  String get playlist_search_zero_results =>
      'По Вашему запросу ничего не найдено. Попробуйте <click>очистить свой запрос</click>.';

  @override
  String get enable_download_title => 'Включение загрузки треков';

  @override
  String enable_download_desc(
      {required int count, required String downloadSize}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'загружено $count треков',
      few: 'загружено $count трека',
      one: 'загружен $count трек',
    );
    return 'Включив загрузку треков, VK Z будет автоматически загружать все треки в данном плейлисте, делая их доступных для прослушивания даже оффлайн, а так же после удаления правообладателем.\n\nПродолжив, будет $_temp0, что потребует ~$downloadSize интернет трафика.\nПожалуйста, не запускайте этот процесс, если у Вас лимитированный интернет.';
  }

  @override
  String get disable_download_title => 'Удаление загруженных треков';

  @override
  String disable_download_desc({required int count, required String size}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сохранённых треков',
      few: '$count сохранённых трека',
      one: '$count сохранённый трек',
    );
    return 'Очистив загруженные треки этого плейлиста, VK Z удалит из памяти $_temp0, что занимает $size на Вашем устройстве.\n\nПосле удаления Вы не сможете слушать данный плейлист оффлайн.\nУверены, что хотите продолжить?';
  }

  @override
  String get stop_downloading_button => 'Остановить';

  @override
  String get delete_downloaded_button => 'Удалить';

  @override
  String playlist_downloading({required String title}) {
    return 'Загрузка плейлиста «$title»';
  }

  @override
  String playlist_download_removal({required String title}) {
    return 'Удаление треков плейлиста «$title»';
  }

  @override
  String get search_music_global => 'Поиск музыки ВКонтакте';

  @override
  String get type_to_search =>
      'Введите название песни сверху чтобы начать поиск.';

  @override
  String get audio_restore_too_late_desc =>
      'Трек не может быть восстановлен, поскольку прошло немало времени с момента его удаления.\nВоспользуйтесь поиском, чтобы найти этот трек и добавить снова.';

  @override
  String get add_track_as_liked => 'Добавить как «любимый» трек';

  @override
  String get remove_track_as_liked => 'Удалить из «любимых» треков';

  @override
  String get open_track_playlist => 'Открыть плейлист';

  @override
  String get add_track_to_playlist => 'Добавить в плейлист';

  @override
  String get play_track_next => 'Сыграть следующим';

  @override
  String get go_to_track_album => 'Перейти к альбому';

  @override
  String go_to_track_album_desc({required String title}) {
    return 'Откроет страницу альбома «$title»';
  }

  @override
  String get search_track_on_genius => 'Поиск по Genius';

  @override
  String get search_track_on_genius_desc =>
      'Текст песни, и прочая информация с Genius';

  @override
  String get download_this_track => 'Загрузить';

  @override
  String get download_this_track_desc =>
      'Позволяет прослушать трек даже без подключения к интернету';

  @override
  String get change_track_thumbnail => 'Заменить обложку';

  @override
  String get change_track_thumbnail_desc =>
      'Устанавливает обложку, выполняя поиск с сервиса Deezer';

  @override
  String get reupload_track_from_youtube => 'Перезалить с Youtube';

  @override
  String get reupload_track_from_youtube_desc =>
      'Локально заменяет этот трек на версию с Youtube';

  @override
  String get replace_track_with_local => 'Локальная замена трека';

  @override
  String get replace_track_with_local_desc =>
      'Локально заменяет это аудио на другое, загруженное на Вашем устройстве';

  @override
  String get replace_track_with_local_filepicker_title =>
      'Выберите трек для замены';

  @override
  String get replace_track_with_local_success =>
      'Трек был успешно заменён на этом устройстве.';

  @override
  String get remove_local_track_version => 'Удалить локальную версию трека';

  @override
  String get remove_local_track_success => 'Трек был успешно восстановлен.';

  @override
  String get remove_local_track_is_restricted_title => 'Трек ограничен';

  @override
  String get remove_local_track_is_restricted_desc =>
      'Данный трек недоступен для прослушивания со стороны ВКонтакте, поскольку так решил его исполнитель. Продолжив, Вы удалите этот трек со своего устройства, и более Вы не сможете его прослушивать здесь.\n\nВы уверены, что хотите потерять доступ к этому треку?';

  @override
  String get track_details => 'Детали трека';

  @override
  String get change_track_thumbnail_search_text => 'Запрос для Deezer';

  @override
  String get change_track_thumbnail_type_to_search =>
      'Введите название трека сверху, чтобы выполнить поиск по обложкам.';

  @override
  String get icon_tooltip_downloaded => 'Загружен';

  @override
  String get icon_tooltip_replaced_locally => 'Заменён локально';

  @override
  String get icon_tooltip_restricted => 'Недоступен';

  @override
  String get icon_tooltip_restricted_playable =>
      'Ограничен с возможностью воспроизведения';

  @override
  String get track_info_edit_error_restricted =>
      'Вы не можете отредактировать данный трек, поскольку это официальный релиз.';

  @override
  String track_info_edit_error({required String error}) {
    return 'Произошла ошибка при редактировании трека: $error';
  }

  @override
  String get all_blocks_disabled => 'Ой! Похоже, тут ничего нет.';

  @override
  String get all_blocks_disabled_desc =>
      'Соскучились по музыке? Включите что-то, нажав на нужный переключатель сверху.';

  @override
  String simillarity_percent({required int simillarity}) {
    return '<bold>$simillarity%</bold> совпадения с Вами';
  }

  @override
  String get fullscreen_no_audio =>
      '<bold>Тс-с-с, тишину! Собачка спит!</bold>\n\nПлеер сейчас ничего не воспроизводит.\nНажмите <exit>сюда</exit>, чтобы закрыть этот экран.';

  @override
  String logout_desc({required String name}) {
    return 'Вы уверены, что хотите выйти из аккаунта $name приложения VK Z?';
  }

  @override
  String get no_recommendations_warning =>
      'Рекомендации ВКонтакте не подключены';

  @override
  String get no_recommendations_warning_desc =>
      'Из-за этого у треков нет обложек, а так же Вы теряете доступ к \"умным\" плейлистам с новыми треками.\n\nНажмите на это поле, чтобы подключить рекомендации и исправить это.';

  @override
  String get demo_mode_warning => 'Запущена демо-версия VK Z';

  @override
  String get demo_mode_warning_desc =>
      'Из-за этого отключена огромная часть функционала, не работает авторизация, есть проблемы с производительностью и стабильностью.\n\nНажмите на это поле, чтобы загрузить полноценную версию приложения на Ваше устройство.';

  @override
  String get player_queue_header => 'Воспроизведение плейлиста';

  @override
  String get player_lyrics_header => 'Источник текста песни';

  @override
  String get lyrics_vk_source => 'ВКонтакте';

  @override
  String get lyrics_lrclib_source => 'LRCLib';

  @override
  String get global_search_query => 'Что ты хочешь найти?';

  @override
  String get search_history => 'История поиска';

  @override
  String get visual_settings => 'Стиль и внешний вид';

  @override
  String get visual_settings_desc =>
      'Изменение внешнего вида и стиля приложения';

  @override
  String get app_theme => 'Тема';

  @override
  String get app_theme_desc =>
      'Тёмная тема делает интерфейс более приятным для глаз, особенно при использовании в тёмное время суток.\n\nДополнительно, Вы можете включить OLED-тему, что сделает фон приложения максимально чёрным для экономии заряда батареи на некоторых устройствах.';

  @override
  String get app_theme_system => 'Системная';

  @override
  String get app_theme_light => 'Светлая';

  @override
  String get app_theme_dark => 'Тёмная';

  @override
  String get oled_theme => 'OLED-тема';

  @override
  String get oled_theme_desc =>
      'При OLED-теме будет использоваться по-настоящему чёрный цвет для фона. Это может сэкономить заряд батареи на некоторых устройствах.';

  @override
  String get enable_oled_theme => 'Использовать OLED-тему';

  @override
  String get use_player_colors_appwide => 'Цвета трека по всему приложению';

  @override
  String get use_player_colors_appwide_desc =>
      'Если включить эту настройку, то цвета обложки играющего трека будут показаны не только в плеере снизу, но и по всему приложению.';

  @override
  String get enable_player_colors_appwide =>
      'Разрешить использование цветов трека по всему приложению';

  @override
  String get player_dynamic_color_scheme_type => 'Палитра цветовой темы';

  @override
  String get player_dynamic_color_scheme_type_desc =>
      'Эта настройка диктует то, насколько яркими будут отображаться цвета в плеере снизу при воспроизведнии музыки.\n\nДанная настройка так же может работать с настройкой «Цвета трека по всему приложению», благодаря чему весь интерфейс приложения может меняться, в зависимости от цветов обложки трека, а так же яркости, указанной здесь.';

  @override
  String get player_dynamic_color_scheme_type_tonalSpot => 'По-умолчанию';

  @override
  String get player_dynamic_color_scheme_type_neutral => 'Нейтральный';

  @override
  String get player_dynamic_color_scheme_type_content => 'Яркий';

  @override
  String get player_dynamic_color_scheme_type_monochrome => 'Монохромный';

  @override
  String get alternate_slider => 'Альтернативный слайдер';

  @override
  String get alternate_slider_desc =>
      'Определяет то, где будет располагаться слайдер («полосочка») для отображения прогресса вопроизведения трека в мини-плеере снизу: над плеером, либо внутри.';

  @override
  String get enable_alternate_slider => 'Переместить слайдер над плеером';

  @override
  String get spoiler_next_audio => 'Спойлер следующего трека';

  @override
  String get spoiler_next_audio_desc =>
      'Данная настройка указывает то, будет ли отображено название для следующего трека перед тем, как закончить воспроизведение текущего. Название трека отображается над мини-плеером снизу.\n\nДополнительно, Вы можете включить настройку «Кроссфейд цветов плеера», что сделает плавный переход цветов плеера перед началом следующего трека.';

  @override
  String get enable_spoiler_next_audio => 'Показывать следующий трек';

  @override
  String get crossfade_audio_colors => 'Кроссфейд цветов плеера';

  @override
  String get crossfade_audio_colors_desc =>
      'Определяет, будет ли происходить плавный переход между цветами текущего трекам, а так же цветов последующего прямо перед началом следующего.';

  @override
  String get enable_crossfade_audio_colors =>
      'Включить кроссфейд цветов плеера';

  @override
  String get show_audio_thumbs => 'Отображение обложек';

  @override
  String get show_audio_thumbs_desc =>
      'Если включить эту настройку, то приложение будет отображать обложки треков в плейлистах.\n\nИзменения данной настройки не затрагивают мини-плеер, располагаемый снизу.';

  @override
  String get enable_show_audio_thumbs => 'Включить отображение обложек треков';

  @override
  String get fullscreen_player => 'Полнооконный плеер';

  @override
  String get fullscreen_player_desc =>
      'Изменение внешнего вида полнооконного плеера';

  @override
  String get use_track_thumb_as_player_background => 'Обложка трека как фон';

  @override
  String get playback => 'Воспроизведение';

  @override
  String get playback_desc =>
      'Управение поведением, настройками воспроизведения';

  @override
  String get track_title_in_window_bar => 'Название трека в заголовке окна';

  @override
  String get close_action => 'Действие при закрытии';

  @override
  String get close_action_desc =>
      'Определяет, закроется ли приложение при закрытии окна';

  @override
  String get close_action_close => 'Закрыться';

  @override
  String get close_action_minimize => 'Свернуться';

  @override
  String get close_action_minimize_if_playing =>
      'Свернуться, если играет музыка';

  @override
  String get android_keep_playing_on_close =>
      'Игра после смахивания приложения';

  @override
  String get android_keep_playing_on_close_desc =>
      'Определяет, продолжится ли воспроизведение после \"закрытия\" приложения в списке \"недавних\"';

  @override
  String get shuffle_on_play => 'Перемешка при воспроизведении';

  @override
  String get shuffle_on_play_desc =>
      'Перемешивает треки в плейлисте при запуске воспроизведения';

  @override
  String get profile_pauseOnMuteTitle => 'Пауза при минимальной громкости';

  @override
  String get profile_pauseOnMuteDescription =>
      'Поставив громкость на минимум, воспроизведение приостановится';

  @override
  String get stop_on_long_pause => 'Остановка при неактивности';

  @override
  String get stop_on_long_pause_desc =>
      'Плеер перестанет играть при долгой паузе, экономя ресурсы устройства';

  @override
  String get rewind_on_previous => 'Перемотка при запуске предыдущего трека';

  @override
  String get rewind_on_previous_desc =>
      'В каких случаях попытка запуска предыдущего трека будет перематывать в начало вместо запуска предыдущего.\nПовторная попытка перемотки в течении небольшого времени запустит предыдущий трек вне зависимости от значения настройки';

  @override
  String get rewind_on_previous_always => 'Всегда';

  @override
  String get rewind_on_previous_only_via_ui => 'Только через интерфейс';

  @override
  String get rewind_on_previous_only_via_notification =>
      'Только через уведомление/наушники';

  @override
  String get rewind_on_previous_only_via_disabled => 'Никогда';

  @override
  String get check_for_duplicates => 'Защита от создания дубликатов';

  @override
  String get check_for_duplicates_desc =>
      'Вы увидите предупреждение о том, что трек уже лайкнут, чтобы не сохранить его дважды';

  @override
  String get track_duplicate_found_title => 'Обнаружен дубликат трека';

  @override
  String get track_duplicate_found_desc =>
      'Похоже, что этот трек уже лайкнут Вами. Сохранив этот трек, у Вас будет ещё одна копия этого трека.\nВы уверены, что хотите сделать дубликат данного трека?';

  @override
  String get integrations => 'Интеграции';

  @override
  String get integrations_desc => 'Работа со сторонними сервисами';

  @override
  String get status_broadcast => 'Трансляция в статус';

  @override
  String get status_broadcast_desc => 'Отображает трек в статусе ВКонтакте';

  @override
  String get discord_rpc => 'Discord Rich Presence';

  @override
  String get discord_rpc_desc => 'Транслирует играющий трек в Discord';

  @override
  String get deezer_thumbnails => 'Обложки Deezer';

  @override
  String get deezer_thumbnails_desc =>
      'Загружает недостающие обложки из Deezer';

  @override
  String get lrclib_lyrics => 'Тексты песен через LRCLIB';

  @override
  String get lrclib_lyrics_desc =>
      'Берёт тексты песен из LRCLIB если они недоступны во ВКонтакте, либо они не являются синхронизированными';

  @override
  String get apple_music_animated_covers => 'Анимированные обложки Apple Music';

  @override
  String get apple_music_animated_covers_desc =>
      'Загружает анимированные обложки из Apple Music, которые отображаются в полнооконном плеере';

  @override
  String get experimental_options => 'Экспериментальные функции';

  @override
  String get experimental_options_desc =>
      'Раздел, в котором могут обитать страшные драконы';

  @override
  String get experimental_no_options_available =>
      'В данной версии приложения нет доступных экспериментальных функций.';

  @override
  String get volume_normalization => 'Нормализация громкости';

  @override
  String get volume_normalization_desc =>
      'Автоматически изменяет громкость треков, чтобы их уровень громкости был схож друг с другом';

  @override
  String get volume_normalization_dialog_desc =>
      'При значениях «средне» или «громко» может происходить искажение звука.';

  @override
  String get volume_normalization_disabled => 'Выключено';

  @override
  String get volume_normalization_quiet => 'Тихо';

  @override
  String get volume_normalization_normal => 'Средне';

  @override
  String get volume_normalization_loud => 'Громко';

  @override
  String get silence_removal => 'Устранение тишины';

  @override
  String get silence_removal_desc =>
      'Избавляется от тишины в начале и конце трека';

  @override
  String get updates => 'Обновления';

  @override
  String get updates_desc => 'Параметры системы обновлений';

  @override
  String get app_updates_policy => 'Вид новых обновлений';

  @override
  String get app_updates_policy_desc =>
      'Определяет то, как приложение будет раздражать Вас, напоминая о новом обновлении';

  @override
  String get app_updates_policy_dialog => 'Диалог';

  @override
  String get app_updates_policy_popup => 'Надпись снизу';

  @override
  String get app_updates_policy_disabled => 'Отключено';

  @override
  String get disable_updates_warning => 'Отключение обновлений';

  @override
  String get disable_updates_warning_desc =>
      'Похоже, что Вы пытаетесь отключить обновления приложения. Делать это не рекомендуется, поскольку в будущих версиях могут быть исправлены баги, а так же могут добавляться новые функции.\n\nЕсли Вас раздражает полноэкранный диалог, мешающий пользованию приложения, то попробуйте поменять эту настройку на значение \"Надпись снизу\": Такой вариант не будет мешать Вам.';

  @override
  String get disable_updates_warning_disable => 'Всё равно отключить';

  @override
  String get updates_are_disabled =>
      'Обновления приложения отключены. Вы можете проверять на наличие обновлений вручную, нажав на кнопку \"О приложении\" на странице профиля.';

  @override
  String get updates_channel => 'Канал обновлений';

  @override
  String get updates_channel_desc =>
      'Бета-канал имеет более частые, но менее стабильные билды';

  @override
  String get updates_channel_releases => 'Основные (по-умолчанию)';

  @override
  String get updates_channel_prereleases => 'Бета';

  @override
  String get show_changelog => 'Список изменений';

  @override
  String get show_changelog_desc =>
      'Показывает список изменений в этой версии приложения';

  @override
  String changelog_dialog({required String version}) {
    return 'Список изменений в $version';
  }

  @override
  String get force_update_check => 'Проверить на наличие обновлений';

  @override
  String force_update_check_desc({required String version}) {
    return 'Текущая версия: $version';
  }

  @override
  String get data_control => 'Экспорт, импорт и удаление данных';

  @override
  String get data_control_desc =>
      'Позволяет управлять данными, хранящимися в приложении';

  @override
  String get export_settings => 'Экспорт настроек';

  @override
  String get export_settings_desc =>
      'Сохраняет изменения настроек приложения и треков в файл, чтобы восстановить их на другом устройстве';

  @override
  String get import_settings => 'Импорт настроек';

  @override
  String get import_settings_desc =>
      'Загружает файл, ранее созданный при помощи «экспорта настроек»';

  @override
  String get export_settings_title => 'Экспорт настроек';

  @override
  String get export_settings_tip => 'Об экспорте настроек';

  @override
  String get export_settings_tip_desc =>
      'Экспорт настроек — функция, которая позволяет сохранить настройки приложения и треков в специальный файл для ручного переноса на другое устройство.\n\nПосле экспорта Вам будет нужно перенести файл на другое устройство и воспользоваться функцией <importSettings><importSettingsIcon></importSettingsIcon> Импорт настроек</importSettings>, чтобы загрузить изменения.';

  @override
  String get export_settings_modified_settings => 'Настройки VK Z';

  @override
  String export_settings_modified_settings_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'о $count настроек',
      few: 'о $count настройки',
      one: 'а $count настройка',
    );
    return 'Изменен$_temp0';
  }

  @override
  String get export_settings_modified_thumbnails => 'Изменённые обложки треков';

  @override
  String export_settings_modified_thumbnails_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'о $count обложек',
      few: 'о $count обложки',
      one: 'а $count обложка',
    );
    return 'Опцией <colored><icon></icon> Заменить обложку</colored> было изменен$_temp0';
  }

  @override
  String get export_settings_modified_lyrics => 'Изменённые тексты песен';

  @override
  String export_settings_modified_lyrics_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ено $count текстов песен',
      few: 'ено $count текста песен',
      one: 'ён $count текст песни',
    );
    return 'Измен$_temp0';
  }

  @override
  String get export_settings_modified_metadata => 'Изменённые параметры треков';

  @override
  String export_settings_modified_metadata_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ено $count треков',
      few: 'ено $count трека',
      one: 'ён $count трек',
    );
    return 'Измен$_temp0';
  }

  @override
  String get export_settings_downloaded_restricted =>
      'Загруженные, но ограниченные треки';

  @override
  String export_settings_downloaded_restricted_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count треков доступно',
      few: '$count трека доступно',
      one: '$count трек доступен',
    );
    return '$_temp0 для прослушивания несмотря на ограниченный доступ благодаря скачиванию';
  }

  @override
  String get export_settings_locally_replaced => 'Локально заменённые треки';

  @override
  String export_settings_locally_replaced_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ено $count .mp3-файлов треков',
      few: 'ено $count трека',
      one: 'ён $count трек',
    );
    return 'Замен$_temp0 при помощи <colored><icon></icon> Локальной замены трека</colored>';
  }

  @override
  String get export_settings_export => 'Экспортировать';

  @override
  String get export_settings_success => 'Экспорт завершён';

  @override
  String get export_settings_success_desc =>
      'Экспорт завершён успешно! Вручную перенесите файл на другое устройство и воспользуйтесь опцией «импорт настроек» что бы восстановить изменения.';

  @override
  String get copy_to_downloads_success =>
      'Файл был успешно скопирован в папку «Загрузки».';

  @override
  String get settings_import => 'Импорт настроек';

  @override
  String get settings_import_tip => 'Об импорте настроек';

  @override
  String get settings_import_tip_desc =>
      'Импорт настроек — функций, синхронизирующая настройки приложения VK Z а так же изменения треков, совершённые на другом устройстве.\n\nНе понимаете с чего начать? Обратитесь к функции <exportSettings><exportSettingsIcon></exportSettingsIcon> Экспорт настроек</exportSettings>.';

  @override
  String get settings_import_select_file =>
      'Файл для импорта настроек не выбран.';

  @override
  String get settings_import_select_file_dialog_title =>
      'Выберите файл для импорта настроек и треков';

  @override
  String get settings_import_version_missmatch => 'Проблема совместимости';

  @override
  String settings_import_version_missmatch_desc({required String version}) {
    return 'Этот файл был создан в предыдущей версии VK Z (v$version), ввиду чего могут быть проблемы с импортом.\n\nУверены, что хотите продолжить?';
  }

  @override
  String get settings_import_import => 'Импортировать';

  @override
  String get settings_import_success => 'Импорт настроек успешен';

  @override
  String get settings_import_success_desc_with_delete =>
      'Импорт настроек и треков был завершён успешно.\n\nВозможно, Вам понадобится перезагрузить приложение, что бы некоторые из настроек успешно сохранились и применились.\n\nПосле импорта, файл экспорта уже не нужен. Хотите удалить его?';

  @override
  String get settings_import_success_desc_no_delete =>
      'Импорт настроек и треков был завершён успешно. Возможно, Вам понадобится перезагрузить приложение, что бы некоторые из настроек успешно сохранились и применились.';

  @override
  String get export_music_list => 'Экспорт списка треков';

  @override
  String export_music_list_desc({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count лайкнутых треков',
      one: '$count лайкнутого трека',
    );
    return 'Список из $_temp0:';
  }

  @override
  String get reset_db => 'Сбросить базу треков';

  @override
  String get reset_db_desc =>
      'Очищает локальную копию базы данных треков, хранимую на этом устройстве';

  @override
  String get reset_db_dialog => 'Сброс базы данных треков';

  @override
  String get reset_db_dialog_desc =>
      'Продолжив, VK Z удалит базу данных треков, хранимую на этом устройстве. Пожалуйста, не делайте этого без острой необходимости.\n\nВаши треки (как лайкнутые, так и загруженные) не будут удалены, однако Вам придётся по-новой запустить процесс загрузки на ранее загруженных плейлистах.';

  @override
  String get debug_options => 'Отладочные опции';

  @override
  String get debug_options_desc =>
      'Опции, необходимые для изучения и исправления технических проблем';

  @override
  String get share_logs => 'Поделиться файлом логов';

  @override
  String get share_logs_desc => 'Техническая информация для отладки ошибок';

  @override
  String get share_logs_desc_no_logs => 'Недоступно, поскольку файл логов пуст';

  @override
  String get player_debug_logging => 'Debug-логирование плеера';

  @override
  String get player_debug_logging_desc =>
      'Включает вывод технических данных плеера, ухудшая при этом производительность';

  @override
  String get about_flutter_vk => 'О VK Z';

  @override
  String get app_telegram => 'Telegram-канал';

  @override
  String get app_telegram_desc =>
      'Откроет Telegram-канал с CI-билдами, а так же информацией о разработке приложения';

  @override
  String get app_github => 'Исходный код проекта';

  @override
  String get app_github_desc =>
      'Нажав сюда, мы отправим Вас в прекрасный Github-репозиторий приложения VK Z';

  @override
  String get app_version => 'О приложении';

  @override
  String app_version_desc({required Object version}) {
    return 'Установленная версия приложения: $version.\nНажмите сюда, чтобы проверить на наличие новых обновлений';
  }

  @override
  String get app_version_prerelease => 'бета';

  @override
  String get development_options => 'Опции разработки';

  @override
  String get development_options_desc =>
      'Эти опции предназначены лишь для разработчиков';

  @override
  String get download_manager_current_tasks => 'Загружаются сейчас';

  @override
  String get download_manager_old_tasks => 'Загружено ранее';

  @override
  String download_manager_all_tasks({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задач',
      few: '$count задачи',
      one: '$count задача',
    );
    return '$_temp0 всего';
  }

  @override
  String get download_manager_no_tasks => 'Пусто...';

  @override
  String get update_available => 'Доступно обновление VK Z';

  @override
  String update_available_desc(
      {required String oldVersion,
      required String newVersion,
      required DateTime date,
      required DateTime time,
      required String badges}) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'v$oldVersion <arrow></arrow> v$newVersion, $dateString, $timeString. $badges';
  }

  @override
  String get update_prerelease_type => '<debug></debug> бета';

  @override
  String app_update_download_long_title({required String version}) {
    return 'Обновление VK Z v$version';
  }

  @override
  String update_available_popup({required Object version}) {
    return 'Доступно обновление VK Z до версии $version.';
  }

  @override
  String update_check_error({required String error}) {
    return 'Ошибка при проверке на наличие обновлений: $error';
  }

  @override
  String get update_pending =>
      'Загрузка обновления начата. Дождитесь окончания загрузки, затем проследуйте инструкциям.';

  @override
  String get update_install_error => 'Ошибка при установке обновления';

  @override
  String get no_updates_available =>
      'Установлена актуальная версия приложения.';
}
