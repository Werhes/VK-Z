import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        if (provider.currentTrack == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PlayerScreen(),
              ),
            );
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[800]!,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: provider.currentTrack!.albumArtUrl != null
                        ? Image.network(
                            provider.currentTrack!.albumArtUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _defaultArt(),
                          )
                        : _defaultArt(),
                  ),
                ),
                const SizedBox(width: 12),
                // Track info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.currentTrack!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        provider.currentTrack!.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Controls
                IconButton(
                  icon: Icon(
                    provider.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 36,
                  ),
                  onPressed: () {
                    provider.togglePlayPause();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 28),
                  onPressed: provider.hasNext ? () => provider.playNext() : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _defaultArt() {
    return Container(
      color: Colors.grey[900],
      child: const Icon(Icons.music_note, size: 24),
    );
  }
}