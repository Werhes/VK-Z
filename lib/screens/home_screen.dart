import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';
import '../widgets/mini_player.dart';
import 'my_music_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  // Tabs: 0=Моя музыка, 1=Поиск, 2=Профиль

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
              _SearchTab(provider: provider, playTrack: _playTrack),
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
                label: 'Моя музыка',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Поиск',
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
// TAB 0: МОЯ МУЗЫКА
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
// TAB 1: ПОИСК
// ============================================
class _SearchTab extends StatefulWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const _SearchTab({required this.provider, required this.playTrack});

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() => _hasSearched = query.isNotEmpty);
    widget.provider.search(query);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Поиск треков, исполнителей...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                onChanged: _onSearch,
              ),
            ),
          ),

          // Results
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('Найдите свою музыку',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    if (widget.provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.provider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text('Ничего не найдено',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: widget.provider.searchResults.length,
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