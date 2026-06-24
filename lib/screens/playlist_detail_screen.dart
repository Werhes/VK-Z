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

  void _shufflePlay() {
    if (_tracks == null || _tracks!.isEmpty) return;
    final shuffled = List<Track>.from(_tracks!)..shuffle();
    context.read<MusicProvider>().playQueue(shuffled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // App bar with playlist cover
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  if (widget.playlist.photoUrl != null)
                    Image.network(
                      widget.playlist.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _defaultHeader(),
                    )
                  else
                    _defaultHeader(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  // Playlist info at bottom of header
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.playlist.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (widget.playlist.description != null &&
                            widget.playlist.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              widget.playlist.description!,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Text(
                          '${_tracks?.length ?? widget.playlist.trackCount} треков',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Play all button
                  GestureDetector(
                    onTap: _playAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 22),
                          SizedBox(width: 6),
                          Text(
                            'Слушать',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Shuffle button
                  GestureDetector(
                    onTap: _shufflePlay,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: Icon(
                        Icons.shuffle,
                        color: Colors.grey[400],
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Download all (placeholder)
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Icon(
                      Icons.download_outlined,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tracks list
          _buildTracksSliver(),
        ],
      ),
    );
  }

  Widget _defaultHeader() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Icon(Icons.playlist_play, size: 80, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildTracksSliver() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTracks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tracks == null || _tracks!.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Плейлист пуст',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = _tracks![index];
          return TrackTile(
            track: track,
            onTap: () => _playTrack(track),
            onPlay: () => _playTrack(track),
          );
        },
        childCount: _tracks!.length,
      ),
    );
  }
}