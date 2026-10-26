import 'package:supabase_flutter/supabase_flutter.dart';

class ExplicitPreferenceService {
  ExplicitPreferenceService._();

  static final ExplicitPreferenceService instance =
      ExplicitPreferenceService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  String get _userId {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'User belum login',
      );
    }

    return user.id;
  }

  Future<Set<String>> getFavoriteSongIds() async {
    final response = await _supabase
        .from('favorites')
        .select('song_id')
        .eq(
          'user_id',
          _userId,
        );

    return (response as List)
        .map(
          (item) =>
              item['song_id'] as String,
        )
        .toSet();
  }

  Future<Set<String>> getPlaylistSongIds() async {
    final response = await _supabase
        .from('playlist_songs')
        .select('''
          song_id,
          playlists!inner(
            user_id
          )
        ''')
        .eq(
          'playlists.user_id',
          _userId,
        );

    return (response as List)
        .map(
          (item) =>
              item['song_id'] as String,
        )
        .toSet();
  }

  Future<Map<String, double>>
      calculateExplicitPreferenceScores() async {
    final results = await Future.wait([
      getFavoriteSongIds(),
      getPlaylistSongIds(),
    ]);

    final favoriteSongIds =
        results[0];

    final playlistSongIds =
        results[1];

    final scores =
        <String, double>{};

    for (final songId in favoriteSongIds) {
      scores[songId] =
          (scores[songId] ?? 0) + 5;
    }

    for (final songId in playlistSongIds) {
      scores[songId] =
          (scores[songId] ?? 0) + 4;
    }

    return scores;
  }
}