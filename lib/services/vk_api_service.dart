import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/mix.dart';
import 'vk_config.dart';

class VkApiService {
  String? _accessToken;
  int? _userId;

  bool get isAuthorized => _accessToken != null;
  int? get userId => _userId;
  String? get accessToken => _accessToken;

  void setToken(String token, {int? userId}) {
    _accessToken = token;
    _userId = userId;
  }

  void clearToken() {
    _accessToken = null;
    _userId = null;
  }

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
      ...?params,
    };

    final uri = Uri.parse('${VkConfig.apiBaseUrl}/$method')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri);

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

  // Get user's audio catalog - the main working endpoint
  Future<Map<String, dynamic>> getCatalog({
    String? userId,
  }) async {
    final params = <String, String>{
      'extended': '1',
    };
    if (userId != null) params['user_id'] = userId;

    final data = await _call(method: 'audio.getCatalog', params: params);
    return data;
  }

  // Get user's audio tracks from catalog
  Future<List<Track>> getTracks({
    int? ownerId,
    int offset = 0,
    int count = 50,
  }) async {
    try {
      // Try the direct method first (might work with some tokens)
      final params = <String, String>{
        'offset': offset.toString(),
        'count': count.toString(),
      };
      if (ownerId != null) params['owner_id'] = ownerId.toString();

      final data = await _call(method: 'audio.get', params: params);
      final items = data['response']?['items'] as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (_) {
      // Fallback: extract tracks from catalog
      return _getTracksFromCatalog();
    }
  }

  /// Extract user's tracks from the catalog's "My Music" or similar sections
  Future<List<Track>> _getTracksFromCatalog() async {
    try {
      final catalog = await getCatalog();
      final sections = catalog['response']?['sections'] as List? ?? [];

      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = section['id'] as String? ?? '';

        // Look for sections containing user's tracks
        // Common section IDs: 'my_music', 'my_tracks', 'recent', 'favorite'
        if (sectionId.contains('my') || 
            sectionId.contains('recent') || 
            sectionId.contains('favorite') ||
            sectionId.contains('likes')) {
          final tracks = section['tracks'] as List? ?? [];
          if (tracks.isNotEmpty) {
            return tracks
                .whereType<Map<String, dynamic>>()
                .map((e) => Track.fromJson(e))
                .toList();
          }
        }
      }

      // Fallback: collect all unique tracks from all sections
      final allTracks = <Track>[];
      final seenIds = <String>{};
      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final tracks = section['tracks'] as List? ?? [];
        for (final trackData in tracks) {
          if (trackData is! Map<String, dynamic>) continue;
          final track = Track.fromJson(trackData);
          final key = '${track.ownerId}_${track.id}';
          if (seenIds.add(key)) {
            allTracks.add(track);
          }
        }
      }

      return allTracks;
    } catch (e) {
      debugPrint('Failed to extract tracks from catalog: $e');
      return [];
    }
  }

  // Get playlists from catalog
  Future<List<Playlist>> getPlaylists({
    int? ownerId,
    int offset = 0,
    int count = 50,
  }) async {
    try {
      // Try the direct method first
      final params = <String, String>{
        'offset': offset.toString(),
        'count': count.toString(),
      };
      if (ownerId != null) params['owner_id'] = ownerId.toString();

      final data = await _call(method: 'audio.getPlaylists', params: params);
      final items = data['response']?['items'] as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Playlist.fromJson(e))
          .toList();
    } catch (_) {
      // Fallback: extract playlists from catalog
      return _getPlaylistsFromCatalog();
    }
  }

  /// Extract playlists from catalog sections
  Future<List<Playlist>> _getPlaylistsFromCatalog() async {
    try {
      final catalog = await getCatalog();
      final sections = catalog['response']?['sections'] as List? ?? [];
      final playlists = <Playlist>[];

      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;

        // Some sections have playlists directly
        final sectionPlaylists = section['playlists'] as List? ?? [];
        for (final plData in sectionPlaylists) {
          if (plData is! Map<String, dynamic>) continue;
          playlists.add(Playlist.fromJson(plData));
        }

        // Some sections have albums
        final albums = section['albums'] as List? ?? [];
        for (final albumData in albums) {
          if (albumData is! Map<String, dynamic>) continue;
          playlists.add(Playlist.fromJson(albumData));
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
      debugPrint('Search failed: $e');
      return [];
    }
  }

  // Get recommended tracks from catalog
  Future<List<Track>> getRecommendations({
    int offset = 0,
    int count = 50,
  }) async {
    try {
      // Try direct method
      final params = <String, String>{
        'offset': offset.toString(),
        'count': count.toString(),
      };

      final data = await _call(method: 'audio.getRecommendations', params: params);
      final items = data['response']?['items'] as List? ?? [];
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    } catch (_) {
      // Fallback: extract recommendations from catalog
      return _getRecommendationsFromCatalog();
    }
  }

  /// Extract recommendations from catalog
  Future<List<Track>> _getRecommendationsFromCatalog() async {
    try {
      final catalog = await getCatalog();
      final sections = catalog['response']?['sections'] as List? ?? [];

      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = section['id'] as String? ?? '';

        // Look for recommendation sections
        if (sectionId.contains('recommend') || 
            sectionId.contains('discover') || 
            sectionId.contains('popular') ||
            sectionId.contains('new')) {
          final tracks = section['tracks'] as List? ?? [];
          if (tracks.isNotEmpty) {
            return tracks
                .whereType<Map<String, dynamic>>()
                .map((e) => Track.fromJson(e))
                .toList();
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
    final params = <String, String>{
      'audios': audioIds.join(','),
    };

    final data = await _call(method: 'audio.getById', params: params);
    final items = data['response'] as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => Track.fromJson(e))
        .toList();
  }

  // Get VK Mix (personalized mix from catalog)
  Future<Mix?> getMix() async {
    try {
      final data = await getCatalog();
      final sections = data['response']?['sections'] as List? ?? [];
      
      // Look for mix section in catalog
      for (final section in sections) {
        if (section is! Map<String, dynamic>) continue;
        final sectionId = section['id'] as String? ?? '';
        
        // VK mix sections typically have 'mix' in the id
        if (sectionId.contains('mix') || sectionId.contains('recommended')) {
          final tracks = section['tracks'] as List? ?? [];
          final trackList = tracks
              .whereType<Map<String, dynamic>>()
              .map((e) => Track.fromJson(e))
              .toList();
          
          if (trackList.isNotEmpty) {
            return Mix(
              id: sectionId,
              title: section['title'] as String? ?? 'Микс',
              description: section['subtitle'] as String?,
              coverUrl: _extractSectionCover(section),
              tracks: trackList,
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
}