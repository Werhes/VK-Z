import 'dart:convert';
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

  // Get user's audio catalog (playlists, albums, etc.)
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

  // Get user's audio tracks
  Future<List<Track>> getTracks({
    int? ownerId,
    int offset = 0,
    int count = 50,
  }) async {
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
  }

  // Get playlists
  Future<List<Playlist>> getPlaylists({
    int? ownerId,
    int offset = 0,
    int count = 50,
  }) async {
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
    final params = <String, String>{
      'q': query,
      'offset': offset.toString(),
      'count': count.toString(),
      'autocomplete': '1',
      'sort': '2', // 2 = by duration, 0 = by date, 1 = by popularity
    };

    final data = await _call(method: 'audio.search', params: params);
    final items = data['response']?['items'] as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => Track.fromJson(e))
        .toList();
  }

  // Get recommended tracks
  Future<List<Track>> getRecommendations({
    int offset = 0,
    int count = 50,
  }) async {
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
  }

  // Get popular tracks
  Future<List<Track>> getPopular({
    int offset = 0,
    int count = 50,
  }) async {
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
      
      // Fallback: create mix from recommendations
      final recs = await getRecommendations(count: 30);
      if (recs.isNotEmpty) {
        return Mix.fromRecommendations(recs);
      }
      
      return null;
    } catch (e) {
      // Fallback to recommendations-based mix
      try {
        final recs = await getRecommendations(count: 30);
        if (recs.isNotEmpty) {
          return Mix.fromRecommendations(recs);
        }
      } catch (_) {}
      return null;
    }
  }

  String? _extractSectionCover(Map<String, dynamic> section) {
    if (section['photo'] != null) {
      final photo = section['photo'] as Map<String, dynamic>;
      if (photo['photo_600'] != null) return photo['photo_600'] as String;
      if (photo['photo_300'] != null) return photo['photo_300'] as String;
      if (photo['photo_120'] != null) return photo['photo_120'] as String;
    }
    if (section['cover'] != null) {
      final cover = section['cover'] as Map<String, dynamic>;
      if (cover['url'] != null) return cover['url'] as String;
    }
    return null;
  }
}