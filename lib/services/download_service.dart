import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';

enum DownloadStatus { idle, downloading, completed, failed }

class DownloadProgress {
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String? localPath;
  final String? error;

  const DownloadProgress({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.localPath,
    this.error,
  });

  DownloadProgress copyWith({
    DownloadStatus? status,
    double? progress,
    String? localPath,
    String? error,
  }) {
    return DownloadProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
    );
  }
}

class DownloadService {
  final Dio _dio;
  final Map<String, DownloadProgress> _downloads = {};
  final Map<String, StreamController<DownloadProgress>> _controllers = {};

  // Cache for downloaded tracks metadata
  List<DownloadedTrackInfo> _downloadedTracks = [];
  bool _metadataLoaded = false;

  DownloadService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  /// Get the downloads directory
  Future<Directory> get _downloadsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get the metadata file path
  Future<File> get _metadataFile async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/downloaded_tracks.json');
    return file;
  }

  /// Generate a unique filename for a track
  String _getTrackFilename(Track track) {
    // Sanitize filename
    final safeTitle = track.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final safeArtist = track.artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return [
      track.ownerId.toString(),
      track.id.toString(),
      safeArtist,
      '$safeTitle.mp3',
    ].join('_');
  }

  /// Get the local file path for a track
  Future<String> getTrackLocalPath(Track track) async {
    final dir = await _downloadsDirectory;
    return '${dir.path}/${_getTrackFilename(track)}';
  }

  /// Check if a track is downloaded
  Future<bool> isTrackDownloaded(Track track) async {
    final path = await getTrackLocalPath(track);
    return File(path).exists();
  }

  /// Get download progress stream for a track
  Stream<DownloadProgress> getDownloadProgress(String trackKey) {
    _controllers.putIfAbsent(trackKey, () {
      return StreamController<DownloadProgress>.broadcast();
    });
    return _controllers[trackKey]!.stream;
  }

  /// Get current download progress
  DownloadProgress? getCurrentProgress(String trackKey) {
    return _downloads[trackKey];
  }

  /// Download a track
  Future<String> downloadTrack(Track track, {void Function(double)? onProgress}) async {
    if (track.trackUrl == null || track.trackUrl!.isEmpty) {
      throw Exception('Track URL is not available');
    }

    final trackKey = '${track.ownerId}_${track.id}';
    final dir = await _downloadsDirectory;
    final filename = _getTrackFilename(track);
    final filePath = '${dir.path}/$filename';

    // Check if already downloaded
    if (await File(filePath).exists()) {
      _updateProgress(trackKey, DownloadProgress(
        status: DownloadStatus.completed,
        progress: 1.0,
        localPath: filePath,
      ));
      return filePath;
    }

    _updateProgress(trackKey, const DownloadProgress(
      status: DownloadStatus.downloading,
      progress: 0.0,
    ));

    try {
      await _dio.download(
        track.trackUrl!,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateProgress(trackKey, DownloadProgress(
              status: DownloadStatus.downloading,
              progress: progress,
              localPath: filePath,
            ));
            onProgress?.call(progress);
          }
        },
      );

      _updateProgress(trackKey, DownloadProgress(
        status: DownloadStatus.completed,
        progress: 1.0,
        localPath: filePath,
      ));

      // Save metadata
      await _saveDownloadedTrack(track, filePath);

      return filePath;
    } catch (e) {
      _updateProgress(trackKey, DownloadProgress(
        status: DownloadStatus.failed,
        progress: 0.0,
        error: e.toString(),
      ));

      // Clean up failed download
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      rethrow;
    }
  }

  /// Delete a downloaded track
  Future<void> deleteTrack(Track track) async {
    final path = await getTrackLocalPath(track);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    // Remove from metadata
    _downloadedTracks.removeWhere((t) =>
        t.trackId == track.id && t.ownerId == track.ownerId);

    final trackKey = '${track.ownerId}_${track.id}';
    _downloads.remove(trackKey);
    _controllers[trackKey]?.close();
    _controllers.remove(trackKey);

    await _saveMetadata();
  }

  /// Get all downloaded tracks info
  Future<List<DownloadedTrackInfo>> getDownloadedTracks() async {
    if (!_metadataLoaded) {
      await _loadMetadata();
    }
    return List.from(_downloadedTracks);
  }

  /// Save downloaded track metadata
  Future<void> _saveDownloadedTrack(Track track, String localPath) async {
    final info = DownloadedTrackInfo(
      trackId: track.id,
      ownerId: track.ownerId,
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      albumArtUrl: track.albumArtUrl,
      localPath: localPath,
      downloadedAt: DateTime.now(),
    );

    // Remove existing entry if any
    _downloadedTracks.removeWhere((t) =>
        t.trackId == track.id && t.ownerId == track.ownerId);

    _downloadedTracks.add(info);
    await _saveMetadata();
  }

  /// Save metadata to file
  Future<void> _saveMetadata() async {
    final file = await _metadataFile;
    final jsonList = _downloadedTracks.map((t) => t.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// Load metadata from file
  Future<void> _loadMetadata() async {
    try {
      final file = await _metadataFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List;
        _downloadedTracks = list
            .map((e) => DownloadedTrackInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _downloadedTracks = [];
    }
    _metadataLoaded = true;
  }

  /// Update progress and notify listeners
  void _updateProgress(String trackKey, DownloadProgress progress) {
    _downloads[trackKey] = progress;
    _controllers[trackKey]?.add(progress);
  }

  /// Clean up resources
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _downloads.clear();
  }
}

class DownloadedTrackInfo {
  final int trackId;
  final int ownerId;
  final String title;
  final String artist;
  final int duration;
  final String? albumArtUrl;
  final String localPath;
  final DateTime downloadedAt;

  DownloadedTrackInfo({
    required this.trackId,
    required this.ownerId,
    required this.title,
    required this.artist,
    required this.duration,
    this.albumArtUrl,
    required this.localPath,
    required this.downloadedAt,
  });

  Track toTrack() {
    return Track(
      id: trackId,
      ownerId: ownerId,
      title: title,
      artist: artist,
      duration: duration,
      albumArtUrl: albumArtUrl,
      trackUrl: localPath,
      isAvailable: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'track_id': trackId,
      'owner_id': ownerId,
      'title': title,
      'artist': artist,
      'duration': duration,
      'album_art_url': albumArtUrl,
      'local_path': localPath,
      'downloaded_at': downloadedAt.toIso8601String(),
    };
  }

  factory DownloadedTrackInfo.fromJson(Map<String, dynamic> json) {
    return DownloadedTrackInfo(
      trackId: json['track_id'] as int,
      ownerId: json['owner_id'] as int,
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown',
      duration: json['duration'] as int? ?? 0,
      albumArtUrl: json['album_art_url'] as String?,
      localPath: json['local_path'] as String? ?? '',
      downloadedAt: DateTime.parse(json['downloaded_at'] as String),
    );
  }
}