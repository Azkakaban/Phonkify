class PlaylistSong {
  final String id;
  final String playlistId;
  final String songId;
  final int position;
  final DateTime addedAt;

  const PlaylistSong({
    required this.id,
    required this.playlistId,
    required this.songId,
    required this.position,
    required this.addedAt,
  });

  factory PlaylistSong.fromMap(
    Map<String, dynamic> map,
  ) {
    return PlaylistSong(
      id: map['id'] as String,
      playlistId: map['playlist_id'] as String,
      songId: map['song_id'] as String,
      position: map['position'] as int,
      addedAt: DateTime.parse(
        map['added_at'] as String,
      ),
    );
  }
}