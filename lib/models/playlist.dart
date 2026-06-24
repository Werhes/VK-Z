import 'track.dart';

class Playlist {
  final int id;
  final int ownerId;
  final String title;
  final String? description;
  final String? photoUrl;
  final int trackCount;
  final List<Track> tracks;

  Playlist({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.photoUrl,
    this.trackCount = 0,
    this.tracks = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      photoUrl: _extractPhotoUrl(json),
      trackCount: json['count'] as int? ?? 0,
      tracks: _parseTracks(json['tracks']),
    );
  }

  static String? _extractPhotoUrl(Map<String, dynamic> json) {
    if (json['photo'] != null) {
      final photo = json['photo'] as Map<String, dynamic>;
      if (photo['photo_600'] != null) return photo['photo_600'] as String;
      if (photo['photo_300'] != null) return photo['photo_300'] as String;
      if (photo['photo_120'] != null) return photo['photo_120'] as String;
      if (photo['photo_68'] != null) return photo['photo_68'] as String;
    }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'count': trackCount,
    };
  }
}