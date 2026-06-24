import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../services/download_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isDownloaded = false;
  DownloadProgress? _downloadProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDownloadStatus();
    });
  }

  void _checkDownloadStatus() async {
    final provider = context.read<MusicProvider>();
    final track = provider.currentTrack;
    if (track == null) return;

    final downloaded = await provider.isTrackDownloaded(track);
    final trackKey = '${track.ownerId}_${track.id}';
    final progress = provider.downloadService.getCurrentProgress(trackKey);

    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
        _downloadProgress = progress;
      });
    }

    provider.downloadService.getDownloadProgress(trackKey).listen((progress) {
      if (mounted) {
        setState(() {
          _downloadProgress = progress;
          _isDownloaded = progress.status == DownloadStatus.completed;
        });
      }
    });
  }

  void _handleDownload() async {
    final provider = context.read<MusicProvider>();
    final track = provider.currentTrack;
    if (track == null) return;

    if (_isDownloaded) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Удалить трек', style: TextStyle(color: Colors.white)),
          content: Text(
            'Удалить "${track.title}" из загрузок?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await provider.deleteDownloadedTrack(track);
        if (mounted) {
          setState(() {
            _isDownloaded = false;
            _downloadProgress = null;
          });
        }
      }
    } else {
      await provider.downloadTrack(track);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final track = provider.currentTrack;
        if (track == null) {
          return const Scaffold(
            body: Center(child: Text('Нет трека')),
          );
        }

        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blueGrey[900]!,
                  Colors.grey[950]!,
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                          onPressed: () => Navigator.of(context).pop(),
                          color: Colors.white70,
                        ),
                        const Spacer(),
                        const Text(
                          'Сейчас играет',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Download button
                        _buildDownloadButton(),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Album art
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 340),
                          color: Colors.grey[900],
                          child: track.albumArtUrl != null
                              ? Image.network(
                                  track.albumArtUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _defaultArt(),
                                )
                              : _defaultArt(),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Track info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                track.artist,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Like button (placeholder)
                        IconButton(
                          icon: Icon(
                            Icons.favorite_outline,
                            color: Colors.grey[400],
                            size: 26,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.grey[800],
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withValues(alpha: 0.15),
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                          ),
                          child: Slider(
                            value: provider.duration.inSeconds > 0
                                ? provider.position.inSeconds /
                                    provider.duration.inSeconds
                                : 0,
                            onChanged: (value) {
                              final position = Duration(
                                seconds: (value * provider.duration.inSeconds).toInt(),
                              );
                              provider.seek(position);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(provider.position),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                _formatDuration(provider.duration),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Main controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Shuffle
                      IconButton(
                        icon: const Icon(Icons.shuffle, size: 24),
                        onPressed: () {},
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      // Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 32),
                        onPressed: provider.hasPrevious
                            ? () => provider.playPrevious()
                            : null,
                        color: provider.hasPrevious ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      // Play/Pause
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: Icon(
                            provider.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 36,
                            color: Colors.black,
                          ),
                          onPressed: () => provider.togglePlayPause(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Next
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 32),
                        onPressed: provider.hasNext
                            ? () => provider.playNext()
                            : null,
                        color: provider.hasNext ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      // Repeat
                      IconButton(
                        icon: const Icon(Icons.repeat, size: 24),
                        onPressed: () {},
                        color: Colors.grey[400],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bottom actions row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Add to playlist
                        IconButton(
                          icon: Icon(
                            Icons.playlist_add,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                          onPressed: () {},
                        ),
                        // Volume
                        IconButton(
                          icon: Icon(
                            Icons.volume_up_outlined,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                          onPressed: () {},
                        ),
                        // Queue
                        IconButton(
                          icon: Icon(
                            Icons.queue_music_outlined,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                          onPressed: () {},
                        ),
                        // Offline indicator
                        if (_isDownloaded)
                          const Icon(
                            Icons.offline_pin,
                            color: Colors.green,
                            size: 24,
                          )
                        else
                          const SizedBox(width: 24),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadButton() {
    if (_downloadProgress != null &&
        _downloadProgress!.status == DownloadStatus.downloading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            value: _downloadProgress!.progress,
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        _isDownloaded ? Icons.cloud_done : Icons.cloud_download_outlined,
        color: _isDownloaded ? Colors.green : Colors.white70,
        size: 24,
      ),
      onPressed: _handleDownload,
      tooltip: _isDownloaded ? 'Удалить из загрузок' : 'Скачать',
    );
  }

  Widget _defaultArt() {
    return Container(
      color: Colors.grey[900],
      child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}