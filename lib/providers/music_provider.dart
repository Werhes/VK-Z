import 'package:flutter/foundation.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/mix.dart';
import '../services/vk_api_service.dart';

class MusicProvider extends ChangeNotifier {
  final VkApiService _apiService;

  MusicProvider(this._apiService);

  // Auth state
  bool _isLoading = false;
  String? _error;

  // Music data
  List<Track> _tracks = [];
  List<Playlist> _playlists = [];
  List<Track> _searchResults = [];
  List<Track> _recommendations = [];
  Mix? _mix;

  // Player state
  Track? _currentTrack;
  List<Track> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Track> get tracks => _tracks;
  List<Playlist> get playlists => _playlists;
  List<Track> get searchResults => _searchResults;
  List<Track> get recommendations => _recommendations;
  Mix? get mix => _mix;
  Track? get currentTrack => _currentTrack;
  List<Track> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  // Auth
  bool get isAuthorized => _apiService.isAuthorized;

  void setToken(String token, {int? userId}) {
    _apiService.setToken(token, userId: userId);
    notifyListeners();
  }

  void logout() {
    _apiService.clearToken();
    _tracks = [];
    _playlists = [];
    _searchResults = [];
    _recommendations = [];
    _mix = null;
    _currentTrack = null;
    _queue = [];
    _currentIndex = -1;
    _isPlaying = false;
    notifyListeners();
  }

  // Load user's music
  Future<void> loadUserMusic() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getTracks(count: 50),
        _apiService.getPlaylists(count: 50),
        _apiService.getRecommendations(count: 20),
        _apiService.getMix(),
      ]);

      _tracks = results[0] as List<Track>;
      _playlists = results[1] as List<Playlist>;
      _recommendations = results[2] as List<Track>;
      _mix = results[3] as Mix?;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Refresh mix
  Future<void> refreshMix() async {
    try {
      _mix = await _apiService.getMix();
      notifyListeners();
    } catch (e) {
      // Silently fail for mix refresh
    }
  }

  // Search tracks
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchTracks(query: query);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load playlist tracks
  Future<List<Track>> loadPlaylistTracks(Playlist playlist) async {
    try {
      return await _apiService.getPlaylistTracks(
        playlistId: playlist.id,
        ownerId: playlist.ownerId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Player controls
  void playTrack(Track track, {List<Track>? queue}) {
    _currentTrack = track;
    if (queue != null) {
      _queue = queue;
      _currentIndex = queue.indexOf(track);
    } else {
      _queue = [track];
      _currentIndex = 0;
    }
    _isPlaying = true;
    _position = Duration.zero;
    notifyListeners();
  }

  void playQueue(List<Track> tracks, {int startIndex = 0}) {
    if (tracks.isEmpty) return;
    _queue = List.from(tracks);
    _currentIndex = startIndex;
    _currentTrack = tracks[startIndex];
    _isPlaying = true;
    _position = Duration.zero;
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void playNext() {
    if (!hasNext) return;
    _currentIndex++;
    _currentTrack = _queue[_currentIndex];
    _isPlaying = true;
    _position = Duration.zero;
    notifyListeners();
  }

  void playPrevious() {
    if (!hasPrevious) return;
    _currentIndex--;
    _currentTrack = _queue[_currentIndex];
    _isPlaying = true;
    _position = Duration.zero;
    notifyListeners();
  }

  void seek(Duration position) {
    _position = position;
    notifyListeners();
  }

  void updatePosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  void updateDuration(Duration duration) {
    _duration = duration;
    notifyListeners();
  }

  void onTrackComplete() {
    if (hasNext) {
      playNext();
    } else {
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}