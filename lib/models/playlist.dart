class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? customArtworkPath;
  final String artworkType; // 'custom', 'collage', 'gradient'
  final int createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.customArtworkPath,
    this.artworkType = 'collage',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'custom_artwork_path': customArtworkPath,
      'artwork_type': artworkType,
      'created_at': createdAt,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      customArtworkPath: map['custom_artwork_path'],
      artworkType: map['artwork_type'] ?? 'collage',
      createdAt: map['created_at'] ?? 0,
    );
  }
}

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class SongLyrics {
  final String songId;
  final List<LyricLine> syncedLyrics;
  final String plainText;
  final bool isSynced;

  SongLyrics({
    required this.songId,
    required this.syncedLyrics,
    required this.plainText,
    required this.isSynced,
  });
}
