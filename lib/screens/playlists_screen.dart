import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme_provider.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../database/database_helper.dart';
import '../widgets/neumorphic_widgets.dart';

class PlaylistsScreen extends StatefulWidget {
  final Function(Song) onSongTap;

  const PlaylistsScreen({super.key, required this.onSongTap});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    final lists = await DatabaseHelper.instance.getAllPlaylists();
    setState(() {
      _playlists = lists;
      _isLoading = false;
    });
  }

  void _showCreatePlaylistDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Playlist Name')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (Optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  final newPl = Playlist(
                    id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  await DatabaseHelper.instance.createPlaylist(newPl);
                  if (mounted) Navigator.pop(context);
                  _loadPlaylists();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        title: Text('Playlists', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: theme.textColor),
            onPressed: _showCreatePlaylistDialog,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.textColor))
          : _playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.listMusic, size: 56, color: theme.subtextColor.withAlpha(100)),
                      const SizedBox(height: 16),
                      Text('No Playlists Created', style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: theme.textColor, foregroundColor: theme.surfaceColor),
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Create Playlist'),
                        onPressed: _showCreatePlaylistDialog,
                      )
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 140),
                  itemCount: _playlists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final pl = _playlists[index];
                    return NeumorphicCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      onTap: () => _openPlaylistDetails(pl),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: theme.textColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(LucideIcons.listMusic, color: theme.textColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pl.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textColor)),
                                if (pl.description != null && pl.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(pl.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                                ]
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(LucideIcons.trash2, color: theme.subtextColor, size: 20),
                            onPressed: () async {
                              await DatabaseHelper.instance.deletePlaylist(pl.id);
                              _loadPlaylists();
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _openPlaylistDetails(Playlist playlist) async {
    final songs = await DatabaseHelper.instance.getPlaylistSongs(playlist.id);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PlaylistDetailsScreen(
          playlist: playlist,
          songs: songs,
          onSongTap: widget.onSongTap,
        ),
      ),
    );
  }
}

class _PlaylistDetailsScreen extends StatefulWidget {
  final Playlist playlist;
  final List<Song> songs;
  final Function(Song) onSongTap;

  const _PlaylistDetailsScreen({required this.playlist, required this.songs, required this.onSongTap});

  @override
  State<_PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<_PlaylistDetailsScreen> {
  late List<Song> _songs;

  @override
  void initState() {
    super.initState();
    _songs = List.from(widget.songs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: theme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text(widget.playlist.name, style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: NeumorphicCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.textColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(LucideIcons.listMusic, color: theme.textColor, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.playlist.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textColor)),
                        Text('${_songs.length} tracks', style: TextStyle(color: theme.subtextColor)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 140),
              itemCount: _songs.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final item = _songs.removeAt(oldIndex);
                _songs.insert(newIndex, item);
                setState(() {});
                await DatabaseHelper.instance.reorderPlaylistTracks(widget.playlist.id, _songs.map((s) => s.id).toList());
              },
              itemBuilder: (context, index) {
                final song = _songs[index];
                return Padding(
                  key: ValueKey(song.id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NeumorphicCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(12),
                    onTap: () => widget.onSongTap(song),
                    child: Row(
                      children: [
                        Icon(LucideIcons.gripVertical, color: theme.subtextColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song.title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor)),
                              Text(song.artist, style: TextStyle(color: theme.subtextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
