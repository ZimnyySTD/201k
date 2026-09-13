import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme_provider.dart';
import '../models/song.dart';
import '../database/database_helper.dart';
import '../widgets/neumorphic_widgets.dart';
import '../services/metadata_scanner.dart';

class LibraryScreen extends StatefulWidget {
  final Function(Song) onSongTap;
  final VoidCallback onImportMusic;

  const LibraryScreen({super.key, required this.onSongTap, required this.onImportMusic});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Song> _songs = [];
  String _sortBy = 'title';
  bool _ascending = true;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final songs = await DatabaseHelper.instance.getAllSongs(sortBy: _sortBy, ascending: _ascending);
    setState(() {
      _songs = songs;
      _isLoading = false;
    });
  }

  List<Song> get _filteredSongs {
    if (_searchQuery.trim().isEmpty) return _songs;
    final q = _searchQuery.toLowerCase();
    return _songs.where((s) => s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q) || s.album.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        title: Text('Music Library', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.folderPlus, color: theme.textColor),
            onPressed: () async {
              widget.onImportMusic();
              await _loadSongs();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.arrowUpDown, color: theme.textColor),
            onSelected: (val) {
              setState(() {
                if (_sortBy == val) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = val;
                  _ascending = true;
                }
              });
              _loadSongs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'title', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'artist', child: Text('Sort by Artist')),
              const PopupMenuItem(value: 'album', child: Text('Sort by Album')),
              const PopupMenuItem(value: 'date_added', child: Text('Sort by Date Added')),
              const PopupMenuItem(value: 'duration', child: Text('Sort by Duration')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: theme.textColor,
          labelColor: theme.textColor,
          unselectedLabelColor: theme.subtextColor,
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Genres'),
            Tab(text: 'Folders'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: NeumorphicCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  hintStyle: TextStyle(color: theme.subtextColor),
                  border: InputBorder.none,
                  icon: Icon(LucideIcons.search, color: theme.subtextColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsTab(theme),
                _buildAlbumsTab(theme),
                _buildArtistsTab(theme),
                _buildGenresTab(theme),
                _buildFoldersTab(theme),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSongsTab(ThemeProvider theme) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: theme.textColor));
    final list = _filteredSongs;
    if (list.isEmpty) return _buildEmptyState(theme, 'No songs found in library');

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 140),
      itemBuilder: (context, index) {
        final song = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NeumorphicCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(12),
            onTap: () => widget.onSongTap(song),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.music, color: theme.textColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textColor)),
                      const SizedBox(height: 4),
                      Text('${song.artist} • ${song.album}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: theme.subtextColor)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.moreVertical, color: theme.subtextColor),
                  onPressed: () => _showSongOptions(song),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSongOptions(Song song) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.pencil),
                title: const Text('Edit Metadata'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMetadataDialog(song);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.heart),
                title: Text(song.isFavorite ? 'Remove Favorite' : 'Mark as Favorite'),
                onTap: () async {
                  await DatabaseHelper.instance.toggleFavorite(song.id, !song.isFavorite);
                  Navigator.pop(context);
                  _loadSongs();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditMetadataDialog(Song song) {
    final titleCtrl = TextEditingController(text: song.title);
    final artistCtrl = TextEditingController(text: song.artist);
    final albumCtrl = TextEditingController(text: song.album);
    final genreCtrl = TextEditingController(text: song.genre);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Metadata'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: artistCtrl, decoration: const InputDecoration(labelText: 'Artist')),
                TextField(controller: albumCtrl, decoration: const InputDecoration(labelText: 'Album')),
                TextField(controller: genreCtrl, decoration: const InputDecoration(labelText: 'Genre')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = song.copyWith(
                  title: titleCtrl.text.trim(),
                  artist: artistCtrl.text.trim(),
                  album: albumCtrl.text.trim(),
                  genre: genreCtrl.text.trim(),
                );
                await MetadataScanner.updateSongMetadata(updated);
                if (mounted) Navigator.pop(context);
                _loadSongs();
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  Widget _buildAlbumsTab(ThemeProvider theme) {
    final albums = <String, List<Song>>{};
    for (var s in _filteredSongs) {
      albums.putIfAbsent(s.album, () => []).add(s);
    }
    if (albums.isEmpty) return _buildEmptyState(theme, 'No albums found');

    final keys = albums.keys.toList();
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 140),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final albumName = keys[index];
        final songList = albums[albumName]!;
        final artistName = songList.first.artist;
        return NeumorphicCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.textColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(LucideIcons.disc, color: theme.textColor, size: 48),
                ),
              ),
              const SizedBox(height: 8),
              Text(albumName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor)),
              Text('$artistName • ${songList.length} tracks', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: theme.subtextColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab(ThemeProvider theme) {
    final artists = <String, List<Song>>{};
    for (var s in _filteredSongs) {
      artists.putIfAbsent(s.artist, () => []).add(s);
    }
    if (artists.isEmpty) return _buildEmptyState(theme, 'No artists found');

    final keys = artists.keys.toList();
    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 140),
      itemCount: keys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final artist = keys[index];
        final tracks = artists[artist]!;
        return NeumorphicCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: theme.textColor.withAlpha(20), child: Icon(LucideIcons.user, color: theme.textColor)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artist, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor, fontSize: 16)),
                  Text('${tracks.length} songs', style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenresTab(ThemeProvider theme) {
    return _buildEmptyState(theme, 'No genre filters active');
  }

  Widget _buildFoldersTab(ThemeProvider theme) {
    return _buildEmptyState(theme, 'No folder structure imported');
  }

  Widget _buildEmptyState(ThemeProvider theme, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.folderOpen, size: 48, color: theme.subtextColor),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: theme.subtextColor, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: theme.textColor, foregroundColor: theme.surfaceColor),
            icon: const Icon(LucideIcons.folderPlus, size: 18),
            label: const Text('Import Local Songs'),
            onPressed: () async {
              widget.onImportMusic();
              await _loadSongs();
            },
          )
        ],
      ),
    );
  }
}
