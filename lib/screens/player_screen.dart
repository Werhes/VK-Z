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
          title: const Text('Удалить трек'),
          content: Text('Удалить "${track.title}" из загрузок?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Сейчас играет',
              style: TextStyle(fontSize: 16),
            ),
            centerTitle: true,
            actions: [
              // Download button in app bar
              _buildAppBarDownloadButton(),
            ],
          ),
          extendBodyBehindAppBar: true,
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
                  const Spacer(),
                  // Album art
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 320),
                          color: Colors.grey[900],
                          child: track.albumArtUrl != null
                              ? Image.network(
                                  track.albumArtUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          _defaultArt(),
                                )
                              : _defaultArt(),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Track info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                track.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Offline indicator
                            if (_isDownloaded)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.offline_pin,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artist,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                            overlayColor: Colors.white.withValues(alpha: 0.2),
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            value: provider.duration.inSeconds > 0
                                ? provider.position.inSeconds /
                                    provider.duration.inSeconds
                                : 0,
                            onChanged: (value) {
                              final position = Duration(
                                seconds:
                                    (value * provider.duration.inSeconds)
                                        .toInt(),
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
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(provider.duration),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, size: 28),
                        onPressed: () {},
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 36),
                        onPressed: provider.hasPrevious
                            ? () => provider.playPrevious()
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: Icon(
                            provider.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 40,
                            color: Colors.black,
                          ),
                          onPressed: () => provider.togglePlayPause(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 36),
                        onPressed: provider.hasNext
                            ? () => provider.playNext()
                            : null,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.repeat, size: 28),
                        onPressed: () {},
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBarDownloadButton() {
    if (_downloadProgress != null &&
        _downloadProgress!.status == DownloadStatus.downloading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 24,
          height: 24,
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
      ),
      onPressed: _handleDownload,
      tooltip: _isDownloaded ? 'Удалить из загрузок' : 'Скачать',
    );
  }

  Widget _defaultArt() {
    return Container(
      color: Colors.grey[900],
      child: const Icon(Icons.music_note, size: 80),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}