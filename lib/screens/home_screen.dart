import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/music_category.dart';
import '../widgets/playlist_card.dart';
import 'my_music_screen.dart';
import 'settings_screen.dart';
import 'playlist_detail_screen.dart';
import 'mix_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  // Tabs: 0=Библиотека, 1=Музыка, 2=Профиль

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadUserMusic();
    });
  }

  void _playTrack(Track track, List<Track> queue) {
    context.read<MusicProvider>().playTrack(track, queue: queue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          return IndexedStack(
            index: _currentTab,
            children: [
              _MusicTab(provider: provider, playTrack: _playTrack),
              _MusicHomeTab(provider: provider, playTrack: _playTrack),
              _ProfileTab(provider: provider, playTrack: _playTrack),
            ],
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _currentTab,
            onDestinationSelected: (int index) {
              setState(() => _currentTab = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.music_note_outlined),
                selectedIcon: Icon(Icons.music_note),
                label: 'Библиотека',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Музыка',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Профиль',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// TAB 0: БИБЛИОТЕКА
// ============================================
class _MusicTab extends StatelessWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const _MusicTab({required this.provider, required this.playTrack});

  @override
  Widget build(BuildContext context) {
    return MyMusicScreen(
      provider: provider,
      playTrack: playTrack,
    );
  }
}

// ============================================
// TAB 1: МУЗЫКА (как FlutterVK MusicRoute)
// ============================================

/// Виджет, показывающий кучку переключателей-фильтров для включения различных разделов "музыки".
class _ChipFilters extends StatelessWidget {
  final bool myMusicEnabled;
  final bool playlistsEnabled;
  final ValueChanged<bool> onMyMusicChanged;
  final ValueChanged<bool> onPlaylistsChanged;

  const _ChipFilters({
    required this.myMusicEnabled,
    required this.playlistsEnabled,
    required this.onMyMusicChanged,
    required this.onPlaylistsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          onSelected: onMyMusicChanged,
          selected: myMusicEnabled,
          label: const Text('Моя музыка'),
        ),
        FilterChip(
          onSelected: onPlaylistsChanged,
          selected: playlistsEnabled,
          label: const Text('Ваши плейлисты'),
        ),
      ],
    );
  }
}

/// Виджет с разделом "Моя музыка" (как FlutterVK MyMusicBlock)
class _MyMusicBlock extends StatelessWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const _MyMusicBlock({required this.provider, required this.playTrack});

  @override
  Widget build(BuildContext context) {
    final tracks = provider.tracks;
    final musicCount = tracks.length;
    final clampedMusicCount = musicCount.clamp(0, 10);

    return MusicCategory(
      title: 'Моя музыка',
      count: musicCount,
      children: [
        // Настоящие данные.
        if (tracks.isNotEmpty && clampedMusicCount > 0)
          for (int index = 0; index < clampedMusicCount; index++) ...[
            TrackTile(
              track: tracks[index],
              onTap: () => playTrack(tracks[index], tracks),
              onPlay: () => playTrack(tracks[index], tracks),
            ),
            const SizedBox(height: 4),
          ],

        const SizedBox(height: 8),

        // Кнопки для управления.
        Wrap(
          spacing: 8,
          children: [
            // "Перемешать".
            FilledButton.icon(
              icon: const Icon(Icons.shuffle),
              label: const Text('Перемешать'),
              onPressed: tracks.isNotEmpty
                  ? () {
                      final shuffled = List<Track>.from(tracks)..shuffle();
                      playTrack(shuffled.first, shuffled);
                    }
                  : null,
            ),

            // "Все треки".
            FilledButton.tonalIcon(
              onPressed: tracks.isNotEmpty
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => _AllTracksScreen(
                            tracks: tracks,
                            playTrack: playTrack,
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.queue_music),
              label: const Text('Все треки'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Экран со всеми треками (открывается по кнопке "Все треки")
class _AllTracksScreen extends StatelessWidget {
  final List<Track> tracks;
  final Function(Track, List<Track>) playTrack;

  const _AllTracksScreen({required this.tracks, required this.playTrack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все треки'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return TrackTile(
            track: track,
            onTap: () => playTrack(track, tracks),
            onPlay: () => playTrack(track, tracks),
          );
        },
      ),
    );
  }
}

/// Виджет с разделом "Ваши плейлисты" (как FlutterVK MyPlaylistsBlock)
class _MyPlaylistsBlock extends StatelessWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const _MyPlaylistsBlock({required this.provider, required this.playTrack});

  @override
  Widget build(BuildContext context) {
    final playlists = provider.playlists;

    return MusicCategory(
      title: 'Ваши плейлисты',
      count: playlists.length,
      children: [
        SizedBox(
          height: 210,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: playlists.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return SizedBox(
                width: 160,
                child: PlaylistCard(
                  playlist: playlist,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(
                          playlist: playlist,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Диалог поиска (как FlutterVK SearchDisplayDialog)
class _SearchDisplayDialog extends StatefulWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const _SearchDisplayDialog({
    required this.provider,
    required this.playTrack,
  });

  @override
  State<_SearchDisplayDialog> createState() => _SearchDisplayDialogState();
}

class _SearchDisplayDialogState extends State<_SearchDisplayDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() => _hasSearched = query.isNotEmpty);
    widget.provider.search(query);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 650,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Верхний AppBar.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Поиск.
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Поиск музыки',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _controller.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsetsDirectional.only(end: 12),
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _controller.clear();
                                    _onSearch('');
                                  },
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Содержимое поиска.
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return Center(
        child: Text(
          'Начните вводить запрос...',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    if (widget.provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.provider.searchResults.isEmpty) {
      return Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.separated(
      itemCount: widget.provider.searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final track = widget.provider.searchResults[index];
        return TrackTile(
          track: track,
          onTap: () => widget.playTrack(track, widget.provider.searchResults),
          onPlay: () => widget.playTrack(track, widget.provider.searchResults),
        );
      },
    );
  }
}

/// Главная страница музыки (как FlutterVK MusicRoute)
class _MusicHomeTab extends StatefulWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const _MusicHomeTab({required this.provider, required this.playTrack});

  @override
  State<_MusicHomeTab> createState() => _MusicHomeTabState();
}

class _MusicHomeTabState extends State<_MusicHomeTab> {
  bool _myMusicEnabled = true;
  bool _playlistsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    final List<Widget> activeBlocks = [];

    if (_myMusicEnabled) {
      activeBlocks.add(_MyMusicBlock(
        provider: provider,
        playTrack: widget.playTrack,
      ));
    }

    if (_playlistsEnabled) {
      activeBlocks.add(_MyPlaylistsBlock(
        provider: provider,
        playTrack: widget.playTrack,
      ));
    }

    if (activeBlocks.isEmpty) {
      activeBlocks.add(
        Column(
          children: [
            const Text(
              'Как пусто...',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Соскучились по музыке? Включите разделы выше!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator.adaptive(
        onRefresh: () => provider.loadUserMusic(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Верхняя часть с приветствием и поиском.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Аватарка пользователя.
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue[800],
                          child: const Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 18),

                        // Текст "Добро пожаловать".
                        Text(
                          'Добро пожаловать',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Настройки микса.
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.grey),
                  tooltip: 'Настройки микса',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MixSettingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 4),

                // Поиск.
                IconButton.filledTonal(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _SearchDisplayDialog(
                        provider: provider,
                        playTrack: widget.playTrack,
                      ),
                    );
                  },
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Фильтры.
            _ChipFilters(
              myMusicEnabled: _myMusicEnabled,
              playlistsEnabled: _playlistsEnabled,
              onMyMusicChanged: (value) => setState(() => _myMusicEnabled = value),
              onPlaylistsChanged: (value) => setState(() => _playlistsEnabled = value),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),

            // Активные блоки.
            for (int i = 0; i < activeBlocks.length; i++) ...[
              activeBlocks[i],
              if (i < activeBlocks.length - 1) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
              ],
            ],

            // Отступ для мини-плеера.
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TAB 2: ПРОФИЛЬ
// ============================================
class _ProfileTab extends StatelessWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const _ProfileTab({required this.provider, required this.playTrack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue[800],
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Мой профиль',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${provider.tracks.length} треков',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Menu items
          _MenuTile(
            icon: Icons.settings_outlined,
            title: 'Настройки',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.download_outlined,
            title: 'Скачанные треки',
            trailing: provider.downloadedTracks.isNotEmpty
                ? Text('${provider.downloadedTracks.length}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14))
                : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => _DownloadedTracksScreen(provider: provider),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.logout,
            title: 'Выйти',
            titleColor: Colors.red[400],
            iconColor: Colors.red[400],
            onTap: () {
              provider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[400], size: 24),
      title: Text(title, style: TextStyle(color: titleColor ?? Colors.white, fontSize: 15)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ============================================
// DOWNLOADED TRACKS SCREEN
// ============================================
class _DownloadedTracksScreen extends StatelessWidget {
  final MusicProvider provider;

  const _DownloadedTracksScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Скачанные треки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadDownloadedTracks(),
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingDownloads) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.downloadedTracks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('Нет скачанных треков',
                      style: TextStyle(fontSize: 18, color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text('Скачайте треки, чтобы слушать офлайн',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: provider.downloadedTracks.length,
            itemBuilder: (context, index) {
              final track = provider.downloadedTracks[index];
              return TrackTile(
                track: track,
                showDownloadButton: true,
                onTap: () => provider.playTrack(track, queue: provider.downloadedTracks),
                onPlay: () => provider.playTrack(track, queue: provider.downloadedTracks),
              );
            },
          );
        },
      ),
    );
  }
}