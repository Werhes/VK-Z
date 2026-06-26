import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/mix.dart';
import '../models/mix_settings.dart';
import 'vk_config.dart';

/// VK API Service
///
/// Чистый Dart VK API клиент на Dio.
/// Использует прямые HTTP-запросы к VK API v5.131.
/// Авторизация через Kate Mobile (bypass audio).
///
/// API v5.131, Kate Mobile User-Agent, GET-запросы к api.vk.com/method/
/// Прямые методы audio.* (как в Python-скрипте vk_client.py)
///
/// Токен хранится в flutter_secure_storage (Android Keystore / iOS Keychain).
class VkApiService {
  String? _accessToken;
  int? _userId;
  late final Dio _dio;
  late final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'vk_access_token';
  static const String _userIdKey = 'vk_user_id';

  VkApiService() {
    _secureStorage = const FlutterSecureStorage();

    _dio = Dio(BaseOptions(
      baseUrl: VkConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent': VkConfig.userAgent,
        'Accept-Language': 'ru',
      },
    ));

    debugPrint('📡 VK API Service initialized (Dio)');
  }

  bool get isAuthorized => _accessToken != null;
  int? get userId => _userId;
  String? get accessToken => _accessToken;

  void setToken(String token, {int? userId}) {
    _accessToken = token;
    _userId = userId;
    _saveSession();
  }

  void clearToken() {
    _accessToken = null;
    _userId = null;
    _clearSession();
  }

  Future<bool> tryRestoreSession() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final userIdStr = await _secureStorage.read(key: _userIdKey);

      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _userId = userIdStr != null ? int.tryParse(userIdStr) : null;
        debugPrint(
            'Session restored: token=${token.substring(0, 10)}..., userId=$_userId');
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
    } catch (e) {
      debugPrint('Failed to save session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userIdKey);
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }

  /// Единая точка вызова VK API.
  Future<dynamic> _call(String method, {Map<String, dynamic>? params}) async {
    if (_accessToken == null) {
      throw Exception('Not authorized');
    }

    final queryParams = <String, dynamic>{
      'access_token': _accessToken,
      'v': VkConfig.apiVersion,
      'lang': 'ru',
      if (params != null) ...params,
    };

    debugPrint('VK API GET: $method');

    try {
      final response = await _dio.get(
        '/$method',
        queryParameters: queryParams,
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response type: ${data.runtimeType}');
      }

      if (data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        final errorMsg =
            'VK API Error [${error['error_code']}]: ${error['error_msg']}';
        debugPrint(errorMsg);
        throw Exception(errorMsg);
      }

      return data['response'] ?? data;
    } on DioException catch (e) {
      debugPrint('Dio error: $e');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Network timeout');
      }
      throw Exception('Network error: ${e.message}');
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
    final params = <String, dynamic>{
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
    final params = <String, dynamic>{
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
    final params = <String, dynamic>{
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
    final params = <String, dynamic>{
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
    final params = <String, dynamic>{
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
      final params = <String, dynamic>{
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
      final params = <String, dynamic>{
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
      final params = <String, dynamic>{
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