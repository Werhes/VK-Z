import 'package:flutter/material.dart';
import '../models/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final Widget? trailing;

  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.onPlay,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: track.albumArtUrl != null
              ? Image.network(
                  track.albumArtUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _defaultArt(),
                )
              : _defaultArt(),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            track.formattedDuration,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          trailing ??
              IconButton(
                icon: const Icon(Icons.play_circle_outline, size: 28),
                onPressed: onPlay,
              ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _defaultArt() {
    return Container(
      color: Colors.grey[900],
      child: const Icon(Icons.music_note, size: 24),
    );
  }
}