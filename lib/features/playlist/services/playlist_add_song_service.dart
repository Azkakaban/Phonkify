import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistAddSongService {
  PlaylistAddSongService._();

  static final PlaylistAddSongService instance =
      PlaylistAddSongService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  String get _userId {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    return user.id;
  }

  Future<bool> isSongInPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    final response = await _supabase
        .from('playlist_songs')
        .select('id')
        .eq('playlist_id', playlistId)
        .eq('song_id', songId)
        .maybeSingle();

    return response != null;
  }

  Future<int> _getNextPosition(
    String playlistId,
  ) async {
    final response = await _supabase
        .from('playlist_songs')
        .select('position')
        .eq('playlist_id', playlistId)
        .order('position', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return 0;
    }

    return (response.first['position'] as int) + 1;
  }

  Future<void> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    final alreadyExists = await isSongInPlaylist(
      playlistId: playlistId,
      songId: songId,
    );

    if (alreadyExists) {
      throw Exception('Lagu sudah ada di playlist ini');
    }

    final position =
        await _getNextPosition(playlistId);

    await _supabase.from('playlist_songs').insert({
      'playlist_id': playlistId,
      'song_id': songId,
      'position': position,
    });
  }

  Future<List<Map<String, dynamic>>> getMyPlaylists() async {
    final response = await _supabase
        .from('playlists')
        .select('id, name')
        .eq('user_id', _userId)
        .order('created_at');

    return (response as List)
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }
}