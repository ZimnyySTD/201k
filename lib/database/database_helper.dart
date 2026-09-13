import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final List<Song> _memSongs = [];
  final List<Playlist> _memPlaylists = [];
  final List<Map<String, dynamic>> _memPlaylistTracks = [];
  final List<Map<String, dynamic>> _memRecentlyPlayed = [];
  final Map<String, Map<String, dynamic>> _memLyrics = {};

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (_database != null) return _database;
    try {
      _database = await _initDB('pulse_music.db');
      return _database;
    } catch (e) {
      debugPrint('SQLite initialization error (falling back to memory): $e');
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath = filePath;
    if (!kIsWeb) {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = join(docsDir.path, filePath);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT NOT NULL,
        genre TEXT NOT NULL,
        year INTEGER NOT NULL,
        track_number INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        file_path TEXT NOT NULL UNIQUE,
        artwork_path TEXT,
        date_added INTEGER NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        custom_artwork_path TEXT,
        artwork_type TEXT NOT NULL DEFAULT 'collage',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_tracks (
        playlist_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, song_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE lyrics (
        song_id TEXT PRIMARY KEY,
        lrc_content TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recently_played (
        song_id TEXT PRIMARY KEY,
        played_at INTEGER NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_songs_title ON songs(title)');
    await db.execute('CREATE INDEX idx_songs_artist ON songs(artist)');
    await db.execute('CREATE INDEX idx_songs_album ON songs(album)');
    await db.execute('CREATE INDEX idx_songs_genre ON songs(genre)');
    await db.execute('CREATE INDEX idx_songs_date ON songs(date_added)');
    await db.execute('CREATE INDEX idx_playlist_tracks_pos ON playlist_tracks(playlist_id, position)');
  }

  // Songs Operations
  Future<void> insertOrUpdateSong(Song song) async {
    final db = await instance.database;
    if (db != null) {
      await db.insert('songs', song.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      _memSongs.removeWhere((s) => s.id == song.id);
      _memSongs.add(song);
    }
  }

  Future<List<Song>> getAllSongs({String sortBy = 'title', bool ascending = true}) async {
    final db = await instance.database;
    if (db != null) {
      String orderCol = 'title';
      switch (sortBy.toLowerCase()) {
        case 'artist':
          orderCol = 'artist';
          break;
        case 'album':
          orderCol = 'album';
          break;
        case 'date':
        case 'date_added':
          orderCol = 'date_added';
          break;
        case 'duration':
          orderCol = 'duration_ms';
          break;
        default:
          orderCol = 'title';
      }
      final order = ascending ? 'ASC' : 'DESC';
      final maps = await db.query('songs', orderBy: '$orderCol $order');
      return maps.map((map) => Song.fromMap(map)).toList();
    } else {
      final list = List<Song>.from(_memSongs);
      list.sort((a, b) => ascending ? a.title.compareTo(b.title) : b.title.compareTo(a.title));
      return list;
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    final db = await instance.database;
    if (db != null) {
      final q = '%$query%';
      final maps = await db.query(
        'songs',
        where: 'title LIKE ? OR artist LIKE ? OR album LIKE ? OR genre LIKE ?',
        whereArgs: [q, q, q, q],
      );
      return maps.map((map) => Song.fromMap(map)).toList();
    } else {
      final q = query.toLowerCase();
      return _memSongs.where((s) => s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q) || s.album.toLowerCase().contains(q)).toList();
    }
  }

  Future<void> toggleFavorite(String songId, bool isFavorite) async {
    final db = await instance.database;
    if (db != null) {
      await db.update('songs', {'is_favorite': isFavorite ? 1 : 0}, where: 'id = ?', whereArgs: [songId]);
    } else {
      final idx = _memSongs.indexWhere((s) => s.id == songId);
      if (idx != -1) {
        _memSongs[idx] = _memSongs[idx].copyWith(isFavorite: isFavorite);
      }
    }
  }

  Future<List<Song>> getFavoriteSongs() async {
    final db = await instance.database;
    if (db != null) {
      final maps = await db.query('songs', where: 'is_favorite = ?', whereArgs: [1]);
      return maps.map((map) => Song.fromMap(map)).toList();
    } else {
      return _memSongs.where((s) => s.isFavorite).toList();
    }
  }

  // Recently Played
  Future<void> recordRecentlyPlayed(String songId) async {
    final db = await instance.database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (db != null) {
      await db.insert('recently_played', {'song_id': songId, 'played_at': timestamp}, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      _memRecentlyPlayed.removeWhere((r) => r['song_id'] == songId);
      _memRecentlyPlayed.insert(0, {'song_id': songId, 'played_at': timestamp});
    }
  }

  Future<List<Song>> getRecentlyPlayed({int limit = 20}) async {
    final db = await instance.database;
    if (db != null) {
      final maps = await db.rawQuery('''
        SELECT s.* FROM songs s
        INNER JOIN recently_played rp ON s.id = rp.song_id
        ORDER BY rp.played_at DESC
        LIMIT ?
      ''', [limit]);
      return maps.map((map) => Song.fromMap(map)).toList();
    } else {
      final recentIds = _memRecentlyPlayed.take(limit).map((r) => r['song_id']).toSet();
      return _memSongs.where((s) => recentIds.contains(s.id)).toList();
    }
  }

  // Playlists Operations
  Future<void> createPlaylist(Playlist playlist) async {
    final db = await instance.database;
    if (db != null) {
      await db.insert('playlists', playlist.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      _memPlaylists.removeWhere((p) => p.id == playlist.id);
      _memPlaylists.add(playlist);
    }
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await instance.database;
    if (db != null) {
      final maps = await db.query('playlists', orderBy: 'name ASC');
      return maps.map((map) => Playlist.fromMap(map)).toList();
    } else {
      final list = List<Playlist>.from(_memPlaylists);
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final db = await instance.database;
    if (db != null) {
      await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
      await db.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlistId]);
    } else {
      _memPlaylists.removeWhere((p) => p.id == playlistId);
      _memPlaylistTracks.removeWhere((pt) => pt['playlist_id'] == playlistId);
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final db = await instance.database;
    if (db != null) {
      final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM playlist_tracks WHERE playlist_id = ?', [playlistId]);
      final pos = (countRes.first['cnt'] as int? ?? 0);
      await db.insert('playlist_tracks', {
        'playlist_id': playlistId,
        'song_id': songId,
        'position': pos,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      final pos = _memPlaylistTracks.where((pt) => pt['playlist_id'] == playlistId).length;
      _memPlaylistTracks.add({'playlist_id': playlistId, 'song_id': songId, 'position': pos});
    }
  }

  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final db = await instance.database;
    if (db != null) {
      final maps = await db.rawQuery('''
        SELECT s.* FROM songs s
        INNER JOIN playlist_tracks pt ON s.id = pt.song_id
        WHERE pt.playlist_id = ?
        ORDER BY pt.position ASC
      ''', [playlistId]);
      return maps.map((map) => Song.fromMap(map)).toList();
    } else {
      final trackIds = _memPlaylistTracks.where((pt) => pt['playlist_id'] == playlistId).map((pt) => pt['song_id']).toList();
      return _memSongs.where((s) => trackIds.contains(s.id)).toList();
    }
  }

  Future<void> reorderPlaylistTracks(String playlistId, List<String> songIds) async {
    final db = await instance.database;
    if (db != null) {
      final batch = db.batch();
      batch.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlistId]);
      for (int i = 0; i < songIds.length; i++) {
        batch.insert('playlist_tracks', {
          'playlist_id': playlistId,
          'song_id': songIds[i],
          'position': i,
        });
      }
      await batch.commit(noResult: true);
    } else {
      _memPlaylistTracks.removeWhere((pt) => pt['playlist_id'] == playlistId);
      for (int i = 0; i < songIds.length; i++) {
        _memPlaylistTracks.add({'playlist_id': playlistId, 'song_id': songIds[i], 'position': i});
      }
    }
  }

  // Lyrics Operations
  Future<void> saveLyrics(String songId, String lrcContent, bool isSynced) async {
    final db = await instance.database;
    if (db != null) {
      await db.insert('lyrics', {
        'song_id': songId,
        'lrc_content': lrcContent,
        'is_synced': isSynced ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      _memLyrics[songId] = {'lrc_content': lrcContent, 'is_synced': isSynced ? 1 : 0};
    }
  }

  Future<Map<String, dynamic>?> getLyrics(String songId) async {
    final db = await instance.database;
    if (db != null) {
      final res = await db.query('lyrics', where: 'song_id = ?', whereArgs: [songId]);
      if (res.isNotEmpty) return res.first;
      return null;
    } else {
      return _memLyrics[songId];
    }
  }
}
