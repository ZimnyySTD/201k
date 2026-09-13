import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:audiotags/audiotags.dart' as at;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/song.dart';
import '../database/database_helper.dart';

class MetadataScanner {
  /// Scans a file path or asset and extracts Song object
  static Future<Song?> scanFile(String filePath) async {
    final fileName = p.basenameWithoutExtension(filePath);
    String title = fileName;
    String artist = 'Unknown Artist';
    String album = 'Unknown Album';
    String genre = 'Unknown Genre';
    int year = 0;
    int trackNumber = 0;
    int durationMs = 0;
    String? artworkPath;

    if (!kIsWeb && File(filePath).existsSync()) {
      try {
        final tag = await at.AudioTags.read(filePath);
        if (tag != null) {
          if (tag.title != null && tag.title!.trim().isNotEmpty) title = tag.title!.trim();
          if (tag.trackArtist != null && tag.trackArtist!.trim().isNotEmpty) artist = tag.trackArtist!.trim();
          if (tag.album != null && tag.album!.trim().isNotEmpty) album = tag.album!.trim();
          if (tag.genre != null && tag.genre!.trim().isNotEmpty) genre = tag.genre!.trim();
          if (tag.year != null) year = tag.year!;
          if (tag.trackNumber != null) trackNumber = tag.trackNumber!;
          if (tag.duration != null) durationMs = (tag.duration! * 1000).toInt();

          // Embedded artwork extraction
          if (tag.pictures.isNotEmpty) {
            final pic = tag.pictures.first;
            artworkPath = await _saveArtworkBytes(pic.bytes, 'art_${title}_$artist.png');
          }
        }
      } catch (e) {
        debugPrint('Error reading audio tags from $filePath: $e');
      }

      // Check folder artwork if no embedded artwork
      if (artworkPath == null) {
        artworkPath = await _searchFolderArtwork(filePath);
      }
    }

    final songId = 'song_${filePath.hashCode}_${DateTime.now().microsecondsSinceEpoch}';
    final song = Song(
      id: songId,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      year: year,
      trackNumber: trackNumber,
      durationMs: durationMs,
      filePath: filePath,
      artworkPath: artworkPath,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
    );

    return song;
  }

  static Future<String?> _saveArtworkBytes(Uint8List bytes, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final artDir = Directory(p.join(dir.path, 'album_art'));
      if (!await artDir.exists()) {
        await artDir.create(recursive: true);
      }
      final file = File(p.join(artDir.path, filename.replaceAll(RegExp(r'[^\w\.-]'), '_')));
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving artwork bytes: $e');
      return null;
    }
  }

  static Future<String?> _searchFolderArtwork(String filePath) async {
    try {
      final dir = Directory(p.dirname(filePath));
      final files = dir.listSync();
      for (var f in files) {
        if (f is File) {
          final ext = p.extension(f.path).toLowerCase();
          final name = p.basenameWithoutExtension(f.path).toLowerCase();
          if ((ext == '.jpg' || ext == '.png' || ext == '.jpeg') &&
              (name.contains('cover') || name.contains('folder') || name.contains('album') || name.contains('art'))) {
            return f.path;
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching folder artwork: $e');
    }
    return null;
  }

  /// Online Artwork Lookup Fallback (iTunes / MusicBrainz API)
  static Future<String?> fetchOnlineArtwork(String artist, String album) async {
    try {
      final query = Uri.encodeComponent('$artist $album');
      final url = Uri.parse('https://itunes.apple.com/search?term=$query&entity=album&limit=1');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['resultCount'] > 0) {
          final artUrl = data['results'][0]['artworkUrl100']?.replaceAll('100x100bb', '600x600bb');
          if (artUrl != null) {
            final imgRes = await http.get(Uri.parse(artUrl));
            if (imgRes.statusCode == 200) {
              return await _saveArtworkBytes(imgRes.bodyBytes, 'online_${artist}_$album.png');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Online artwork fetch error: $e');
    }
    return null;
  }

  /// Update Song Tags (In database and audio file header if feasible)
  static Future<void> updateSongMetadata(Song updatedSong) async {
    await DatabaseHelper.instance.insertOrUpdateSong(updatedSong);
    if (!kIsWeb && File(updatedSong.filePath).existsSync()) {
      try {
        final tag = at.Tag(
          title: updatedSong.title,
          trackArtist: updatedSong.artist,
          album: updatedSong.album,
          genre: updatedSong.genre,
          year: updatedSong.year,
          trackNumber: updatedSong.trackNumber,
          pictures: const [],
        );
        await at.AudioTags.write(updatedSong.filePath, tag);
      } catch (e) {
        debugPrint('Error updating audio file tags: $e');
      }
    }
  }
}
