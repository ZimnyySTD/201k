import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'theme/theme_provider.dart';
import 'services/playback_engine.dart';
import 'services/metadata_scanner.dart';
import 'database/database_helper.dart';
import 'models/song.dart';
import 'models/playlist.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/now_playing_screen.dart';
import 'widgets/neumorphic_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackEngine()),
      ],
      child: const PulsePlayerApp(),
    ),
  );
}

class PulsePlayerApp extends StatelessWidget {
  const PulsePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Pulse Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: theme.backgroundColor,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _addDemoDataIfEmpty();
  }

  Future<void> _addDemoDataIfEmpty() async {
    final songs = await DatabaseHelper.instance.getAllSongs();
    if (songs.isEmpty) {
      final demoSongs = [
        Song(
          id: 'demo_1',
          title: 'Midnight Resonance',
          artist: 'Acoustic Pulse',
          album: 'Sonic Horizons',
          genre: 'Ambient',
          year: 2025,
          trackNumber: 1,
          durationMs: 215000,
          filePath: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          dateAdded: DateTime.now().millisecondsSinceEpoch,
          isFavorite: true,
        ),
        Song(
          id: 'demo_2',
          title: 'Neumorphic Dreams',
          artist: 'Synthwave Minimal',
          album: 'Glass & Shadow',
          genre: 'Electronic',
          year: 2026,
          trackNumber: 2,
          durationMs: 184000,
          filePath: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          dateAdded: DateTime.now().millisecondsSinceEpoch - 100000,
          isFavorite: false,
        ),
      ];

      for (var s in demoSongs) {
        await DatabaseHelper.instance.insertOrUpdateSong(s);
      }

      await DatabaseHelper.instance.createPlaylist(Playlist(
        id: 'pl_demo_1',
        name: 'Chill Beats',
        description: 'Smooth background melodies',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      await DatabaseHelper.instance.addSongToPlaylist('pl_demo_1', 'demo_1');

      setState(() {});
    }
  }

  void _onPlaySong(Song song) {
    final engine = Provider.of<PlaybackEngine>(context, listen: false);
    engine.playSong(song);
    _openNowPlaying();
  }

  void _openNowPlaying() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final engine = Provider.of<PlaybackEngine>(context);

    final List<Widget> pages = [
      HomeScreen(
        onSongTap: _onPlaySong,
        onPlaylistTap: (p) => setState(() => _currentIndex = 3),
      ),
      LibraryScreen(onSongTap: _onPlaySong),
      SearchScreen(onSongTap: _onPlaySong),
      PlaylistsScreen(onSongTap: _onPlaySong),
      SettingsScreen(onImportComplete: () => setState(() {})),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          if (engine.currentSong != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 80,
              child: _buildMiniPlayer(engine, theme),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: theme.darkShadow.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: theme.surfaceColor,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.accentColor,
          unselectedItemColor: theme.subtextColor,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.library), label: 'Library'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.listMusic), label: 'Playlists'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(PlaybackEngine engine, ThemeProvider theme) {
    final song = engine.currentSong!;

    return GestureDetector(
      onTap: _openNowPlaying,
      child: GlassmorphicContainer(
        blur: 15,
        opacity: 0.85,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.accentColor.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.music, color: theme.accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textColor)),
                  Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: theme.subtextColor)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(engine.isPlaying ? LucideIcons.pause : LucideIcons.play, color: theme.accentColor, size: 24),
              onPressed: engine.togglePlayPause,
            ),
            IconButton(
              icon: Icon(LucideIcons.skipForward, color: theme.textColor, size: 22),
              onPressed: engine.next,
            ),
          ],
        ),
      ),
    );
  }
}
