import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import '../widgets/track_tile.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Track>? _tracks;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tracks = await context
          .read<MusicProvider>()
          .loadPlaylistTracks(widget.playlist);
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _playAll() {
    if (_tracks == null || _tracks!.isEmpty) return;
    context.read<MusicProvider>().playQueue(_tracks!);
  }

  void _playTrack(Track track) {
    if (_tracks == null) return;
    context.read<MusicProvider>().playTrack(track, queue: _tracks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTracks,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_tracks == null || _tracks!.isEmpty) {
      return const Center(child: Text('Плейлист пуст'));
    }

    return Column(
      children: [
        // Playlist header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[900],
                  child: widget.playlist.photoUrl != null
                      ? Image.network(
                          widget.playlist.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.playlist_play, size: 48),
                        )
                      : const Icon(Icons.playlist_play, size: 48),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playlist.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.playlist.description != null &&
                        widget.playlist.description!.isNotEmpty)
                      Text(
                        widget.playlist.description!,
                        style: TextStyle(color: Colors.grey[400]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${_tracks!.length} треков',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _playAll,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Слушать все'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // Tracks list
        Expanded(
          child: ListView.builder(
            itemCount: _tracks!.length,
            itemBuilder: (context, index) {
              final track = _tracks![index];
              return TrackTile(
                track: track,
                onTap: () => _playTrack(track),
                onPlay: () => _playTrack(track),
              );
            },
          ),
        ),
      ],
    );
  }
}