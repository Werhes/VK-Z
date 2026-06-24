import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import '../services/download_service.dart';

class TrackTile extends StatefulWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final Widget? trailing;
  final bool showDownloadButton;

  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.onPlay,
    this.trailing,
    this.showDownloadButton = true,
  });

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  DownloadProgress? _downloadProgress;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
    _listenToDownloadProgress();
  }

  void _checkDownloadStatus() async {
    final provider = context.read<MusicProvider>();
    final downloaded = await provider.isTrackDownloaded(widget.track);
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
      });
    }
  }

  void _listenToDownloadProgress() {
    final provider = context.read<MusicProvider>();
    final trackKey = '${widget.track.ownerId}_${widget.track.id}';
    final progress = provider.downloadService.getCurrentProgress(trackKey);
    if (progress != null && mounted) {
      setState(() {
        _downloadProgress = progress;
        _isDownloaded = progress.status == DownloadStatus.completed;
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
    if (_isDownloaded) {
      // Show delete confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить трек'),
          content: Text('Удалить "${widget.track.title}" из загрузок?'),
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
        await provider.deleteDownloadedTrack(widget.track);
        if (mounted) {
          setState(() {
            _isDownloaded = false;
            _downloadProgress = null;
          });
        }
      }
    } else {
      await provider.downloadTrack(widget.track);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: widget.track.albumArtUrl != null
              ? Image.network(
                  widget.track.albumArtUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _defaultArt(),
                )
              : _defaultArt(),
        ),
      ),
      title: Text(
        widget.track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        widget.track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Download button
          if (widget.showDownloadButton) ...[
            _buildDownloadButton(),
            const SizedBox(width: 4),
          ],
          Text(
            widget.track.formattedDuration,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          widget.trailing ??
              IconButton(
                icon: const Icon(Icons.play_circle_outline, size: 28),
                onPressed: widget.onPlay,
              ),
        ],
      ),
      onTap: widget.onTap,
    );
  }

  Widget _buildDownloadButton() {
    if (_downloadProgress != null &&
        _downloadProgress!.status == DownloadStatus.downloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          value: _downloadProgress!.progress,
          strokeWidth: 2,
          color: Colors.blue,
        ),
      );
    }

    return IconButton(
      icon: Icon(
        _isDownloaded ? Icons.cloud_done : Icons.cloud_download_outlined,
        size: 20,
        color: _isDownloaded ? Colors.green : Colors.grey,
      ),
      onPressed: _handleDownload,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      tooltip: _isDownloaded ? 'Удалить из загрузок' : 'Скачать',
    );
  }

  Widget _defaultArt() {
    return Container(
      color: Colors.grey[900],
      child: const Icon(Icons.music_note, size: 24),
    );
  }
}