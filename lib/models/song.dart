class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int year;
  final int trackNumber;
  final int durationMs;
  final String filePath;
  final String? artworkPath;
  final int dateAdded;
  final bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.year,
    required this.trackNumber,
    required this.durationMs,
    required this.filePath,
    this.artworkPath,
    required this.dateAdded,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'year': year,
      'track_number': trackNumber,
      'duration_ms': durationMs,
      'file_path': filePath,
      'artwork_path': artworkPath,
      'date_added': dateAdded,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'] ?? 'Unknown Title',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'] ?? 'Unknown Album',
      genre: map['genre'] ?? 'Unknown Genre',
      year: map['year'] ?? 0,
      trackNumber: map['track_number'] ?? 0,
      durationMs: map['duration_ms'] ?? 0,
      filePath: map['file_path'],
      artworkPath: map['artwork_path'],
      dateAdded: map['date_added'] ?? 0,
      isFavorite: (map['is_favorite'] ?? 0) == 1,
    );
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? year,
    int? trackNumber,
    int? durationMs,
    String? filePath,
    String? artworkPath,
    int? dateAdded,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      durationMs: durationMs ?? this.durationMs,
      filePath: filePath ?? this.filePath,
      artworkPath: artworkPath ?? this.artworkPath,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
