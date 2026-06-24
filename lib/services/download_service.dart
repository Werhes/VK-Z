import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';

// ============================================
// Download Status & Progress 
// ============================================

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

// ============================================
// DownloadItem — загрузка одного трека (как в FlutterVK)
// ============================================

class DownloadItem {
  final Track track;
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final Dio _dio;

  DownloadItem({required this.track, required Dio dio}) : _dio = dio;

  Future<void> download(String filePath) async {
    if (track.trackUrl == null || track.trackUrl!.isEmpty) {
      throw Exception('Track URL is not available');
    }

    await _dio.download(
      track.trackUrl!,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          progress.value = received / total;
        }
      },
    );

    progress.value = 1.0;
  }
}

// ============================================
// DownloadTask — группа загрузок с очередью (как в FlutterVK)
// ============================================

class DownloadTask {
  final String id;
  final String smallTitle;
  final String longTitle;
  final List<DownloadItem> items;
  final ValueNotifier<double> progress = ValueNotifier(0.0);

  DownloadTask({
    required this.id,
    required this.smallTitle,
    required this.longTitle,
    required this.items,
  });

  Future<void> execute(String Function(Track) getPath) async {
    for (final item in items) {
      void listener() {
        progress.value = items.fold<double>(
          0.0,
          (total, i) => total + i.progress.value,
        ) / items.length;
      }

      item.progress.addListener(listener);
      try {
        final path = getPath(item.track);
        await item.download(path);
      } finally {
        item.progress.removeListener(listener);
      }
    }
    progress.value = 1.0;
  }
}

// ============================================
// DownloadManager — управление загрузками (как в FlutterVK)
// ============================================

class DownloadManager {
  final Dio _dio;
  final Map<String, DownloadProgress> _downloads = {};
  final Map<String, StreamController<DownloadProgress>> _controllers = {};

  // Общий прогресс по всем активным загрузкам
  final ValueNotifier<double> globalProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> isDownloading = ValueNotifier(false);
  int _activeDownloads = 0;

  // Метаданные скачанных треков
  List<DownloadedTrackInfo> _downloadedTracks = [];
  bool _metadataLoaded = false;

  DownloadManager()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  Future<Directory> get _downloadsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> get _metadataFile async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/downloaded_tracks.json');
  }

  String _getTrackFilename(Track track) {
    final safeTitle = track.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final safeArtist = track.artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return '${track.ownerId}_${track.id}_${safeArtist}_$safeTitle.mp3';
  }

  Future<String> getTrackLocalPath(Track track) async {
    final dir = await _downloadsDirectory;
    return '${dir.path}/${_getTrackFilename(track)}';
  }

  Future<bool> isTrackDownloaded(Track track) async {
    final path = await getTrackLocalPath(track);
    return File(path).exists();
  }

  Stream<DownloadProgress> getDownloadProgress(String trackKey) {
    _controllers.putIfAbsent(trackKey, () {
      return StreamController<DownloadProgress>.broadcast();
    });
    return _controllers[trackKey]!.stream;
  }

  DownloadProgress? getCurrentProgress(String trackKey) {
    return _downloads[trackKey];
  }

  /// Загрузка одного трека (как DownloadItem в FlutterVK)
  Future<String> downloadTrack(Track track, {void Function(double)? onProgress}) async {
    if (track.trackUrl == null || track.trackUrl!.isEmpty) {
      throw Exception('Track URL is not available');
    }

    final trackKey = '${track.ownerId}_${track.id}';
    final dir = await _downloadsDirectory;
    final filename = _getTrackFilename(track);
    final filePath = '${dir.path}/$filename';

    if (await File(filePath).exists()) {
      _updateProgress(trackKey, const DownloadProgress(
        status: DownloadStatus.completed,
        progress: 1.0,
      ));
      return filePath;
    }

    _updateProgress(trackKey, const DownloadProgress(
      status: DownloadStatus.downloading,
      progress: 0.0,
    ));

    _activeDownloads++;
    isDownloading.value = true;

    try {
      final item = DownloadItem(track: track, dio: _dio);
      void listener() {
        final p = item.progress.value;
        _updateProgress(trackKey, DownloadProgress(
          status: DownloadStatus.downloading,
          progress: p,
          localPath: filePath,
        ));
        onProgress?.call(p);
        _updateGlobalProgress();
      }

      item.progress.addListener(listener);
      await item.download(filePath);
      item.progress.removeListener(listener);

      _updateProgress(trackKey, DownloadProgress(
        status: DownloadStatus.completed,
        progress: 1.0,
        localPath: filePath,
      ));

      await _saveDownloadedTrack(track, filePath);
      return filePath;
    } catch (e) {
      _updateProgress(trackKey, DownloadProgress(
        status: DownloadStatus.failed,
        progress: 0.0,
        error: e.toString(),
      ));

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    } finally {
      _activeDownloads--;
      if (_activeDownloads <= 0) {
        _activeDownloads = 0;
        isDownloading.value = false;
      }
      _updateGlobalProgress();
    }
  }

  /// Загрузка нескольких треков через DownloadTask (как в FlutterVK)
  Future<void> downloadTracks(List<Track> tracks, {String? taskTitle}) async {
    if (tracks.isEmpty) return;

    final items = tracks.map((t) => DownloadItem(track: t, dio: _dio)).toList();

    _activeDownloads += tracks.length;
    isDownloading.value = true;

    try {
      for (final item in items) {
        final trackKey = '${item.track.ownerId}_${item.track.id}';
        final dir = await _downloadsDirectory;
        final filePath = '${dir.path}/${_getTrackFilename(item.track)}';

        if (await File(filePath).exists()) {
          _updateProgress(trackKey, const DownloadProgress(
            status: DownloadStatus.completed,
            progress: 1.0,
          ));
          _activeDownloads--;
          continue;
        }

        _updateProgress(trackKey, const DownloadProgress(
          status: DownloadStatus.downloading,
          progress: 0.0,
        ));

        void listener() {
          final p = item.progress.value;
          _updateProgress(trackKey, DownloadProgress(
            status: DownloadStatus.downloading,
            progress: p,
            localPath: filePath,
          ));
          _updateGlobalProgress();
        }

        item.progress.addListener(listener);
        try {
          await item.download(filePath);
          _updateProgress(trackKey, DownloadProgress(
            status: DownloadStatus.completed,
            progress: 1.0,
            localPath: filePath,
          ));
          await _saveDownloadedTrack(item.track, filePath);
        } catch (e) {
          _updateProgress(trackKey, DownloadProgress(
            status: DownloadStatus.failed,
            progress: 0.0,
            error: e.toString(),
          ));
        } finally {
          item.progress.removeListener(listener);
          _activeDownloads--;
          _updateGlobalProgress();
        }
      }
    } finally {
      if (_activeDownloads <= 0) {
        _activeDownloads = 0;
        isDownloading.value = false;
      }
      _updateGlobalProgress();
    }
  }

  void _updateGlobalProgress() {
    if (_downloads.isEmpty) {
      globalProgress.value = 0.0;
      return;
    }
    final total = _downloads.values.fold<double>(
      0.0,
      (sum, p) => sum + p.progress,
    );
    globalProgress.value = total / _downloads.length;
  }

  Future<void> deleteTrack(Track track) async {
    final path = await getTrackLocalPath(track);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    _downloadedTracks.removeWhere((t) =>
        t.trackId == track.id && t.ownerId == track.ownerId);

    final trackKey = '${track.ownerId}_${track.id}';
    _downloads.remove(trackKey);
    _controllers[trackKey]?.close();
    _controllers.remove(trackKey);

    await _saveMetadata();
  }

  Future<List<DownloadedTrackInfo>> getDownloadedTracks() async {
    if (!_metadataLoaded) {
      await _loadMetadata();
    }
    return List.from(_downloadedTracks);
  }

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

    _downloadedTracks.removeWhere((t) =>
        t.trackId == track.id && t.ownerId == track.ownerId);
    _downloadedTracks.add(info);
    await _saveMetadata();
  }

  Future<void> _saveMetadata() async {
    final file = await _metadataFile;
    final jsonList = _downloadedTracks.map((t) => t.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

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

  void _updateProgress(String trackKey, DownloadProgress progress) {
    _downloads[trackKey] = progress;
    _controllers[trackKey]?.add(progress);
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _downloads.clear();
  }
}

// ============================================
// DownloadedTrackInfo (метаданные)
// ============================================

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