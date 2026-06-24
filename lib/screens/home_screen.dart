import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/track.dart';
import '../models/mix.dart';
import '../widgets/track_tile.dart';
import '../widgets/playlist_card.dart';
import '../widgets/mini_player.dart';
import 'playlist_detail_screen.dart';
import 'mix_screen.dart';
import 'settings_screen.dart';
import 'playlists_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

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
              _HomeTab(provider: provider, playTrack: _playTrack),
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
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[950],
        border: Border(
          top: BorderSide(color: Colors.grey[900]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Главная',
                isActive: _currentTab == 0,
                onTap: () => setState(() => _currentTab = 0),
              ),
              _NavItem(
                icon: Icons.library_music_outlined,
                activeIcon: Icons.library_music,
                label: 'Моя музыка',
                isActive: _currentTab == 1,
                onTap: () => setState(() => _currentTab = 1),
              ),
              _NavItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.search,
                label: 'Поиск',
                isActive: _currentTab == 2,
                onTap: () => setState(() => _currentTab = 2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Профиль',
                isActive: _currentTab == 3,
                onTap: () => setState(() => _currentTab = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Bottom Navigation Item
// ============================================
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? Colors.blue : Colors.grey[500],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Colors.blue : Colors.grey[500],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// TAB 0: ГЛАВНАЯ
// ============================================
class _HomeTab extends StatelessWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const _HomeTab({required this.provider, required this.playTrack});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                provider.loadUserMusic();
              },
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
      );
    }

    final hasContent = provider.mix != null ||
        provider.downloadedTracks.isNotEmpty ||
        provider.recommendations.isNotEmpty;

    if (!provider.isLoading && !hasContent) {
      return RefreshIndicator(
        onRefresh: () => provider.loadUserMusic(),
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note_outlined, size: 72, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'Музыка загружается...',
                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Потяните вниз для обновления',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadUserMusic(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const SizedBox(height: 8),

          // VK Mix card
          if (provider.mix != null) ...[
            _buildMixCard(context, provider.mix!),
            const SizedBox(height: 8),
          ],

          // Downloaded tracks summary
          if (provider.downloadedTracks.isNotEmpty) ...[
            _buildDownloadsCard(context),
            const SizedBox(height: 8),
          ],

          // Recommendations
          if (provider.recommendations.isNotEmpty) ...[
            _SectionHeader(title: 'Рекомендации'),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.recommendations.length,
                itemBuilder: (context, index) {
                  final track = provider.recommendations[index];
                  return _RecommendationCard(
                    track: track,
                    onTap: () => playTrack(track, provider.recommendations),
                  );
                },
              ),
            ),
          ],

          // Recently played / popular section placeholder
          if (provider.tracks.isNotEmpty) ...[
            _SectionHeader(title: 'Недавно прослушано'),
            ...provider.tracks.take(5).map((track) => TrackTile(
                  track: track,
                  onTap: () => playTrack(track, provider.tracks),
                  onPlay: () => playTrack(track, provider.tracks),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildMixCard(BuildContext context, Mix mix) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MixScreen(mix: mix)),
        );
      },
      child: Container(
        height: 160,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF0D0D2B)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 120, height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0FFFFFFF),
                ),
              ),
            ),
            Positioned(
              right: 40, bottom: -30,
              child: Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0FFFFFFF),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    mix.title,
                    style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mix.description ?? '${mix.tracks.length} треков',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Слушать', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _DownloadedTracksScreen(provider: provider),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download_done, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Скачано', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('${provider.downloadedTracks.length} треков',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// TAB 1: МОЯ МУЗЫКА
// ============================================
class _MusicTab extends StatelessWidget {
  final MusicProvider provider;
  final Function(Track, List<Track>) playTrack;

  const _MusicTab({required this.provider, required this.playTrack});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.tracks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                provider.loadUserMusic();
              },
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
      );
    }

    final hasContent = provider.playlists.isNotEmpty || provider.tracks.isNotEmpty;

    if (!provider.isLoading && !hasContent) {
      return RefreshIndicator(
        onRefresh: () => provider.loadUserMusic(),
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.library_music_outlined, size: 72, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'Нет музыки',
                    style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Потяните вниз для обновления',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadUserMusic(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const SizedBox(height: 8),

          // Playlists
          if (provider.playlists.isNotEmpty) ...[
            _SectionHeaderWithAction(
              title: 'Мои плейлисты',
              actionLabel: 'Показать все',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PlaylistsScreen(),
                  ),
                );
              },
            ),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.playlists.length,
                itemBuilder: (context, index) {
                  final playlist = provider.playlists[index];
                  return PlaylistCard(
                    playlist: playlist,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(playlist: playlist),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],

          // My tracks
          if (provider.tracks.isNotEmpty) ...[
            _SectionHeader(title: 'Мои треки'),
            ...provider.tracks.map((track) => TrackTile(
                  track: track,
                  onTap: () => playTrack(track, provider.tracks),
                  onPlay: () => playTrack(track, provider.tracks),
                )),
          ],
        ],
      ),
    );
  }
}

// ============================================
// TAB 2: ПОИСК
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
// TAB 3: ПРОФИЛЬ
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
// SHARED WIDGETS
// ============================================
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SectionHeaderWithAction extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeaderWithAction({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _RecommendationCard({required this.track, required this.onTap});

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
                child: track.albumArtUrl != null
                    ? Image.network(track.albumArtUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 40))
                    : const Icon(Icons.music_note, size: 40),
              ),
            ),
            const SizedBox(height: 6),
            Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
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