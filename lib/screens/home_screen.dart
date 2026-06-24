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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadUserMusic();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<MusicProvider>().search(query);
  }

  void _playTrack(Track track, List<Track> queue) {
    context.read<MusicProvider>().playTrack(track, queue: queue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск треков...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearch,
              )
            : const Text('VK Z'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _onSearch('');
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<MusicProvider>().logout();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('Выйти')),
            ],
          ),
        ],
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
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
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadUserMusic();
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (_isSearching && _searchController.text.isNotEmpty) {
            return _buildSearchResults(provider);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadUserMusic(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // VK Mix section
                if (provider.mix != null) ...[
                  _buildMixCard(provider.mix!),
                  const SizedBox(height: 8),
                ],

                // Recommendations section
                if (provider.recommendations.isNotEmpty) ...[
                  _buildSectionHeader('Рекомендации'),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.recommendations.length,
                      itemBuilder: (context, index) {
                        final track = provider.recommendations[index];
                        return _buildRecommendationCard(track, provider);
                      },
                    ),
                  ),
                ],

                // Playlists section
                if (provider.playlists.isNotEmpty) ...[
                  _buildSectionHeader('Мои плейлисты'),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.playlists.length,
                      itemBuilder: (context, index) {
                        return PlaylistCard(
                          playlist: provider.playlists[index],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PlaylistDetailScreen(
                                  playlist: provider.playlists[index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],

                // My tracks section
                if (provider.tracks.isNotEmpty) ...[
                  _buildSectionHeader('Мои треки'),
                  ...provider.tracks.map((track) => TrackTile(
                        track: track,
                        onTap: () => _playTrack(track, provider.tracks),
                        onPlay: () => _playTrack(track, provider.tracks),
                      )),
                ],
              ],
            ),
          );
        },
      ),
      bottomSheet: const MiniPlayer(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMixCard(Mix mix) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MixScreen(mix: mix),
          ),
        );
      },
      child: Container(
        height: 180,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[700]!,
              Colors.purple[700]!,
              Colors.deepPurple[900]!,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
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
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.yellow[400],
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mix.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mix.description ?? '${mix.tracks.length} треков',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Слушать',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  Widget _buildRecommendationCard(Track track, MusicProvider provider) {
    return GestureDetector(
      onTap: () => _playTrack(track, provider.recommendations),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 150,
                height: 150,
                color: Colors.grey[900],
                child: track.albumArtUrl != null
                    ? Image.network(
                        track.albumArtUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.music_note, size: 48),
                      )
                    : const Icon(Icons.music_note, size: 48),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(MusicProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.searchResults.isEmpty) {
      return const Center(child: Text('Ничего не найдено'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final track = provider.searchResults[index];
        return TrackTile(
          track: track,
          onTap: () => _playTrack(track, provider.searchResults),
          onPlay: () => _playTrack(track, provider.searchResults),
        );
      },
    );
  }
}