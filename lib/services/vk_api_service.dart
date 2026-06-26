import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/mix.dart';
import '../models/mix_settings.dart';
import 'vk_config.dart';

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
  /// Использует GET-запросы как в Python-скрипте (Kate Mobile подход).
  /// API v5.131 — audio.* методы работают напрямую.
  Future<dynamic> _call({
    required String method,
    Map<String, dynamic>? params,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authorized');
    }

    final queryParams = <String, String>{
      'access_token': _accessToken!,
      'v': VkConfig.apiVersion,
      'lang': 'ru',
    };

    if (params != null) {
      for (final entry in params.entries) {
        queryParams[entry.key] = entry.value.toString();
      }
    }

    final uri = Uri.parse('${VkConfig.apiBaseUrl}/$method')
        .replace(queryParameters: queryParams);

    debugPrint('VK API call: $method');

    final request = http.Request('GET', uri);
    request.headers.addAll(VkConfig.extraHeaders);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Check for API errors
    if (data.containsKey('error')) {
      final error = data['error'] as Map<String, dynamic>;
      throw Exception(
          'VK API Error ${error['error_code']}: ${error['error_msg']}');
    }

    return data['response'] ?? data;
  }

  // ==========================================
  // User
  // ==========================================

  /// Get current user info
  Future<Map<String, dynamic>> getCurrentUser() async {
    final data = await _call(
      method: 'users.get',
      params: {'fields': 'photo_100'},
    );
    if (data is List && data.isNotEmpty) {
      return data[0] as Map<String, dynamic>;
    }
    return {};
  }

  // ==========================================
  // Audio methods — прямые, как в Python-скрипте
  // API v5.131 — audio.* работают с Kate Mobile токеном
  // ==========================================

  /// Get user's audio tracks — прямой audio.get
  Future<List<Track>> getTracks({
    int? ownerId,
    int offset = 0,
    int count = 100,
  }) async {
    try {
      final params = <String, dynamic>{
        'owner_id': ownerId ?? _userId,
        'offset': offset,
        'count': count,
      };

      final data = await _call(method: 'audio.get', params: params);
      final items = (data is Map ? data['items'] : data) as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('audio.get failed: $e');
      return [];
    }
  }

  /// Get ALL audio tracks (paginated, like Python get_audio_all)
  Future<List<Track>> getAllTracks({int? ownerId}) async {
    try {
      // First request to get total count
      final first = await _call(
        method: 'audio.get',
        params: {'owner_id': ownerId ?? _userId, 'count': 1},
      );
      final total = (first is Map ? first['count'] : 0) as int? ?? 0;
      if (total == 0) return [];

      // Fetch all pages in parallel
      final tasks = <Future<List<Track>>>[];
      for (int off = 0; off < total; off += 100) {
        tasks.add(getTracks(ownerId: ownerId, offset: off, count: 100));
      }

      final results = await Future.wait(tasks);
      final allTracks = <Track>[];
      for (final tracks in results) {
        allTracks.addAll(tracks);
      }
      return allTracks;
    } catch (e) {
      debugPrint('getAllTracks failed: $e');
      return [];
    }
  }

  /// Search tracks — прямой audio.search
  Future<List<Track>> searchTracks({
    required String query,
    int offset = 0,
    int count = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'q': query,
        'count': count,
        'offset': offset,
        'auto_complete': 1,
        'sort': 2, // по популярности
      };

      final data = await _call(method: 'audio.search', params: params);
      final items = (data is Map ? data['items'] : data) as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('audio.search failed: $e');
      return [];
    }
  }

  /// Get recommendations — прямой audio.getRecommendations
  Future<List<Track>> getRecommendations({
    String? targetAudio,
    int count = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'count': count,
        'shuffle': 1,
      };
      if (targetAudio != null) {
        params['target_audio'] = targetAudio;
      } else {
        params['user_id'] = _userId;
      }

      final data =
          await _call(method: 'audio.getRecommendations', params: params);
      final items = (data is Map ? data['items'] : data) as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('audio.getRecommendations failed: $e');
      return [];
    }
  }

  // ==========================================
  // Playlists — прямой audio.getPlaylists
  // ==========================================

  /// Get playlists — прямой audio.getPlaylists
  Future<List<Playlist>> getPlaylists({
    int? ownerId,
    int offset = 0,
    int count = 200,
  }) async {
    try {
      final params = <String, dynamic>{
        'owner_id': ownerId ?? _userId,
        'offset': offset,
        'count': count,
      };

      final data = await _call(method: 'audio.getPlaylists', params: params);
      final items = (data is Map ? data['items'] : data) as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Playlist.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('audio.getPlaylists failed: $e');
      return [];
    }
  }

  /// Get tracks from a specific playlist — прямой audio.get с playlist_id
  Future<List<Track>> getPlaylistTracks({
    required int playlistId,
    required int ownerId,
    String? accessKey,
    int offset = 0,
    int count = 2000,
  }) async {
    try {
      final params = <String, dynamic>{
        'owner_id': ownerId,
        'playlist_id': playlistId,
        'count': count,
      };
      if (accessKey != null && accessKey.isNotEmpty) {
        params['access_key'] = accessKey;
      }

      final data = await _call(method: 'audio.get', params: params);
      final items = (data is Map ? data['items'] : data) as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('audio.get (playlist) failed: $e');
      return [];
    }
  }

  // ==========================================
  // Catalog methods — только для VK Mix
  // ==========================================

  /// Get audio catalog — для VK Mix (как в Python get_vk_mixes)
  Future<Map<String, dynamic>> getCatalog({
    String? userId,
  }) async {
    final params = <String, dynamic>{
      'need_blocks': 1,
    };
    if (userId != null) params['user_id'] = userId;

    final data = await _call(method: 'catalog.getAudio', params: params);
    return data is Map<String, dynamic> ? data : {};
  }

  // ==========================================
  // Mix — audio.getStreamMixAudios
  // ==========================================

  /// Get VK Mix — прямой audio.getStreamMixAudios
  Future<Mix?> getMix() async {
    try {
      // Try audio.getStreamMixAudios first
      try {
        final params = <String, dynamic>{
          'mix_id': 'common',
          'append': 0,
          'count': 50,
        };
        final data = await _call(
            method: 'audio.getStreamMixAudios', params: params);
        final items = (data is Map ? data['items'] : data) as List? ?? [];
        if (items.isNotEmpty) {
          final tracks = items
              .whereType<Map<String, dynamic>>()
              .map((e) => Track.fromJson(e))
              .toList();
          if (tracks.isNotEmpty) {
            return Mix(
              id: 'stream_mix',
              title: 'Мой Микс',
              tracks: tracks,
            );
          }
        }
      } catch (e) {
        debugPrint('audio.getStreamMixAudios failed: $e');
      }

      // Fallback: get recommendations as mix
      final recommendations = await getRecommendations(count: 50);
      if (recommendations.isNotEmpty) {
        return Mix(
          id: 'recommendations',
          title: 'Микс дня',
          description: 'Персональные рекомендации для вас',
          tracks: recommendations,
        );
      }

      // Final fallback: shuffle user's tracks
      final allTracks = await getTracks(count: 100);
      if (allTracks.length >= 5) {
        allTracks.shuffle();
        return Mix(
          id: 'my_music_mix',
          title: 'Мой Микс',
          description: 'Ваши треки в случайном порядке',
          tracks: allTracks.take(30).toList(),
        );
      }

      return null;
    } catch (e) {
      debugPrint('getMix failed: $e');
      return null;
    }
  }

  // ==========================================
  // Mix Settings — audio.getStreamMixSettings
  // ==========================================

  /// Get VK Mix settings
  Future<MixSettingsRoot?> getStreamMixSettings(String mixId) async {
    try {
      final params = <String, dynamic>{
        'mix_id': mixId,
      };

      final data = await _call(
          method: 'audio.getStreamMixSettings', params: params);

      if (data is Map<String, dynamic>) {
        return MixSettingsRoot.fromJson(data);
      }

      return null;
    } catch (e) {
      debugPrint('audio.getStreamMixSettings failed: $e');
      return null;
    }
  }

  // ==========================================
  // Audio management
  // ==========================================

  /// Add track to library
  Future<bool> addAudio(int audioId, int ownerId) async {
    try {
      await _call(
        method: 'audio.add',
        params: {'audio_id': audioId, 'owner_id': ownerId},
      );
      return true;
    } catch (e) {
      debugPrint('audio.add failed: $e');
      return false;
    }
  }

  /// Delete track from library
  Future<bool> deleteAudio(int audioId, int ownerId) async {
    try {
      await _call(
        method: 'audio.delete',
        params: {'audio_id': audioId, 'owner_id': ownerId},
      );
      return true;
    } catch (e) {
      debugPrint('audio.delete failed: $e');
      return false;
    }
  }

  // ==========================================
  // Methods that accept pre-fetched catalog data
  // (kept for backward compatibility with MusicProvider)
  // ==========================================

  /// Extract tracks from already-fetched catalog data
  Future<List<Track>> getTracksFromCatalogData(
      Map<String, dynamic> catalog) async {
    // With v5.131, we use direct audio.get instead
    return getTracks();
  }

  /// Extract playlists from already-fetched catalog data
  Future<List<Playlist>> getPlaylistsFromCatalogData(
      Map<String, dynamic> catalog) async {
    // With v5.131, we use direct audio.getPlaylists instead
    return getPlaylists();
  }

  /// Extract recommendations from already-fetched catalog data
  Future<List<Track>> getRecommendationsFromCatalogData(
      Map<String, dynamic> catalog) async {
    // With v5.131, we use direct audio.getRecommendations instead
    return getRecommendations();
  }

  /// Extract mix from already-fetched catalog data
  Future<Mix?> getMixFromCatalogData(Map<String, dynamic> catalog) async {
    // With v5.131, we use direct audio.getStreamMixAudios instead
    return getMix();
  }
}