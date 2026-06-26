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
  String? _deviceId;

  static const String _tokenKey = 'vk_access_token';
  static const String _userIdKey = 'vk_user_id';
  static const String _deviceIdKey = 'vk_device_id';

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
    _deviceId = null;
    _clearSession();
  }

  /// Пытается восстановить сессию из shared_preferences
  Future<bool> tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userId = prefs.getInt(_userIdKey);
      final deviceId = prefs.getString(_deviceIdKey);

      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        _userId = userId;
        _deviceId = deviceId;
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
      if (_deviceId != null) {
        await prefs.setString(_deviceIdKey, _deviceId!);
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
      await prefs.remove(_deviceIdKey);
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }

  /// Get or generate device ID
  String get _deviceIdValue {
    _deviceId ??= VkConfig.generateDeviceId();
    return _deviceId!;
  }

  /// Make an HTTP POST request with VK Android App headers
  Future<http.Response> _makeRequest(Uri uri, Map<String, String> bodyParams) async {
    final request = http.Request('POST', uri);

    // Add VK Android App headers
    request.headers.addAll(VkConfig.extraHeaders);
    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';

    request.bodyFields = bodyParams;

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  /// Direct API call with VK Android App headers and device_id
  Future<Map<String, dynamic>> _call({
    required String method,
    Map<String, String>? params,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authorized');
    }

    final bodyParams = <String, String>{
      'access_token': _accessToken!,
      'v': VkConfig.apiVersion,
      'lang': 'ru',
      'device_id': _deviceIdValue,
      ...?params,
    };

    final uri = Uri.parse('${VkConfig.apiBaseUrl}/$method');

    debugPrint('VK API call: $method');
    final response = await _makeRequest(uri, bodyParams);

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

    return data;
  }

  // ==========================================
  // Catalog methods
  // ==========================================

  /// Get audio catalog
  Future<Map<String, dynamic>> getCatalog({
    String? userId,
  }) async {
    final params = <String, String>{
      'extended': '1',
    };
    if (userId != null) params['user_id'] = userId;

    final data = await _call(method: 'catalog.getAudio', params: params);

    // Debug: log the catalog structure in detail
    try {
      debugPrint('=== CATALOG RESPONSE DEBUG ===');
      debugPrint('Catalog top-level keys: ${data.keys.join(', ')}');
      if (data['response'] != null) {
        final resp = data['response'];
        debugPrint('Response type: ${resp.runtimeType}');
        if (resp is Map) {
          debugPrint('Response keys: ${resp.keys.join(', ')}');
          if (resp['sections'] is List) {
            final sections = resp['sections'] as List;
            debugPrint('Sections count: ${sections.length}');
            for (int i = 0; i < sections.length; i++) {
              final section = sections[i] as Map;
              debugPrint('  Section[$i] keys: ${section.keys.join(', ')}');
              debugPrint('  Section[$i] id: ${section['id']}');
              debugPrint('  Section[$i] title: ${section['title']}');
              // Check for tracks/items/audios
              for (final field in ['tracks', 'items', 'audios', 'music', 'list', 'data']) {
                if (section.containsKey(field)) {
                  final val = section[field];
                  debugPrint('  Section[$i] $field type: ${val.runtimeType}');
                  if (val is List) {
                    debugPrint('  Section[$i] $field length: ${val.length}');
                    if (val.isNotEmpty && val.first is Map) {
                      debugPrint('  Section[$i] $field[0] keys: ${(val.first as Map).keys.join(', ')}');
                    }
                  }
                }
              }
              // Check for playlists/albums
              for (final field in ['playlists', 'albums', 'collections', 'lists']) {
                if (section.containsKey(field)) {
                  final val = section[field];
                  debugPrint('  Section[$i] $field type: ${val.runtimeType}');
                  if (val is List) {
                    debugPrint('  Section[$i] $field length: ${val.length}');
                  }
                }
              }
            }
          } else {
            debugPrint('Response is not a Map with sections');
            final respStr = resp.toString();
            debugPrint('Response content: ${respStr.substring(0, respStr.length > 2000 ? 2000 : respStr.length)}');
          }
        } else if (resp is List) {
          debugPrint('Response is a List with ${resp.length} items');
          if (resp.isNotEmpty && resp.first is Map) {
            debugPrint('First item keys: ${(resp.first as Map).keys.join(', ')}');
          }
        }
      } else {
        debugPrint('No "response" key in data');
        debugPrint('Data keys: ${data.keys.join(', ')}');
      }
      debugPrint('=== END CATALOG DEBUG ===');
    } catch (e) {
      debugPrint('Debug catalog error: $e');
    }

    return data;
  }

  /// Get catalog section
  Future<Map<String, dynamic>> getSection({
    required String sectionId,
    String? startFrom,
  }) async {
    final params = <String, String>{
      'extended': '1',
      'section_id': sectionId,
      'need_blocks': '1',
    };
    if (startFrom != null) params['start_from'] = startFrom;

    return await _call(method: 'catalog.getSection', params: params);
  }

  /// Get block items
  Future<Map<String, dynamic>> getBlockItems({
    required String blockId,
  }) async {
    final params = <String, String>{
      'extended': '1',
      'block_id': blockId,
    };

    return await _call(method: 'catalog.getBlockItems', params: params);
  }

  // ==========================================
  // Audio methods
  // ==========================================

  /// Get user's audio tracks
  Future<List<Track>> getTracks({
    int? ownerId,
    int offset = 0,
    int count = 50,
  }) async {
    try {
      final params = <String, String>{
        'offset': offset.toString(),
        'count': count.toString(),
      };
      if (ownerId != null) params['owner_id'] = ownerId.toString();

      final data = await _call(method: 'audio.get', params: params);
      final response = data['response'];
      if (response is Map) {
        final items = response['items'] as List? ?? [];
        if (items.isNotEmpty) {
          return items
              .whereType<Map<String, dynamic>>()
              .map((e) => Track.fromJson(e))
              .toList();
        }
      } else if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map((e) => Track.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('audio.get failed, falling back to catalog: $e');
    }

    // Fallback: extract tracks from catalog
    return _getTracksFromCatalog();
  }

  /// Extract user's tracks from the catalog
  Future<List<Track>> _getTracksFromCatalog() async {
    try {
      final catalog = await getCatalog();
      final responseData = catalog['response'];

      if (responseData == null) {
        debugPrint('Catalog response is null');
        return [];
      }

      // The response might be a Map or a List
      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }

      debugPrint('Catalog sections count: ${sections.length}');

      if (sections.isEmpty) {
        return _extractTracksFromResponse(responseData);
      }

      // First pass: look for sections with user's music
      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = _getStringValue(section, 'id');
        final sectionTitle = _getStringValue(section, 'title');

        debugPrint('Section: id=$sectionId, title=$sectionTitle');

        final tracks = _extractTracksFromSection(section);
        if (tracks.isNotEmpty && _isUserMusicSection(sectionId, sectionTitle)) {
          debugPrint('Found ${tracks.length} tracks in section: $sectionId');
          return tracks;
        }
      }

      // Second pass: collect all unique tracks from all sections
      final allTracks = <Track>[];
      final seenIds = <String>{};
      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final tracks = _extractTracksFromSection(section);
        for (final track in tracks) {
          final key = '${track.ownerId}_${track.id}';
          if (seenIds.add(key)) {
            allTracks.add(track);
          }
        }
      }

      debugPrint('Total unique tracks from all sections: ${allTracks.length}');
      return allTracks;
    } catch (e) {
      debugPrint('Failed to extract tracks from catalog: $e');
      return [];
    }
  }

  /// Check if a section contains user's personal music
  bool _isUserMusicSection(String sectionId, String sectionTitle) {
    final lowerId = sectionId.toLowerCase();
    final lowerTitle = sectionTitle.toLowerCase();

    return lowerId.contains('my') ||
        lowerId.contains('recent') ||
        lowerId.contains('favorite') ||
        lowerId.contains('likes') ||
        lowerId.contains('own') ||
        lowerId.contains('user') ||
        lowerTitle.contains('моя') ||
        lowerTitle.contains('мои') ||
        lowerTitle.contains('недав') ||
        lowerTitle.contains('любим') ||
        lowerTitle.contains('избран');
  }

  /// Extract tracks from a section, trying multiple possible field names
  List<Track> _extractTracksFromSection(Map<String, dynamic> section) {
    final possibleFields = ['tracks', 'items', 'audios', 'music', 'list', 'data'];

    for (final field in possibleFields) {
      final tracks = section[field];
      if (tracks is List && tracks.isNotEmpty) {
        final result = tracks
            .whereType<Map<String, dynamic>>()
            .map((e) => Track.fromJson(e))
            .toList();
        if (result.isNotEmpty) return result;
      }
    }

    return [];
  }

  /// Extract tracks from a non-sections response
  List<Track> _extractTracksFromResponse(dynamic responseData) {
    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    }
    if (responseData is Map<String, dynamic>) {
      for (final field in ['items', 'tracks', 'audios', 'music', 'list']) {
        final items = responseData[field];
        if (items is List && items.isNotEmpty) {
          return items
              .whereType<Map<String, dynamic>>()
              .map((e) => Track.fromJson(e))
              .toList();
        }
      }
    }
    return [];
  }

  /// Safe string getter from a map
  String _getStringValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    return '';
  }

  // ==========================================
  // Playlists
  // ==========================================

  /// Get playlists
  Future<List<Playlist>> getPlaylists({
    int? ownerId,
    int offset = 0,
    int count = 50,
  }) async {
    try {
      final params = <String, String>{
        'offset': offset.toString(),
        'count': count.toString(),
      };
      if (ownerId != null) params['owner_id'] = ownerId.toString();

      final data = await _call(method: 'audio.getPlaylists', params: params);
      final response = data['response'];
      if (response is Map) {
        final items = response['items'] as List? ?? [];
        if (items.isNotEmpty) {
          return items
              .whereType<Map<String, dynamic>>()
              .map((e) => Playlist.fromJson(e))
              .toList();
        }
      } else if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map((e) => Playlist.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('audio.getPlaylists failed, falling back to catalog: $e');
    }

    // Fallback: extract playlists from catalog
    return _getPlaylistsFromCatalog();
  }

  /// Extract playlists from catalog sections
  Future<List<Playlist>> _getPlaylistsFromCatalog() async {
    try {
      final catalog = await getCatalog();
      final responseData = catalog['response'];

      if (responseData == null) return [];

      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }

      final playlists = <Playlist>[];

      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;

        for (final field in ['playlists', 'albums', 'collections', 'lists']) {
          final items = section[field] as List? ?? [];
          for (final item in items) {
            if (item is! Map<String, dynamic>) continue;
            try {
              playlists.add(Playlist.fromJson(item));
            } catch (e) {
              debugPrint('Failed to parse playlist: $e');
            }
          }
        }
      }

      return playlists;
    } catch (e) {
      debugPrint('Failed to extract playlists from catalog: $e');
      return [];
    }
  }

  /// Get tracks from a specific playlist
  Future<List<Track>> getPlaylistTracks({
    required int playlistId,
    required int ownerId,
    String? accessKey,
    int offset = 0,
    int count = 100,
  }) async {
    try {
      final params = <String, String>{
        'playlist_id': playlistId.toString(),
        'owner_id': ownerId.toString(),
        'offset': offset.toString(),
        'count': count.toString(),
        'audio_count': count.toString(),
        'need_playlist': '1',
        'func_v': '10',
        'need_owner': '1',
      };
      if (accessKey != null) params['access_key'] = accessKey;

      final data = await _call(method: 'execute.getPlaylist', params: params);
      final response = data['response'];
      if (response is Map) {
        final items = response['items'] as List? ?? [];
        return items
            .whereType<Map<String, dynamic>>()
            .map((e) => Track.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('execute.getPlaylist failed: $e');
    }
    return [];
  }

  // ==========================================
  // Search
  // ==========================================

  /// Search tracks
  Future<List<Track>> searchTracks({
    required String query,
    int offset = 0,
    int count = 50,
  }) async {
    try {
      final params = <String, String>{
        'extended': '1',
        'q': query,
        'offset': offset.toString(),
        'count': count.toString(),
      };

      final data =
          await _call(method: 'catalog.getAudioSearch', params: params);
      final responseData = data['response'];

      if (responseData == null) return [];

      // Try to extract tracks from the response
      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }

      // Search results are typically in the first section with tracks
      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final tracks = _extractTracksFromSection(section);
        if (tracks.isNotEmpty) return tracks;
      }

      // Fallback: try items directly
      if (responseData is Map<String, dynamic>) {
        final items = responseData['items'] as List? ?? [];
        if (items.isNotEmpty) {
          return items
              .whereType<Map<String, dynamic>>()
              .map((e) => Track.fromJson(e))
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('catalog.getAudioSearch failed: $e');
      return [];
    }
  }

  // ==========================================
  // Recommendations
  // ==========================================

  /// Get recommended tracks
  Future<List<Track>> getRecommendations({
    int offset = 0,
    int count = 50,
  }) async {
    try {
      final params = <String, String>{
        'offset': offset.toString(),
        'count': count.toString(),
      };
      final data =
          await _call(method: 'audio.getRecommendations', params: params);
      final response = data['response'];
      if (response is Map) {
        final items = response['items'] as List? ?? [];
        if (items.isNotEmpty) {
          return items
              .whereType<Map<String, dynamic>>()
              .map((e) => Track.fromJson(e))
              .toList();
        }
      } else if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map((e) => Track.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint(
          'audio.getRecommendations failed, falling back to catalog: $e');
    }

    return _getRecommendationsFromCatalog();
  }

  /// Extract recommendations from catalog
  Future<List<Track>> _getRecommendationsFromCatalog() async {
    try {
      final catalog = await getCatalog();
      final responseData = catalog['response'];

      if (responseData == null) return [];

      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }

      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = _getStringValue(section, 'id').toLowerCase();
        final sectionTitle = _getStringValue(section, 'title').toLowerCase();

        if (sectionId.contains('recommend') ||
            sectionId.contains('discover') ||
            sectionId.contains('popular') ||
            sectionId.contains('new') ||
            sectionTitle.contains('рекоменд') ||
            sectionTitle.contains('популяр') ||
            sectionTitle.contains('новин')) {
          final tracks = _extractTracksFromSection(section);
          if (tracks.isNotEmpty) {
            debugPrint(
                'Found ${tracks.length} recommendations in section: $sectionId');
            return tracks;
          }
        }
      }

      return [];
    } catch (e) {
      debugPrint('Failed to extract recommendations from catalog: $e');
      return [];
    }
  }

  // ==========================================
  // Mix Settings
  // ==========================================

  /// Get VK Mix settings
  Future<MixSettingsRoot?> getStreamMixSettings(String mixId) async {
    try {
      final params = <String, String>{
        'device_id': _deviceIdValue,
        'mix_id': mixId,
      };

      final data = await _call(
          method: 'audio.getStreamMixSettings', params: params);

      if (data['response'] != null) {
        final response = data['response'];
        if (response is Map<String, dynamic>) {
          return MixSettingsRoot.fromJson(response);
        }
      }

      return null;
    } catch (e) {
      debugPrint('audio.getStreamMixSettings failed: $e');
      return null;
    }
  }

  // ==========================================
  // Mix
  // ==========================================

  /// Get VK Mix
  Future<Mix?> getMix() async {
    try {
      // First try to get mix from catalog
      final catalog = await getCatalog();
      final mixFromCatalog = _getMixFromCatalogData(catalog);
      if (mixFromCatalog != null) return mixFromCatalog;

      // Fallback: try audio.getStreamMixAudios
      try {
        final params = <String, String>{
          'mix_id': 'common',
          'append': '0',
          'count': '50',
        };
        final data = await _call(
            method: 'audio.getStreamMixAudios', params: params);
        final response = data['response'];
        final items = (response is Map ? response['items'] : response) as List? ?? [];
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

      // Final fallback: create mix from catalog tracks
      final allTracks = await _getTracksFromCatalog();
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

  /// Extract mix from catalog data
  Mix? _getMixFromCatalogData(Map<String, dynamic> catalog) {
    try {
      final responseData = catalog['response'];
      if (responseData == null) return null;

      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }

      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = _getStringValue(section, 'id').toLowerCase();
        final sectionTitle = _getStringValue(section, 'title');

        if (sectionId.contains('mix') ||
            sectionId.contains('recommended') ||
            sectionTitle.toLowerCase().contains('микс')) {
          final tracks = _extractTracksFromSection(section);

          if (tracks.isNotEmpty) {
            return Mix(
              id: sectionId,
              title: section['title'] as String? ?? 'Микс',
              description: section['subtitle'] as String?,
              coverUrl: _extractSectionCover(section),
              tracks: tracks,
            );
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('getMixFromCatalogData failed: $e');
      return null;
    }
  }

  String? _extractSectionCover(Map<String, dynamic> section) {
    if (section['photo'] != null) {
      final photo = section['photo'] as Map<String, dynamic>;
      if (photo['photo_600'] != null) return photo['photo_600'] as String;
      if (photo['photo_300'] != null) return photo['photo_300'] as String;
      if (photo['photo_120'] != null) return photo['photo_120'] as String;
      if (photo['photo_68'] != null) return photo['photo_68'] as String;
    }
    if (section['cover'] != null) {
      final cover = section['cover'] as Map<String, dynamic>;
      if (cover['url'] != null) return cover['url'] as String;
    }
    return null;
  }

  // ==========================================
  // Other methods
  // ==========================================

  /// Get audio by ID
  Future<List<Track>> getAudioById({
    required List<String> audioIds,
  }) async {
    try {
      final params = <String, String>{
        'audios': audioIds.join(','),
      };
      final data = await _call(method: 'audio.getById', params: params);
      final response = data['response'];
      final items = (response is Map ? response['items'] : response) as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('getAudioById failed: $e');
      return [];
    }
  }

  // ==========================================
  // Methods that accept pre-fetched catalog data
  // ==========================================

  /// Extract tracks from already-fetched catalog data
  Future<List<Track>> getTracksFromCatalogData(
      Map<String, dynamic> catalog) async {
    return _getTracksFromCatalogData(catalog);
  }

  /// Extract playlists from already-fetched catalog data
  Future<List<Playlist>> getPlaylistsFromCatalogData(
      Map<String, dynamic> catalog) async {
    return _getPlaylistsFromCatalogData(catalog);
  }

  /// Extract recommendations from already-fetched catalog data
  Future<List<Track>> getRecommendationsFromCatalogData(
      Map<String, dynamic> catalog) async {
    return _getRecommendationsFromCatalogData(catalog);
  }

  /// Extract mix from already-fetched catalog data
  Future<Mix?> getMixFromCatalogData(Map<String, dynamic> catalog) async {
    return _getMixFromCatalogData(catalog);
  }

  /// Internal: extract tracks from catalog data
  Future<List<Track>> _getTracksFromCatalogData(
      Map<String, dynamic> catalog) async {
    try {
      final responseData = catalog['response'];
      if (responseData == null) {
        debugPrint('Catalog response is null');
        return [];
      }

      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }

      if (sections.isEmpty) {
        return _extractTracksFromResponse(responseData);
      }

      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = _getStringValue(section, 'id');
        final sectionTitle = _getStringValue(section, 'title');

        final tracks = _extractTracksFromSection(section);
        if (tracks.isNotEmpty && _isUserMusicSection(sectionId, sectionTitle)) {
          return tracks;
        }
      }

      final allTracks = <Track>[];
      final seenIds = <String>{};
      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final tracks = _extractTracksFromSection(section);
        for (final track in tracks) {
          final key = '${track.ownerId}_${track.id}';
          if (seenIds.add(key)) {
            allTracks.add(track);
          }
        }
      }

      return allTracks;
    } catch (e) {
      debugPrint('Failed to extract tracks from catalog data: $e');
      return [];
    }
  }

  /// Internal: extract playlists from catalog data
  Future<List<Playlist>> _getPlaylistsFromCatalogData(
      Map<String, dynamic> catalog) async {
    try {
      final responseData = catalog['response'];
      if (responseData == null) return [];

      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }

      final playlists = <Playlist>[];

      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;

        for (final field in ['playlists', 'albums', 'collections', 'lists']) {
          final items = section[field] as List? ?? [];
          for (final item in items) {
            if (item is! Map<String, dynamic>) continue;
            try {
              playlists.add(Playlist.fromJson(item));
            } catch (e) {
              debugPrint('Failed to parse playlist: $e');
            }
          }
        }
      }

      return playlists;
    } catch (e) {
      debugPrint('Failed to extract playlists from catalog data: $e');
      return [];
    }
  }

  /// Internal: extract recommendations from catalog data
  Future<List<Track>> _getRecommendationsFromCatalogData(
      Map<String, dynamic> catalog) async {
    try {
      final responseData = catalog['response'];
      if (responseData == null) return [];

      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }

      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = _getStringValue(section, 'id').toLowerCase();
        final sectionTitle = _getStringValue(section, 'title').toLowerCase();

        if (sectionId.contains('recommend') ||
            sectionId.contains('discover') ||
            sectionId.contains('popular') ||
            sectionId.contains('new') ||
            sectionTitle.contains('рекоменд') ||
            sectionTitle.contains('популяр') ||
            sectionTitle.contains('новин')) {
          final tracks = _extractTracksFromSection(section);
          if (tracks.isNotEmpty) {
            return tracks;
          }
        }
      }

      return [];
    } catch (e) {
      debugPrint('Failed to extract recommendations from catalog data: $e');
      return [];
    }
  }
}