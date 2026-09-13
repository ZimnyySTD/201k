import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/theme_provider.dart';
import '../services/playback_engine.dart';
import '../services/lyrics_service.dart';
import '../models/playlist.dart';
import '../database/database_helper.dart';
import '../widgets/neumorphic_widgets.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _showLyrics = false;
  bool _showQueue = false;
  SongLyrics? _lyrics;
  bool _isLoadingLyrics = false;
  final ScrollController _lyricsScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  void _fetchLyrics() async {
    final engine = Provider.of<PlaybackEngine>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    if (engine.currentSong != null) {
      theme.updateAccentFromImage(engine.currentSong!.artworkPath);
      setState(() => _isLoadingLyrics = true);
      final lyrics = await LyricsService.getLyricsForSong(
        engine.currentSong!.id,
        engine.currentSong!.title,
        engine.currentSong!.artist,
      );
      if (mounted) {
        setState(() {
          _lyrics = lyrics;
          _isLoadingLyrics = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<PlaybackEngine>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final song = engine.currentSong;

    if (song == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(child: Text('No song selected', style: TextStyle(color: theme.textColor))),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Blurred Artwork Background
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withAlpha(200),
                    theme.backgroundColor,
                    theme.secondaryColor.withAlpha(150),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withAlpha(40)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronDown, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Text('PLAYING FROM LIBRARY', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 2),
                          Text(song.album, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.listMusic, color: _showQueue ? theme.accentColor : Colors.white, size: 24),
                        onPressed: () => setState(() => _showQueue = !_showQueue),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _showQueue
                      ? _buildQueueView(engine, theme)
                      : _showLyrics
                          ? _buildLyricsView(engine, theme)
                          : _buildArtworkView(song, theme),
                ),

                // Controls Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    children: [
                      // Song Title & Artist
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 16)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(song.isFavorite ? LucideIcons.heart : LucideIcons.heart, color: song.isFavorite ? theme.accentColor : Colors.white70, size: 26),
                            onPressed: () async {
                              final newFav = !song.isFavorite;
                              await DatabaseHelper.instance.toggleFavorite(song.id, newFav);
                              final updated = song.copyWith(isFavorite: newFav);
                              engine.playSong(updated);
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Progress Bar
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          activeTrackColor: theme.accentColor,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: engine.position.inMilliseconds.toDouble().clamp(0.0, engine.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity)),
                          min: 0.0,
                          max: engine.duration.inMilliseconds.toDouble() > 0 ? engine.duration.inMilliseconds.toDouble() : 1.0,
                          onChanged: (val) {
                            engine.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(engine.position), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
                            Text(_formatDuration(engine.duration), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Playback Action Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(LucideIcons.shuffle, color: engine.isShuffle ? theme.accentColor : Colors.white60, size: 22),
                            onPressed: engine.toggleShuffle,
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.skipBack, color: Colors.white, size: 32),
                            onPressed: engine.previous,
                          ),
                          NeumorphicButton(
                            size: 68,
                            color: theme.accentColor,
                            onTap: engine.togglePlayPause,
                            child: Icon(
                              engine.isPlaying ? LucideIcons.pause : LucideIcons.play,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.skipForward, color: Colors.white, size: 32),
                            onPressed: engine.next,
                          ),
                          IconButton(
                            icon: Icon(
                              engine.loopMode == LoopModeState.one ? LucideIcons.repeat1 : LucideIcons.repeat,
                              color: engine.loopMode != LoopModeState.off ? theme.accentColor : Colors.white60,
                              size: 22,
                            ),
                            onPressed: engine.toggleLoopMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Toggle Lyrics Button
                      GestureDetector(
                        onTap: () => setState(() => _showLyrics = !_showLyrics),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _showLyrics ? theme.accentColor.withAlpha(60) : Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.quote, size: 16, color: _showLyrics ? theme.accentColor : Colors.white70),
                              const SizedBox(width: 8),
                              Text(_showLyrics ? 'Hide Lyrics' : 'View Lyrics', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
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
    );
  }

  Widget _buildArtworkView(song, ThemeProvider theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withAlpha(120),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              color: Colors.white12,
              child: Icon(LucideIcons.disc, color: theme.accentColor, size: 120),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsView(PlaybackEngine engine, ThemeProvider theme) {
    if (_isLoadingLyrics) {
      return Center(child: CircularProgressIndicator(color: theme.accentColor));
    }
    if (_lyrics == null || _lyrics!.syncedLyrics.isEmpty) {
      return Center(
        child: Text('No Lyrics Available', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 18, fontWeight: FontWeight.bold)),
      );
    }

    final currentPos = engine.position;
    int currentLineIdx = -1;
    for (int i = 0; i < _lyrics!.syncedLyrics.length; i++) {
      if (currentPos >= _lyrics!.syncedLyrics[i].time) {
        currentLineIdx = i;
      }
    }

    return ListView.builder(
      controller: _lyricsScrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      itemCount: _lyrics!.syncedLyrics.length,
      itemBuilder: (context, index) {
        final line = _lyrics!.syncedLyrics[index];
        final isHighlighted = index == currentLineIdx;

        return GestureDetector(
          onTap: () => engine.seek(line.time),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              line.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isHighlighted ? theme.accentColor : Colors.white54,
                fontSize: isHighlighted ? 22 : 17,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueView(PlaybackEngine engine, ThemeProvider theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: engine.queue.length,
      itemBuilder: (context, index) {
        final s = engine.queue[index];
        final isCurrent = index == engine.currentIndex;

        return ListTile(
          leading: Icon(LucideIcons.music, color: isCurrent ? theme.accentColor : Colors.white70),
          title: Text(s.title, style: TextStyle(color: isCurrent ? theme.accentColor : Colors.white, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
          subtitle: Text(s.artist, style: TextStyle(color: Colors.white60, fontSize: 12)),
          onTap: () => engine.playSong(s),
        );
      },
    );
  }
}
