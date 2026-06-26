import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/mix.dart';
import '../models/mix_settings.dart';
import 'vk_config.dart';

/// VK API Service
///
/// Использует тот же подход, что и рабочий Python-скрипт vk_client.py:
/// - API v5.131
/// - Kate Mobile User-Agent
/// - GET-запросы к api.vk.ru/method/
/// - Прямые методы audio.* (не catalog.getAudio)
/// - Без лишних заголовков и device_id
class VkApiService {
  String? _accessToken;
  int? _userId;

  static const String _tokenKey = 'vk_access_token';
  static const String _userIdKey = 'vk_user_id';

  bool get isAuthorized => _accessToken != null;
  int? get userId => _userId;
  String? get accessToken => _accessToken;

  /// Сохраняет токен и userId в памяти и в shared_preferences
  void setToken(String token, {int? userId}) {
    _accessToken = token;
    _userId = userId;
    _saveSession();
  }

  /// Очищает токен из памяти и из shared_preferences
  void clearToken() {
    _accessToken = null;
    _userId = null;
    _clearSession();
  }

  /// Пытается восстановить сессию из shared_preferences
  Future<bool> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userId = prefs.getInt(_userIdKey);

      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _userId = userId;
        debugPrint(
            'Session restored: token=${token.substring(0, 10)}..., userId=$userId');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to restore session: $e');
    }
    return false;
  }

  /// Сохраняет сессию в shared_preferences
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString(_tokenKey, _accessToken!);
      }
      if (_userId != null) {
        await prefs.setInt(_userIdKey, _userId!);
      }
    } catch (e) {
      debugPrint('Failed to save session: $e');
    }
  }

  /// Очищает сессию из shared_preferences
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }

  /// Единая точка вызова VK API.
  /// Использует GET-запрос как в Python-скрипте (Kate Mobile, v5.131).
  Future<dynamic> _call(String method, {Map<String, String>? params}) async {
    if (_accessToken == null) {
      throw Exception('Not authorized');
    }

    final queryParams = <String, String>{
      'access_token': _accessToken!,
      'v': VkConfig.apiVersion,
      'lang': 'ru',
      ...?params,
    };

    final uri = Uri.parse('${VkConfig.apiBaseUrl}/$method')
        .replace(queryParameters: queryParams);

    debugPrint('VK API GET: $method');

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': VkConfig.userAgent,
        'Accept-Language': 'ru',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Проверка на ошибку API
    if (data.containsKey('error')) {
      final error = data['error'] as Map<String, dynamic>;
      throw Exception(
          'VK API Error [${error['error_code']}]: ${error['error_msg']}');
    }

    return data['response'] ?? data;
  }

  // ==========================================
  // User info
  // ==========================================

  /// Получить информацию о текущем пользователе
  Future<Map<String, dynamic>> getCurrentUser() async {
    final data = await _call('users.get', params: {'fields': 'photo_100'});
    if (data is List && data.isNotEmpty) {
      return data[0] as Map<String, dynamic>;
    }
    return {};
  }

  // ==========================================
  // Tracks
  // ==========================================

  /// Получить аудиозаписи пользователя
  Future<List<Track>> getTracks({
    int? ownerId,
    int offset = 0,
    int count = 100,
  }) async {
    final params = <String, String>{
      'owner_id': (ownerId ?? _userId).toString(),
      'offset': offset.toString(),
      'count': count.toString(),
    };

    final data = await _call('audio.get', params: params);
    final items = _extractItems(data);
    return items.map((e) => Track.fromJson(e)).toList();
  }

  // ==========================================
  // Search
  // ==========================================

  /// Поиск аудиозаписей
  Future<List<Track>> searchTracks({
    required String query,
    int offset = 0,
    int count = 50,
  }) async {
    final params = <String, String>{
      'q': query,
      'count': count.toString(),
      'offset': offset.toString(),
      'auto_complete': '1',
      'sort': '2', // по популярности
    };

    final data = await _call('audio.search', params: params);
    final items = _extractItems(data);
    return items.map((e) => Track.fromJson(e)).toList();
  }

  // ==========================================
  // Playlists
  // ==========================================

  /// Получить плейлисты пользователя
  Future<List<Playlist>> getPlaylists({
    int? ownerId,
  }) async {
    final params = <String, String>{
      'owner_id': (ownerId ?? _userId).toString(),
      'count': '200',
    };

    final data = await _call('audio.getPlaylists', params: params);
    final items = _extractItems(data);
    return items.map((e) => Playlist.fromJson(e)).toList();
  }

  /// Получить треки плейлиста
  Future<List<Track>> getPlaylistTracks({
    required int playlistId,
    required int ownerId,
    String? accessKey,
    int offset = 0,
    int count = 2000,
  }) async {
    final params = <String, String>{
      'owner_id': ownerId.toString(),
      'playlist_id': playlistId.toString(),
      'offset': offset.toString(),
      'count': count.toString(),
    };
    if (accessKey != null && accessKey.isNotEmpty) {
      params['access_key'] = accessKey;
    }

    final data = await _call('audio.get', params: params);
    final items = _extractItems(data);
    return items.map((e) => Track.fromJson(e)).toList();
  }

  // ==========================================
  // Recommendations
  // ==========================================

  /// Получить рекомендации
  Future<List<Track>> getRecommendations({
    String? targetAudio,
    int count = 50,
  }) async {
    final params = <String, String>{
      'count': count.toString(),
      'shuffle': '1',
    };
    if (targetAudio != null && targetAudio.isNotEmpty) {
      params['target_audio'] = targetAudio;
    } else {
      params['user_id'] = _userId.toString();
    }

    final data = await _call('audio.getRecommendations', params: params);
    final items = _extractItems(data);
    return items.map((e) => Track.fromJson(e)).toList();
  }

  // ==========================================
  // VK Mix
  // ==========================================

  /// Получить треки VK Mix
  Future<List<Track>> getStreamMixAudios({
    String mixId = 'common',
    int count = 50,
  }) async {
    try {
      final params = <String, String>{
        'mix_id': mixId,
        'count': count.toString(),
      };

      final data = await _call('audio.getStreamMixAudios', params: params);
      final items = _extractItems(data);
      return items.map((e) => Track.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getStreamMixAudios failed: $e');
      return [];
    }
  }

  /// Получить настройки VK Mix
  Future<MixSettingsRoot?> getStreamMixSettings(String mixId) async {
    try {
      final params = <String, String>{
        'mix_id': mixId,
      };

      final data = await _call('audio.getStreamMixSettings', params: params);
      if (data is Map<String, dynamic>) {
        return MixSettingsRoot.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('getStreamMixSettings failed: $e');
      return null;
    }
  }

  /// Получить VK Mix (микс + треки)
  Future<Mix?> getMix() async {
    try {
      // Пробуем получить треки микса
      final tracks = await getStreamMixAudios(mixId: 'common', count: 50);
      if (tracks.isNotEmpty) {
        return Mix(
          id: 'stream_mix',
          title: 'Мой Микс',
          description: 'Персональная подборка для вас',
          tracks: tracks,
        );
      }

      // Fallback: создаём микс из рекомендаций
      final recs = await getRecommendations(count: 30);
      if (recs.isNotEmpty) {
        return Mix.fromRecommendations(recs);
      }

      return null;
    } catch (e) {
      debugPrint('getMix failed: $e');
      return null;
    }
  }

  // ==========================================
  // Audio by ID
  // ==========================================

  /// Получить аудио по ID (формат: owner_id_audio_id)
  Future<List<Track>> getAudioById({
    required List<String> audioIds,
  }) async {
    try {
      final params = <String, String>{
        'audios': audioIds.join(','),
      };

      final data = await _call('audio.getById', params: params);
      final items = _extractItems(data);
      return items.map((e) => Track.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getAudioById failed: $e');
      return [];
    }
  }

  // ==========================================
  // Catalog (для обратной совместимости)
  // ==========================================

  /// Заглушка для обратной совместимости с MusicProvider.
  /// В новом подходе catalog не используется.
  Future<Map<String, dynamic>> getCatalog() async {
    debugPrint('getCatalog: not used in new API approach, returning empty');
    return {'response': null};
  }

  /// Заглушка для обратной совместимости
  Future<List<Track>> getTracksFromCatalogData(
      Map<String, dynamic> catalog) async {
    return getTracks();
  }

  /// Заглушка для обратной совместимости
  Future<List<Playlist>> getPlaylistsFromCatalogData(
      Map<String, dynamic> catalog) async {
    return getPlaylists();
  }

  /// Заглушка для обратной совместимости
  Future<List<Track>> getRecommendationsFromCatalogData(
      Map<String, dynamic> catalog) async {
    return getRecommendations();
  }

  /// Заглушка для обратной совместимости
  Future<Mix?> getMixFromCatalogData(Map<String, dynamic> catalog) async {
    return getMix();
  }

  // ==========================================
  // Helpers
  // ==========================================

  /// Извлечь items из ответа API (может быть Map с ключом 'items' или List)
  List<Map<String, dynamic>> _extractItems(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }
}