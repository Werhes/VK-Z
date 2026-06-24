import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/mix.dart';
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
        debugPrint('Session restored: token=${token.substring(0, 10)}..., userId=$userId');
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

  /// Generate a random device ID (like VK Android App does)
  String _generateDeviceId() {
    final random = Random();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Get or generate device ID
  String get _deviceIdValue {
    _deviceId ??= _generateDeviceId();
    return _deviceId!;
  }

  /// Make an HTTP GET request with VK Android App headers
  Future<http.Response> _makeRequest(Uri uri) async {
    final request = http.Request('GET', uri);
    
    // Add VK Android App headers (required to bypass audio.* restrictions)
    request.headers.addAll(VkConfig.extraHeaders);
    
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

    final queryParams = <String, String>{
      'access_token': _accessToken!,
      'v': VkConfig.apiVersion,
      'device_id': _deviceIdValue,
      ...?params,
    };

    final uri = Uri.parse('${VkConfig.apiBaseUrl}/$method')
        .replace(queryParameters: queryParams);

    debugPrint('VK API call: $method');
    final response = await _makeRequest(uri);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Check for API errors
    if (data.containsKey('error')) {
      final error = data['error'] as Map<String, dynamic>;
      throw Exception('VK API Error ${error['error_code']}: ${error['error_msg']}');
    }

    return data;
  }

  // Get user's audio catalog
  Future<Map<String, dynamic>> getCatalog({
    String? userId,
  }) async {
    final params = <String, String>{
      'extended': '1',
    };
    if (userId != null) params['user_id'] = userId;

    final data = await _call(method: 'audio.getCatalog', params: params);
    
    // Debug: log the catalog structure
    try {
      debugPrint('Catalog response keys: ${data.keys.join(', ')}');
      if (data['response'] != null) {
        final resp = data['response'];
        if (resp is Map) {
          debugPrint('Catalog response keys: ${resp.keys.join(', ')}');
          if (resp['sections'] is List) {
            final sections = resp['sections'] as List;
            debugPrint('Catalog sections count: ${sections.length}');
            if (sections.isNotEmpty && sections.first is Map) {
              final first = sections.first as Map;
              debugPrint('First section keys: ${first.keys.join(', ')}');
              debugPrint('First section id: ${first['id']}');
              debugPrint('First section title: ${first['title']}');
            }
          }
        } else if (resp is List) {
          debugPrint('Catalog response is a List with ${resp.length} items');
          if (resp.isNotEmpty && resp.first is Map) {
            final first = resp.first as Map;
            debugPrint('First item keys: ${first.keys.join(', ')}');
          }
        }
      }
    } catch (e) {
      debugPrint('Debug catalog error: $e');
    }
    
    return data;
  }

  // Get user's audio tracks
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
      final items = data['response']?['items'] as List? ?? [];
      if (items.isNotEmpty) {
        return items
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
        // Some API versions return a list directly
        sections = responseData;
      }

      debugPrint('Catalog sections count: ${sections.length}');

      if (sections.isEmpty) {
        // Try to find tracks directly in response
        return _extractTracksFromResponse(responseData);
      }

      // First pass: look for sections with user's music
      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = _getStringValue(section, 'id');
        final sectionTitle = _getStringValue(section, 'title');
        
        debugPrint('Section: id=$sectionId, title=$sectionTitle');

        // Check various possible field names for tracks
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
    // Try different possible field names for tracks
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

  // Get playlists from catalog
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
      final items = data['response']?['items'] as List? ?? [];
      if (items.isNotEmpty) {
        return items
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

        // Try different field names for playlists/albums
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

  // Get tracks from a specific playlist
  Future<List<Track>> getPlaylistTracks({
    required int playlistId,
    required int ownerId,
    int offset = 0,
    int count = 100,
  }) async {
    try {
      final params = <String, String>{
        'playlist_id': playlistId.toString(),
        'owner_id': ownerId.toString(),
        'offset': offset.toString(),
        'count': count.toString(),
      };
      final data = await _call(method: 'audio.getPlaylistTracks', params: params);
      final items = data['response']?['items'] as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('audio.getPlaylistTracks failed: $e');
      return [];
    }
  }

  // Search tracks
  Future<List<Track>> searchTracks({
    required String query,
    int offset = 0,
    int count = 50,
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'offset': offset.toString(),
        'count': count.toString(),
        'autocomplete': '1',
        'sort': '2',
      };
      final data = await _call(method: 'audio.search', params: params);
      final items = data['response']?['items'] as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('audio.search failed: $e');
      return [];
    }
  }

  // Get recommended tracks
  Future<List<Track>> getRecommendations({
    int offset = 0,
    int count = 50,
  }) async {
    try {
      final params = <String, String>{
        'offset': offset.toString(),
        'count': count.toString(),
      };
      final data = await _call(method: 'audio.getRecommendations', params: params);
      final items = data['response']?['items'] as List? ?? [];
      if (items.isNotEmpty) {
        return items
            .whereType<Map<String, dynamic>>()
            .map((e) => Track.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('audio.getRecommendations failed, falling back to catalog: $e');
    }

    // Fallback: extract recommendations from catalog
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
            debugPrint('Found ${tracks.length} recommendations in section: $sectionId');
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

  // Get popular tracks
  Future<List<Track>> getPopular({
    int offset = 0,
    int count = 50,
  }) async {
    try {
      final params = <String, String>{
        'offset': offset.toString(),
        'count': count.toString(),
      };
      final data = await _call(method: 'audio.getPopular', params: params);
      final items = data['response'] as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('getPopular failed: $e');
      return [];
    }
  }

  // Get audio by ID (for getting direct audio URLs)
  Future<List<Track>> getAudioById({
    required List<String> audioIds,
  }) async {
    try {
      final params = <String, String>{
        'audios': audioIds.join(','),
      };
      final data = await _call(method: 'audio.getById', params: params);
      final items = data['response'] as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('getAudioById failed: $e');
      return [];
    }
  }

  // Get VK Mix (personalized mix from catalog)
  Future<Mix?> getMix() async {
    try {
      final data = await getCatalog();
      final responseData = data['response'];
      
      if (responseData == null) return null;

      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }
      
      // Look for mix section in catalog
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
      
      // Fallback: create mix from catalog tracks
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
  // Methods that accept pre-fetched catalog data
  // (to avoid fetching catalog multiple times)
  // ==========================================

  /// Extract tracks from already-fetched catalog data
  Future<List<Track>> getTracksFromCatalogData(Map<String, dynamic> catalog) async {
    return _getTracksFromCatalogData(catalog);
  }

  /// Extract playlists from already-fetched catalog data
  Future<List<Playlist>> getPlaylistsFromCatalogData(Map<String, dynamic> catalog) async {
    return _getPlaylistsFromCatalogData(catalog);
  }

  /// Extract recommendations from already-fetched catalog data
  Future<List<Track>> getRecommendationsFromCatalogData(Map<String, dynamic> catalog) async {
    return _getRecommendationsFromCatalogData(catalog);
  }

  /// Extract mix from already-fetched catalog data
  Future<Mix?> getMixFromCatalogData(Map<String, dynamic> catalog) async {
    return _getMixFromCatalogData(catalog);
  }

  /// Internal: extract tracks from catalog data
  Future<List<Track>> _getTracksFromCatalogData(Map<String, dynamic> catalog) async {
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

      // First pass: look for sections with user's music
      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = _getStringValue(section, 'id');
        final sectionTitle = _getStringValue(section, 'title');

        final tracks = _extractTracksFromSection(section);
        if (tracks.isNotEmpty && _isUserMusicSection(sectionId, sectionTitle)) {
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

      return allTracks;
    } catch (e) {
      debugPrint('Failed to extract tracks from catalog data: $e');
      return [];
    }
  }

  /// Internal: extract playlists from catalog data
  Future<List<Playlist>> _getPlaylistsFromCatalogData(Map<String, dynamic> catalog) async {
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
  Future<List<Track>> _getRecommendationsFromCatalogData(Map<String, dynamic> catalog) async {
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

  /// Internal: extract mix from catalog data
  Future<Mix?> _getMixFromCatalogData(Map<String, dynamic> catalog) async {
    try {
      final responseData = catalog['response'];
      if (responseData == null) return null;

      List<dynamic> sections = [];
      if (responseData is Map<String, dynamic>) {
        sections = responseData['sections'] as List<dynamic>? ?? [];
      } else if (responseData is List<dynamic>) {
        sections = responseData;
      }

      // Look for mix section in catalog
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

      // Fallback: create mix from catalog tracks
      final allTracks = await _getTracksFromCatalogData(catalog);
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
      debugPrint('getMixFromCatalogData failed: $e');
      return null;
    }
  }
}