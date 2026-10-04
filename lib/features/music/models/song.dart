class Song {
  final String id;
  final String title;
  final String artist;
  final String? albumId;
  final String audioUrl;
  final String? coverUrl;
  final int duration;
  final double? bpm;
  final double? energy;
  final double? danceability;
  final double? valence;
  final String? subgenre;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.albumId,
    required this.audioUrl,
    this.coverUrl,
    required this.duration,
    this.bpm,
    this.energy,
    this.danceability,
    this.valence,
    this.subgenre,
    this.createdAt,
    this.updatedAt,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      albumId: map['album_id'] as String?,
      audioUrl: map['audio_url'] as String,
      coverUrl: map['cover_url'] as String?,
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      bpm: (map['bpm'] as num?)?.toDouble(),
      energy: (map['energy'] as num?)?.toDouble(),
      danceability: (map['danceability'] as num?)?.toDouble(),
      valence: (map['valence'] as num?)?.toDouble(),
      subgenre: map['subgenre'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album_id': albumId,
      'audio_url': audioUrl,
      'cover_url': coverUrl,
      'duration': duration,
      'bpm': bpm,
      'energy': energy,
      'danceability': danceability,
      'valence': valence,
      'subgenre': subgenre,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}