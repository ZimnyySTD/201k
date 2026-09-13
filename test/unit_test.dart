import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_player/models/song.dart';
import 'package:pulse_player/services/lyrics_service.dart';

void main() {
  group('LyricsService LRC Parser Tests', () {
    test('Should correctly parse synced LRC timestamps and text', () {
      const lrc = '''
[00:12.00]Line 1 First verse
[00:17.25]Line 2 Second verse
[01:05.50]Chorus line
''';

      final lyrics = LyricsService.parseLrc('test_song_1', lrc);

      expect(lyrics.isSynced, isTrue);
      expect(lyrics.syncedLyrics.length, equals(3));
      expect(lyrics.syncedLyrics[0].time, equals(const Duration(seconds: 12)));
      expect(lyrics.syncedLyrics[0].text, equals('Line 1 First verse'));
      expect(lyrics.syncedLyrics[1].time, equals(const Duration(seconds: 17, milliseconds: 250)));
      expect(lyrics.syncedLyrics[2].time, equals(const Duration(minutes: 1, seconds: 5, milliseconds: 500)));
    });

    test('Should handle plain text without timestamps gracefully', () {
      const plain = 'Just plain lyrics without timestamps.';
      final lyrics = LyricsService.parseLrc('test_song_2', plain);

      expect(lyrics.isSynced, isFalse);
      expect(lyrics.syncedLyrics, isEmpty);
    });
  });

  group('Song Model Tests', () {
    test('Should serialize to Map and deserialize back correctly', () {
      final song = Song(
        id: 's1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        genre: 'Rock',
        year: 2024,
        trackNumber: 1,
        durationMs: 180000,
        filePath: '/path/to/song.mp3',
        dateAdded: 100000,
        isFavorite: true,
      );

      final map = song.toMap();
      final restored = Song.fromMap(map);

      expect(restored.id, equals('s1'));
      expect(restored.title, equals('Test Song'));
      expect(restored.artist, equals('Test Artist'));
      expect(restored.isFavorite, isTrue);
    });
  });
}
