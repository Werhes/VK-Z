import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mix.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import '../widgets/track_tile.dart';
import 'mix_settings_screen.dart';

class MixScreen extends StatelessWidget {
  final Mix mix;

  const MixScreen({
    super.key,
    required this.mix,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with cover
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white70),
                tooltip: 'Настройки микса',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MixSettingsScreen(
                        mixId: mix.id,
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  if (mix.coverUrl != null)
                    Image.network(
                      mix.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _defaultCover(),
                    )
                  else
                    _defaultCover(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  // Title and info
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mix.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (mix.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            mix.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${mix.tracks.length} треков',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Play all button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _playAll(context),
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    'Слушать микс',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Tracks list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = mix.tracks[index];
                return TrackTile(
                  track: track,
                  onTap: () => _playTrack(context, track),
                  onPlay: () => _playTrack(context, track),
                );
              },
              childCount: mix.tracks.length,
            ),
          ),
        ],
      ),
    );
  }

  void _playAll(BuildContext context) {
    if (mix.tracks.isEmpty) return;
    context.read<MusicProvider>().playQueue(mix.tracks);
  }

  void _playTrack(BuildContext context, Track track) {
    context.read<MusicProvider>().playTrack(track, queue: mix.tracks);
  }

  Widget _defaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey[800]!,
            Colors.blueGrey[900]!,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.queue_music,
          size: 80,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}