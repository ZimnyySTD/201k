import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme_provider.dart';
import '../widgets/neumorphic_widgets.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../database/database_helper.dart';

class HomeScreen extends StatefulWidget {
  final Function(Song) onSongTap;
  final Function(Playlist) onPlaylistTap;
  final VoidCallback onImportMusic;

  const HomeScreen({
    super.key,
    required this.onSongTap,
    required this.onPlaylistTap,
    required this.onImportMusic,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _recentlyPlayed = [];
  List<Song> _recentlyAdded = [];
  List<Song> _favoriteSongs = [];
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);
    final recent = await DatabaseHelper.instance.getRecentlyPlayed(limit: 10);
    final allSongs = await DatabaseHelper.instance.getAllSongs(sortBy: 'date_added', ascending: false);
    final favorites = await DatabaseHelper.instance.getFavoriteSongs();
    final playlists = await DatabaseHelper.instance.getAllPlaylists();

    setState(() {
      _recentlyPlayed = recent;
      _recentlyAdded = allSongs.take(10).toList();
      _favoriteSongs = favorites;
      _playlists = playlists;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.textColor));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 32, bottom: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pulse Music',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: theme.textColor,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'High-Fidelity Audio Experience',
                    style: TextStyle(fontSize: 13, color: theme.subtextColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              NeumorphicButton(
                size: 48,
                onTap: widget.onImportMusic,
                child: Icon(LucideIcons.folderPlus, color: theme.textColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 28),

          if (_recentlyPlayed.isNotEmpty) ...[
            _buildSectionTitle(theme, 'Recently Played', LucideIcons.history),
            const SizedBox(height: 14),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _recentlyPlayed.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final song = _recentlyPlayed[index];
                  return _buildAlbumCard(theme, song.title, song.artist, song.artworkPath, () => widget.onSongTap(song));
                },
              ),
            ),
            const SizedBox(height: 28),
          ],

          if (_recentlyAdded.isNotEmpty) ...[
            _buildSectionTitle(theme, 'Recently Added', LucideIcons.sparkles),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentlyAdded.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final song = _recentlyAdded[index];
                return _buildSongTile(theme, song);
              },
            ),
            const SizedBox(height: 28),
          ],

          if (_favoriteSongs.isNotEmpty) ...[
            _buildSectionTitle(theme, 'Favorite Tracks', LucideIcons.heart),
            const SizedBox(height: 14),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _favoriteSongs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final song = _favoriteSongs[index];
                  return _buildAlbumCard(theme, song.title, song.artist, song.artworkPath, () => widget.onSongTap(song));
                },
              ),
            ),
            const SizedBox(height: 28),
          ],

          if (_playlists.isNotEmpty) ...[
            _buildSectionTitle(theme, 'Pinned Playlists', LucideIcons.listMusic),
            const SizedBox(height: 14),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _playlists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return GestureDetector(
                    onTap: () => widget.onPlaylistTap(playlist),
                    child: NeumorphicCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: 130,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.music, size: 36, color: theme.textColor),
                            const SizedBox(height: 12),
                            Text(
                              playlist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          if (_recentlyPlayed.isEmpty && _recentlyAdded.isEmpty) ...[
            NeumorphicCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.disc, size: 56, color: theme.subtextColor),
                    const SizedBox(height: 16),
                    Text(
                      'Your Library is Empty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to import local audio files (MP3, FLAC, AAC, WAV, OPUS, OGG).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.subtextColor, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    NeumorphicButton(
                      size: 56,
                      color: theme.textColor,
                      onTap: () async {
                        widget.onImportMusic();
                        await _loadHomeData();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.folderPlus, color: theme.surfaceColor, size: 20),
                          const SizedBox(width: 8),
                          Text('Import Audio Files', style: TextStyle(color: theme.surfaceColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeProvider theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.textColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textColor),
        ),
      ],
    );
  }

  Widget _buildAlbumCard(ThemeProvider theme, String title, String subtitle, String? artworkPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 120,
                  height: 90,
                  color: theme.textColor.withAlpha(15),
                  child: Icon(LucideIcons.disc, color: theme.textColor, size: 36),
                ),
              ),
              const SizedBox(height: 8),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.textColor)),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: theme.subtextColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongTile(ThemeProvider theme, Song song) {
    return NeumorphicCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => widget.onSongTap(song),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.textColor.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.music, color: theme.textColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textColor)),
                const SizedBox(height: 2),
                Text('${song.artist} • ${song.album}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: theme.subtextColor)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(song.isFavorite ? LucideIcons.heart : LucideIcons.heart, color: song.isFavorite ? theme.textColor : theme.subtextColor, size: 20),
            onPressed: () async {
              await DatabaseHelper.instance.toggleFavorite(song.id, !song.isFavorite);
              _loadHomeData();
            },
          )
        ],
      ),
    );
  }
}
