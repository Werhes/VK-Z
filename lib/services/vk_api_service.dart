import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/track.dart';
import '../models/playlist.dart';
import '../models/mix.dart';
import '../models/mix_settings.dart';
import 'log_service.dart';
import 'vk_config.dart';

/// VK API Service
///
/// Использует чистый Dart HttpClient (без Dio, без Go FFI).
/// Все запросы — POST с form-encoded body, как в Music-M (VK Android App).
///
/// Ключевые отличия от предыдущей версии:
/// - API v8.154 (как в VK Android App)
/// - POST-запросы (не GET)
/// - VK Android App User-Agent и заголовки
/// - device_id для всех запросов
/// - HTTP/2
class VkApiService {
  String? _accessToken;
  int? _userId;
  String? _deviceId;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  HttpClient? _httpClient;

  static const String _tokenKey = 'vk_access_token';
  static const String _userIdKey = 'vk_user_id';
  static const String _deviceIdKey = 'vk_device_id';

  VkApiService({String? deviceId}) {
    _deviceId = deviceId;
    _httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 10);
  }

  bool get isAuthorized => _accessToken != null;
  int? get userId => _userId;
  String? get accessToken => _accessToken;
  String? get deviceId => _deviceId;

  void setToken(String token, {int? userId}) {
    _accessToken = token;
    _userId = userId;
    _saveSession();
  }

  /// Устанавливает device_id (синхронизирует с VkAuthService)
  void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  void clearToken() {
    _accessToken = null;
    _userId = null;
    _deviceId = null;
    _clearSession();
  }

  Future<bool> tryRestoreSession() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final userIdStr = await _secureStorage.read(key: _userIdKey);
      final savedDeviceId = await _secureStorage.read(key: _deviceIdKey);

      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _userId = userIdStr != null ? int.tryParse(userIdStr) : null;
        _deviceId = savedDeviceId ?? VkConfig.generateDeviceId();
        LogService.i(
            'Session restored: token=${token.substring(0, 10)}..., userId=$_userId, deviceId=$_deviceId',
            tag: 'API');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to restore session: $e');
    }
    return false;
  }

  Future<void> _saveSession() async {
    try {
      if (_accessToken != null) {
        await _secureStorage.write(key: _tokenKey, value: _accessToken!);
      }
      if (_userId != null) {
        await _secureStorage.write(key: _userIdKey, value: _userId.toString());
      }
      if (_deviceId != null) {
        await _secureStorage.write(key: _deviceIdKey, value: _deviceId!);
      }
    } catch (e) {
      debugPrint('Failed to save session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _deviceIdKey);
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }

  /// Единая точка вызова VK API.
  /// POST-запрос с form-encoded body, как в Music-M.
  ///
  /// [skipAuthorization] — если true, не добавляет access_token (для auth.* методов).
  /// [anonymousToken] — анонимный токен для методов, которые его требуют.
  Future<dynamic> _call(String method,
      {Map<String, String>? params,
      bool skipAuthorization = false,
      String? anonymousToken}) async {
    // Генерируем device_id если ещё нет
    _deviceId ??= VkConfig.generateDeviceId();

    // Собираем параметры как в Music-M VkApiInvoke.TryAddRequiredParameters
    final bodyParams = <String, String>{
      'v': VkConfig.apiVersion,
      'lang': 'ru',
      'device_id': _deviceId!,
      if (!skipAuthorization) 'access_token': _accessToken!,
      if (anonymousToken != null && anonymousToken.isNotEmpty)
        'anonymous_token': anonymousToken,
      if (params != null) ...params,
    };

    final url = '${VkConfig.apiBaseUrl}/$method';
    final body = Uri(queryParameters: bodyParams).query;

    LogService.d('VK API POST: $method (${bodyParams.length} params)', tag: 'API');

    try {
      final request = await _httpClient!.postUrl(Uri.parse(url));

      // Устанавливаем заголовки как в Music-M RestClientWithUserAgent
      for (final entry in VkConfig.headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
      request.headers.set('Content-Length', body.length.toString());

      // Отправляем тело
      request.write(body);

      final response = await request.close();

      if (response.statusCode != 200) {
        final errorBody = await response.transform(utf8.decoder).join();
        LogService.e('VK API HTTP ERROR $method: status=${response.statusCode}, body=$errorBody', tag: 'API');
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      // Проверяем VK API ошибку
      if (data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        final errorCode = error['error_code'];
        final errorMsg = error['error_msg'] ?? error['error_text'] ?? 'Unknown';
        final errorStr = 'VK API Error [$errorCode]: $errorMsg';
        LogService.e('VK API ERROR $method: $errorStr', tag: 'API');
        LogService.d('VK API ERROR response body: $responseBody', tag: 'API');
        throw Exception(errorStr);
      }

      final responseData = data['response'] ?? data;
      LogService.d('VK API OK $method: response type=${responseData.runtimeType}', tag: 'API');
      if (responseData is Map<String, dynamic>) {
        LogService.d('VK API OK $method: keys=${responseData.keys.take(10).join(", ")}', tag: 'API');
        if (responseData.containsKey('items')) {
          final items = responseData['items'];
          LogService.d('VK API OK $method: items count=${items is List ? items.length : "not a list"}', tag: 'API');
        }
        if (responseData.containsKey('count')) {
          LogService.d('VK API OK $method: count=${responseData['count']}', tag: 'API');
        }
      }
      if (responseData is List) {
        LogService.d('VK API OK $method: list length=${responseData.length}', tag: 'API');
      }

      return responseData;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  // ==========================================
  // User info
  // ==========================================

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
    LogService.d('Parsed ${items.length} tracks from audio.get', tag: 'API');
    return items.map((e) => Track.fromJson(e)).toList();
  }

  // ==========================================
  // Search
  // ==========================================

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
      'sort': '2',
    };

    final data = await _call('audio.search', params: params);
    final items = _extractItems(data);
    return items.map((e) => Track.fromJson(e)).toList();
  }

  // ==========================================
  // Playlists
  // ==========================================

  Future<List<Playlist>> getPlaylists({
    int? ownerId,
  }) async {
    final params = <String, String>{
      'owner_id': (ownerId ?? _userId).toString(),
      'count': '200',
    };

    final data = await _call('audio.getPlaylists', params: params);
    final items = _extractItems(data);
    LogService.d('Parsed ${items.length} playlists from audio.getPlaylists', tag: 'API');
    return items.map((e) => Playlist.fromJson(e)).toList();
  }

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
    LogService.d('Parsed ${items.length} recommendations', tag: 'API');
    return items.map((e) => Track.fromJson(e)).toList();
  }

  // ==========================================
  // VK Mix
  // ==========================================

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
      LogService.w('getStreamMixAudios failed: $e', tag: 'API');
      return [];
    }
  }

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
      LogService.w('getStreamMixSettings failed: $e', tag: 'API');
      return null;
    }
  }

  Future<Mix?> getMix() async {
    try {
      final tracks = await getStreamMixAudios(mixId: 'common', count: 50);
      if (tracks.isNotEmpty) {
        return Mix(
          id: 'stream_mix',
          title: 'Мой Микс',
          description: 'Персональная подборка для вас',
          tracks: tracks,
        );
      }

      final recs = await getRecommendations(count: 30);
      if (recs.isNotEmpty) {
        return Mix.fromRecommendations(recs);
      }

      return null;
    } catch (e) {
      LogService.w('getMix failed: $e', tag: 'API');
      return null;
    }
  }

  // ==========================================
  // Audio by ID
  // ==========================================

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
      LogService.w('getAudioById failed: $e', tag: 'API');
      return [];
    }
  }

  // ==========================================
  // Catalog (заглушки для совместимости)
  // ==========================================

  Future<Map<String, dynamic>> getCatalog() async {
    LogService.d('getCatalog: not used, returning empty', tag: 'API');
    return {'response': null};
  }

  Future<List<Track>> getTracksFromCatalogData(
      Map<String, dynamic> catalog) async {
    return getTracks();
  }

  Future<List<Playlist>> getPlaylistsFromCatalogData(
      Map<String, dynamic> catalog) async {
    return getPlaylists();
  }

  Future<List<Track>> getRecommendationsFromCatalogData(
      Map<String, dynamic> catalog) async {
    return getRecommendations();
  }

  Future<Mix?> getMixFromCatalogData(Map<String, dynamic> catalog) async {
    return getMix();
  }

  // ==========================================
  // Helpers
  // ==========================================

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