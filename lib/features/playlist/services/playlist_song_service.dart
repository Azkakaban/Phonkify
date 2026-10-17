import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/playlist_song.dart';

class PlaylistSongService {
  PlaylistSongService._();

  static final PlaylistSongService instance =
      PlaylistSongService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<PlaylistSong>> getPlaylistSongs(
    String playlistId,
  ) async {
    final response = await _supabase
        .from('playlist_songs')
        .select(
          'id, playlist_id, song_id, position, added_at',
        )
        .eq('playlist_id', playlistId)
        .order('position');

    return (response as List)
        .map(
          (item) => PlaylistSong.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> addSongToPlaylist({
    required String playlistId,
    required String songId,
    required int position,
  }) async {
    await _supabase.from('playlist_songs').insert({
      'playlist_id': playlistId,
      'song_id': songId,
      'position': position,
    });
  }

  Future<int> getNextPosition(
    String playlistId,
  ) async {
    final response = await _supabase
        .from('playlist_songs')
        .select('position')
        .eq('playlist_id', playlistId)
        .order(
          'position',
          ascending: false,
        )
        .limit(1);

    if (response.isEmpty) {
      return 0;
    }

    return (response.first['position'] as int) + 1;
  }

  Future<void> removeSongFromPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    await _supabase
        .from('playlist_songs')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('song_id', songId);
  }

  Future<void> moveSongUp({
    required String playlistId,
    required String songId,
  }) async {
    await _supabase.rpc(
      'move_playlist_song',
      params: {
        'p_playlist_id': playlistId,
        'p_song_id': songId,

        // SEMENTARA DIBALIK UNTUK TEST
        'p_direction': 'down',
      },
    );
  }

  Future<void> moveSongDown({
    required String playlistId,
    required String songId,
  }) async {
    await _supabase.rpc(
      'move_playlist_song',
      params: {
        'p_playlist_id': playlistId,
        'p_song_id': songId,

        // SEMENTARA DIBALIK UNTUK TEST
        'p_direction': 'up',
      },
    );
  }

  Future<List<Map<String, dynamic>>>
      getPlaylistSongsWithDetails(
    String playlistId,
  ) async {
    final response = await _supabase
        .from('playlist_songs')
        .select(
          '''
          id,
          playlist_id,
          song_id,
          position,
          added_at,
          songs(
            id,
            title,
            artist,
            album_id,
            audio_url,
            cover_url,
            duration,
            bpm,
            energy,
            danceability,
            valence,
            subgenre,
            created_at,
            updated_at
          )
          ''',
        )
        .eq('playlist_id', playlistId)
        .order('position');

    return (response as List)
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }
}