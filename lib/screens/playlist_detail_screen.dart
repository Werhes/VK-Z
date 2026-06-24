import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../providers/music_provider.dart';
import '../widgets/track_tile.dart';

/// Виджет, отображающий информацию о данном плейлисте (его название, ...).
class _PlaylistInfoWidget extends StatelessWidget {
  final Playlist playlist;
  final List<Track>? tracks;
  final double infoBoxHeight;

  const _PlaylistInfoWidget({
    required this.playlist,
    this.tracks,
    required this.infoBoxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: infoBoxHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              // Название плейлиста.
              Text(
                playlist.title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              // Описание плейлиста, если таковое есть.
              if (playlist.description != null &&
                  playlist.description!.isNotEmpty) ...[
                Text(
                  playlist.description!,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Пояснение того, что это за плейлист.
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  children: [
                    const TextSpan(text: 'Плейлист'),
                    const TextSpan(text: ' • '),
                    TextSpan(
                      text: '${tracks?.length ?? playlist.trackCount} треков',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ряд из кнопок управления плейлиста.
class _ControlButtonsWidget extends StatelessWidget {
  static const double buttonSize = 56;

  final Playlist playlist;
  final ScrollController scrollController;
  final double maxAppBarHeight;
  final double minAppBarHeight;
  final double infoBoxHeight;
  final VoidCallback? onPlayPausePressed;
  final VoidCallback? onShufflePressed;

  const _ControlButtonsWidget({
    required this.playlist,
    required this.scrollController,
    required this.maxAppBarHeight,
    required this.minAppBarHeight,
    required this.infoBoxHeight,
    this.onPlayPausePressed,
    this.onShufflePressed,
  });

  @override
  Widget build(BuildContext context) {
    final scrollPosition = scrollController.position;

    final double finalPosition = minAppBarHeight - buttonSize / 2;
    double positionFromTop = maxAppBarHeight;
    double otherButtonOpacity = 1.0;

    if (scrollController.hasClients) {
      final double offset = scrollPosition.pixels;
      final double buttonCenterPosition = infoBoxHeight - buttonSize / 2;

      otherButtonOpacity =
          (1.0 + (maxAppBarHeight - minAppBarHeight - offset) / infoBoxHeight)
              .clamp(0.0, 1.0);

      positionFromTop =
          offset > (maxAppBarHeight - finalPosition + buttonCenterPosition)
              ? finalPosition
              : maxAppBarHeight - offset + buttonCenterPosition;
    }

    const double realButtonSize = buttonSize - 8 * 2;

    return Positioned(
      top: positionFromTop,
      child: SizedBox(
        width: 300,
        child: RepaintBoundary(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Кнопка для перемешивания.
              SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: (otherButtonOpacity > 0)
                    ? Opacity(
                        opacity: otherButtonOpacity,
                        child: IconButton(
                          icon: const Icon(Icons.shuffle),
                          iconSize: realButtonSize,
                          onPressed: onShufflePressed,
                        ),
                      )
                    : null,
              ),

              // Кнопка для воспроизведения/паузы.
              IconButton.filled(
                icon: const Icon(Icons.play_arrow),
                iconSize: realButtonSize,
                onPressed: onPlayPausePressed,
              ),

              // Пустое место справа для симметрии.
              SizedBox(
                width: buttonSize,
                height: buttonSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Виджет, отображающий список из треков для плейлиста.
class _PlaylistTracksListWidget extends StatelessWidget {
  final Playlist playlist;
  final List<Track>? tracks;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final Function(Track) onPlayTrack;

  const _PlaylistTracksListWidget({
    required this.playlist,
    this.tracks,
    required this.isLoading,
    this.error,
    required this.onRetry,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    // Загрузка.
    if (isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Ошибка.
    if (error != null) {
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
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
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

    // Нет треков.
    if (tracks == null || tracks!.isEmpty) {
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

    // Список треков.
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = tracks![index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TrackTile(
              track: track,
              onTap: () => onPlayTrack(track),
              onPlay: () => onPlayTrack(track),
            ),
          );
        },
        childCount: tracks!.length,
      ),
    );
  }
}

/// Экран детального просмотра плейлиста (как FlutterVK PlaylistRoute).
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final infoBoxHeight =
        (widget.playlist.description != null &&
                widget.playlist.description!.isNotEmpty)
            ? 150.0
            : 100.0;
    final maxAppBarHeight =
        (screenHeight / 2).roundToDouble().clamp(0, 500) - infoBoxHeight +
            statusBarHeight;
    final minAppBarHeight = 70 + statusBarHeight;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Фоновый градиент.
          _BackgroundGradient(
            scrollController: _scrollController,
            maxHeight: maxAppBarHeight + infoBoxHeight,
          ),

          // Основной контент.
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // AppBar с анимированным изображением плейлиста.
              _AppBarWidget(
                playlist: widget.playlist,
                maxAppBarHeight: maxAppBarHeight,
                minAppBarHeight: minAppBarHeight,
              ),

              // Информация о плейлисте.
              _PlaylistInfoWidget(
                playlist: widget.playlist,
                tracks: _tracks,
                infoBoxHeight: infoBoxHeight,
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 36)),

              // Треки в плейлисте.
              _PlaylistTracksListWidget(
                playlist: widget.playlist,
                tracks: _tracks,
                isLoading: _isLoading,
                error: _error,
                onRetry: _loadTracks,
                onPlayTrack: _playTrack,
              ),

              // Отступ для мини-плеера.
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // Плавающие кнопки управления.
          _ControlButtonsWidget(
            playlist: widget.playlist,
            scrollController: _scrollController,
            maxAppBarHeight: maxAppBarHeight,
            minAppBarHeight: minAppBarHeight,
            infoBoxHeight: infoBoxHeight,
            onPlayPausePressed: _playAll,
            onShufflePressed: _shufflePlay,
          ),
        ],
      ),
    );
  }
}

/// Фоновый градиент для плейлиста.
class _BackgroundGradient extends StatelessWidget {
  final ScrollController scrollController;
  final double maxHeight;

  const _BackgroundGradient({
    required this.scrollController,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        height: maxHeight,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A3E),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AppBar для плейлиста с анимированным изображением.
class _AppBarWidget extends StatelessWidget {
  final Playlist playlist;
  final double maxAppBarHeight;
  final double minAppBarHeight;

  const _AppBarWidget({
    required this.playlist,
    required this.maxAppBarHeight,
    required this.minAppBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        maxHeight: maxAppBarHeight,
        minHeight: minAppBarHeight,
        builder: (context, offset) {
          const double albumPadding = 50;
          final double albumImageSize =
              (MediaQuery.sizeOf(context).width - albumPadding * 2)
                  .clamp(50, 300);
          final double albumImageSizeWithPadding =
              albumImageSize + albumPadding * 2;

          final double scrollToHeightRatio = offset / maxAppBarHeight;

          // Изображение альбома должно становиться меньше при скролле.
          final double freeSpace = maxAppBarHeight - albumImageSizeWithPadding;
          final bool shouldScaleDownAlbumImage = offset > freeSpace;
          final double albumScaleDiff = shouldScaleDownAlbumImage
              ? (offset - freeSpace) / (maxAppBarHeight - freeSpace)
              : 0.0;
          final double albumScale = 1.0 - albumScaleDiff;

          // Прозрачность альбома.
          final double albumOpacity =
              (1.0 - (albumScaleDiff - 0.5) / 0.7).clamp(0.0, 1.0);

          // Позиция изображения.
          final double albumBasePosition =
              maxAppBarHeight / 2 - albumImageSize / 2;
          final double albumAnimatedPosition = albumBasePosition -
              scrollToHeightRatio * maxAppBarHeight / 2 -
              (albumImageSize / 2 * (1.0 - albumOpacity));

          // Прозрачность названия в AppBar.
          final bool showAppBarTitle = scrollToHeightRatio > 0.7;
          final double titleOpacity = showAppBarTitle
              ? 1.0 - (maxAppBarHeight - offset) / minAppBarHeight
              : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Изображение альбома.
              if (albumOpacity > 0)
                Positioned(
                  top: albumAnimatedPosition,
                  child: Opacity(
                    opacity: albumOpacity,
                    child: Transform.scale(
                      scale: albumScale,
                      child: _buildAlbumImage(albumImageSize),
                    ),
                  ),
                ),

              // AppBar сверху.
              Container(
                decoration: showAppBarTitle
                    ? const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0D0D2B),
                            Color(0xFF0D0D2B),
                          ],
                        ),
                      )
                    : null,
                child: AppBar(
                  title: AnimatedOpacity(
                    opacity: titleOpacity,
                    duration: const Duration(milliseconds: 150),
                    child: Text(playlist.title),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlbumImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 50,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: playlist.photoUrl != null
            ? Image.network(
                playlist.photoUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) =>
                    _defaultAlbumArt(size),
              )
            : _defaultAlbumArt(size),
      ),
    );
  }

  Widget _defaultAlbumArt(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[900],
      child: Center(
        child: Icon(Icons.playlist_play, size: size * 0.3, color: Colors.grey[700]),
      ),
    );
  }
}

/// Делегат для SliverPersistentHeader.
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget Function(BuildContext context, double shrinkOffset) builder;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: builder(context, shrinkOffset),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        builder != oldDelegate.builder;
  }
}