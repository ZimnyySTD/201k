import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';
import '../database/database_helper.dart';

class LyricsService {
  /// Parses LRC string format into structured SongLyrics object
  static SongLyrics parseLrc(String songId, String lrcContent) {
    final List<LyricLine> syncedLines = [];
    final lines = LineSplitter.split(lrcContent);
    final RegExp regExp = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (var line in lines) {
      final match = regExp.firstMatch(line.trim());
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3)!;
        final ms = int.parse(msStr.padRight(3, '0').substring(0, 3));
        final text = match.group(4)!.trim();
        final time = Duration(minutes: min, seconds: sec, milliseconds: ms);
        syncedLines.add(LyricLine(time: time, text: text));
      }
    }

    syncedLines.sort((a, b) => a.time.compareTo(b.time));

    final isSynced = syncedLines.isNotEmpty;
    return SongLyrics(
      songId: songId,
      syncedLyrics: syncedLines,
      plainText: lrcContent,
      isSynced: isSynced,
    );
  }

  /// Get lyrics from DB or fallback online
  static Future<SongLyrics?> getLyricsForSong(String songId, String title, String artist) async {
    final dbLyrics = await DatabaseHelper.instance.getLyrics(songId);
    if (dbLyrics != null) {
      return parseLrc(songId, dbLyrics['lrc_content']);
    }

    // Try fetching online from LRCLIB
    try {
      final url = Uri.parse('https://lrclib.net/api/get?track_name=${Uri.encodeComponent(title)}&artist_name=${Uri.encodeComponent(artist)}');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final syncedLrc = data['syncedLyrics'] as String?;
        final plainLrc = data['plainLyrics'] as String?;
        final lrcText = syncedLrc ?? plainLrc;
        if (lrcText != null && lrcText.isNotEmpty) {
          final isSynced = syncedLrc != null && syncedLrc.isNotEmpty;
          await DatabaseHelper.instance.saveLyrics(songId, lrcText, isSynced);
          return parseLrc(songId, lrcText);
        }
      }
    } catch (e) {
      debugPrint('LRCLIB fetch error: $e');
    }

    return null;
  }
}
