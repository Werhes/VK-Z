import 'track.dart';

class Mix {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final List<Track> tracks;
  final String? artistName;

  Mix({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.tracks = const [],
    this.artistName,
  });

  factory Mix.fromJson(Map<String, dynamic> json) {
    return Mix(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Микс',
      description: json['description'] as String?,
      coverUrl: _extractCoverUrl(json),
      tracks: _parseTracks(json['tracks']),
      artistName: json['artist_name'] as String?,
    );
  }

  static String? _extractCoverUrl(Map<String, dynamic> json) {
    if (json['photo'] != null) {
      final photo = json['photo'] as Map<String, dynamic>;
      if (photo['photo_600'] != null) return photo['photo_600'] as String;
      if (photo['photo_300'] != null) return photo['photo_300'] as String;
      if (photo['photo_120'] != null) return photo['photo_120'] as String;
      if (photo['photo_68'] != null) return photo['photo_68'] as String;
    }
    if (json['cover_url'] != null) return json['cover_url'] as String;
    return null;
  }

  static List<Track> _parseTracks(dynamic tracksData) {
    if (tracksData == null) return [];
    if (tracksData is List) {
      return tracksData
          .whereType<Map<String, dynamic>>()
          .map((e) => Track.fromJson(e))
          .toList();
    }
    return [];
  }

  // Create a mix from recommendations (fallback)
  factory Mix.fromRecommendations(List<Track> tracks) {
    return Mix(
      id: 'recommendations',
      title: 'Микс дня',
      description: 'Персональные рекомендации для вас',
      tracks: tracks,
    );
  }
}