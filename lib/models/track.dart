class Track {
  final int id;
  final int ownerId;
  final String title;
  final String artist;
  final int duration; // in seconds
  final String? albumArtUrl;
  final String? trackUrl;
  final bool isAvailable;

  Track({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.artist,
    required this.duration,
    this.albumArtUrl,
    this.trackUrl,
    this.isAvailable = true,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as int,
      ownerId: json['owner_id'] as int,
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown',
      duration: json['duration'] as int? ?? 0,
      albumArtUrl: _extractAlbumArt(json),
      trackUrl: json['url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  static String? _extractAlbumArt(Map<String, dynamic> json) {
    // Try to get album art from various possible locations
    if (json['album'] != null) {
      final album = json['album'] as Map<String, dynamic>;
      if (album['thumb'] != null) {
        final thumb = album['thumb'] as Map<String, dynamic>;
        if (thumb['photo_600'] != null) return thumb['photo_600'] as String;
        if (thumb['photo_300'] != null) return thumb['photo_300'] as String;
        if (thumb['photo_120'] != null) return thumb['photo_120'] as String;
        if (thumb['photo_68'] != null) return thumb['photo_68'] as String;
      }
    }
    // Try direct album art field
    if (json['album_art'] != null) return json['album_art'] as String;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'artist': artist,
      'duration': duration,
      'url': trackUrl,
    };
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => '$artist - $title';
}