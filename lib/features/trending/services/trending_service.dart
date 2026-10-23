import 'package:supabase_flutter/supabase_flutter.dart';

class TrendingService {
  TrendingService._();

  static final TrendingService instance =
      TrendingService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<Map<String, dynamic>>>
      getTrendingSongs() async {
    final response = await _supabase
        .from('trending_songs')
        .select('''
          id,
          song_id,
          position,
          created_at,
          songs(*)
        ''')
        .order('position');

    return (response as List)
        .map(
          (item) => Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      getAllSongsForTesting() async {
    final response = await _supabase
        .from('songs')
        .select('id, title, artist')
        .order('title');

    return (response as List)
        .map(
          (item) => Map<String, dynamic>.from(
            item,
          ),
        )
        .toList();
  }

  Future<bool> isSongTrending(
    String songId,
  ) async {
    final response = await _supabase
        .from('trending_songs')
        .select('id')
        .eq('song_id', songId)
        .maybeSingle();

    return response != null;
  }

  Future<int> _getNextPosition() async {
    final response = await _supabase
        .from('trending_songs')
        .select('position')
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

  Future<void> addSongToTrending({
    required String songId,
  }) async {
    final alreadyExists =
        await isSongTrending(songId);

    if (alreadyExists) {
      throw Exception(
        'Lagu sudah ada di Trending',
      );
    }

    final position =
        await _getNextPosition();

    await _supabase
        .from('trending_songs')
        .insert({
      'song_id': songId,
      'position': position,
    });
  }

  Future<void> removeSongFromTrending({
    required String songId,
  }) async {
    await _supabase.rpc(
      'remove_trending_song',
      params: {
        'p_song_id': songId,
      },
    );
  }

  Future<void> moveSongUp({
    required String songId,
  }) async {
    await _supabase.rpc(
      'move_trending_song',
      params: {
        'p_song_id': songId,
        'p_direction': 'down',
      },
    );
  }

  Future<void> moveSongDown({
    required String songId,
  }) async {
    await _supabase.rpc(
      'move_trending_song',
      params: {
        'p_song_id': songId,
        'p_direction': 'up',
      },
    );
  }
}