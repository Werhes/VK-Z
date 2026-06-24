import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';

/// Экран "Моя музыка" — список любимых треков пользователя.
/// Скопирован из FlutterVK (MyMusicBlock + MusicCategory).
class MyMusicScreen extends StatelessWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const MyMusicScreen({
    super.key,
    required this.provider,
    required this.playTrack,
  });

  @override
  Widget build(BuildContext context) {
    final tracks = provider.tracks;
    final trackCount = tracks.length;
    final clampedCount = trackCount.clamp(0, 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя музыка'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Заголовок с количеством треков
          _MusicCategoryHeader(
            title: 'Моя музыка',
            count: trackCount,
          ),
          const SizedBox(height: 14),

          // Список треков (до 10)
          if (tracks.isNotEmpty)
            for (int i = 0; i < clampedCount; i++) ...[
              TrackTile(
                track: tracks[i],
                onTap: () => playTrack(tracks[i], tracks),
                onPlay: () => playTrack(tracks[i], tracks),
              ),
              const SizedBox(height: 4),
            ],

          const SizedBox(height: 8),

          // Кнопки управления
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: Icon(
                  provider.isPlaying && provider.currentTrack != null
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                label: Text(
                  provider.isPlaying && provider.currentTrack != null
                      ? 'Пауза'
                      : 'Слушать',
                ),
                onPressed: tracks.isNotEmpty
                    ? () {
                        if (provider.currentTrack != null &&
                                tracks.contains(provider.currentTrack)) {
                              provider.togglePlayPause();
                        } else if (tracks.isNotEmpty) {
                          playTrack(tracks.first, tracks);
                        }
                      }
                    : null,
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.shuffle),
                label: const Text('Перемешать'),
                onPressed: tracks.isNotEmpty
                    ? () {
                        final shuffled = List<Track>.from(tracks)..shuffle();
                        playTrack(shuffled.first, shuffled);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Заголовок категории в стиле FlutterVK MusicCategory.
class _MusicCategoryHeader extends StatelessWidget {
  final String title;
  final int count;

  const _MusicCategoryHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              WidgetSpan(
                baseline: TextBaseline.alphabetic,
                alignment: PlaceholderAlignment.baseline,
                child: Text(
                  '  $count',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.75),
                      ),
                ),
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}