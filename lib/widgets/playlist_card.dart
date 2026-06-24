import 'package:flutter/material.dart';
import '../models/playlist.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 140,
                height: 140,
                color: Colors.grey[900],
                child: playlist.photoUrl != null
                    ? Image.network(
                        playlist.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _defaultArt(),
                      )
                    : _defaultArt(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              '${playlist.trackCount} треков',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultArt() {
    return Container(
      color: Colors.grey[850],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_play, size: 40, color: Colors.grey[600]),
        ],
      ),
    );
  }
}