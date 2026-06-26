import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/mix.dart';
import '../models/mix_settings.dart';
import 'vk_config.dart';
import 'rust_vk_api.dart';

/// VK API Service
///
/// Использует Rust VK API клиент через FFI (если библиотека загружена),
/// иначе fallback на чистый Dart HttpClient.
///
/// Rust-клиент — прямой порт рабочего Python-скрипта vk_client.py:
/// - API v5.131
/// - Kate Mobile User-Agent
/// - GET-запросы к api.vk.ru/method/
/// - Прямые методы audio.*
class VkApiService {
  String? _accessToken;
  int? _userId;
  HttpClient? _dartClient;
  final RustVkApi _rustApi = RustVkApi.instance;
  bool _useRust = false;

  static const String _tokenKey = 'vk_access_token';
  static const String _userIdKey = 'vk_user_id';

  VkApiService() {
    // Пытаемся загрузить Rust-библиотеку
    _useRust = _rustApi.tryLoad();
    if (_useRust) {
      debugPrint('🚀 Using Rust VK API client');
    } else {
      debugPrint('📡 Using Dart HttpClient fallback');
      _dartClient = HttpClient()
        ..userAgent = VkConfig.userAgent
        ..connectionTimeout = const Duration(seconds: 30)
        ..idleTimeout = const Duration(seconds: 15);
    }
  }

  bool get isAuthorized => _accessToken != null;
  int? get userId => _userId;
  String? get accessToken => _accessToken;

  void setToken(String token, {int? userId}) {
    _accessToken = token;
    _userId = userId;
    _saveSession();
    // Передаём токен в Rust, если он загружен
    if (_useRust) {
      _rustApi.setToken(token, userId);
    }
  }

  void clearToken() {
    _accessToken = null;
    _userId = null;
    _clearSession();
  }

  Future<bool> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userId = prefs.getInt(_userIdKey);

      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _userId = userId;
        if (_useRust) {
          _rustApi.setToken(token, userId);
        }
        debugPrint(
            'Session restored: token=${token.substring(0, 10)}..., userId=$userId');
        return true;
      }
    } catch (e) {
      debugPrint('Failed to restore session: $e');
    }
    return false;
  }

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
  /// Сначала пробует Rust, если не получилось — Dart HttpClient.
  Future<dynamic> _call(String method, {Map<String, String>? params}) async {
    if (_accessToken == null) {
      throw Exception('Not authorized');
    }

    // Пробуем Rust
    if (_useRust) {
      try {
        final result = await _rustApi.callRust(method, params ?? {});
        if (result != null) {
          return result;
        }
      } catch (e) {
        debugPrint('Rust call failed, falling back to Dart: $e');
      }
    }

    // Fallback: Dart HttpClient
    return _dartCall(method, params: params);
  }

  /// Dart HttpClient реализация (как aiohttp в Python)
  Future<dynamic> _dartCall(String method, {Map<String, String>? params}) async {
    final queryParams = <String, String>{
      'access_token': _accessToken!,
      'v': VkConfig.apiVersion,
      'lang': 'ru',
      ...?params,
    };

    final uri = Uri.parse('${VkConfig.apiBaseUrl}/$method')
        .replace(queryParameters: queryParams);

    debugPrint('VK API GET: $method');
    debugPrint('URL: $uri');

    try {
      final request = await _dartClient!.getUrl(uri);
      request.headers.set('Accept-Language', 'ru');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('HTTP error body: $body');
        throw Exception('HTTP ${response.statusCode}: $body');
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (e) {
        debugPrint('JSON decode error: $e');
        debugPrint('Raw body (first 500): ${body.substring(0, body.length > 500 ? 500 : body.length)}');
        throw Exception('Failed to decode JSON response: $e');
      }

      if (decoded is! Map<String, dynamic>) {
        debugPrint('Response is not a Map: ${decoded.runtimeType}');
        throw Exception('Unexpected response type: ${decoded.runtimeType}');
      }

      if (decoded.containsKey('error')) {
        final error = decoded['error'] as Map<String, dynamic>;
        final errorMsg = 'VK API Error [${error['error_code']}]: ${error['error_msg']}';
        debugPrint(errorMsg);
        throw Exception(errorMsg);
      }

      final result = decoded['response'] ?? decoded;
      debugPrint('Response type: ${result.runtimeType}');
      if (result is Map) {
        debugPrint('Response keys: ${result.keys.join(', ')}');
        if (result.containsKey('items')) {
          final items = result['items'];
          debugPrint('Items type: ${items.runtimeType}, count: ${items is List ? items.length : 'N/A'}');
        }
        if (result.containsKey('count')) {
          debugPrint('Count: ${result['count']}');
        }
      } else if (result is List) {
        debugPrint('Response is List with ${result.length} items');
      }

      return result;
    } on SocketException catch (e) {
      debugPrint('Socket error: $e');
      throw Exception('Network error: $e');
    } on HttpException catch (e) {
      debugPrint('HTTP error: $e');
      throw Exception('HTTP error: $e');
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
    debugPrint('Parsed ${items.length} tracks from audio.get');
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
    debugPrint('Parsed ${items.length} playlists from audio.getPlaylists');
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
    debugPrint('Parsed ${items.length} recommendations');
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
      debugPrint('getStreamMixAudios failed: $e');
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
      debugPrint('getStreamMixSettings failed: $e');
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
      debugPrint('getMix failed: $e');
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
      debugPrint('getAudioById failed: $e');
      return [];
    }
  }

  // ==========================================
  // Catalog (заглушки для совместимости)
  // ==========================================

  Future<Map<String, dynamic>> getCatalog() async {
    debugPrint('getCatalog: not used, returning empty');
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