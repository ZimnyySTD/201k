import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme_provider.dart';
import '../models/song.dart';
import '../database/database_helper.dart';
import '../widgets/neumorphic_widgets.dart';

class SearchScreen extends StatefulWidget {
  final Function(Song) onSongTap;

  const SearchScreen({super.key, required this.onSongTap});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Song> _results = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final res = await DatabaseHelper.instance.searchSongs(query);
    setState(() {
      _results = res;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        title: Text('Search Music', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            NeumorphicCard(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Type song name, artist, or album...',
                  hintStyle: TextStyle(color: theme.subtextColor),
                  border: InputBorder.none,
                  icon: Icon(LucideIcons.search, color: theme.accentColor),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(LucideIcons.x, color: theme.subtextColor),
                          onPressed: () {
                            _controller.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isSearching
                  ? Center(child: CircularProgressIndicator(color: theme.accentColor))
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.search, size: 56, color: theme.subtextColor.withAlpha(100)),
                              const SizedBox(height: 16),
                              Text(
                                _controller.text.isEmpty ? 'Instant Indexed Search' : 'No matching tracks found',
                                style: TextStyle(color: theme.subtextColor, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final song = _results[index];
                            return NeumorphicCard(
                              borderRadius: 16,
                              padding: const EdgeInsets.all(12),
                              onTap: () => widget.onSongTap(song),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: theme.accentColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(LucideIcons.music, color: theme.accentColor, size: 22),
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
                                  Icon(LucideIcons.playCircle, color: theme.accentColor, size: 24)
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
