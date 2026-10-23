import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';
import '../../recommendation/services/user_music_profile_service.dart';

class ListeningHistoryService {
  ListeningHistoryService._();

  static final ListeningHistoryService instance =
      ListeningHistoryService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  String get _userId {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    return user.id;
  }

  Future<String> startListening({
    required String songId,
  }) async {
    final response = await _supabase
        .from('listening_history')
        .insert({
          'user_id': _userId,
          'song_id': songId,
          'started_at':
              DateTime.now().toUtc().toIso8601String(),
          'duration_played': 0,
          'completed': false,
          'skipped': false,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<void> finishListening({
    required String historyId,
    required int durationPlayed,
    required bool completed,
    required bool skipped,
  }) async {
    await _supabase
        .from('listening_history')
        .update({
          'duration_played': durationPlayed,
          'completed': completed,
          'skipped': skipped,
        })
        .eq('id', historyId)
        .eq('user_id', _userId);

    try {
      await UserMusicProfileService.instance
          .updateProfile();
    } catch (_) {
      // Gagal memperbarui profil musik
      // tidak boleh menghentikan playback.
    }
  }

  Future<List<Song>> getRecentlyPlayed({
    int limit = 10,
  }) async {
    if (limit <= 0) {
      return [];
    }

    final response = await _supabase
        .from('listening_history')
        .select('''
          song_id,
          started_at,
          songs(*)
        ''')
        .eq('user_id', _userId)
        .order(
          'started_at',
          ascending: false,
        )
        .limit(100);

    final seenSongIds = <String>{};
    final songs = <Song>[];

    for (final item in response as List) {
      final map =
          Map<String, dynamic>.from(item);

      final songData = map['songs'];

      if (songData is! Map) {
        continue;
      }

      final songMap =
          Map<String, dynamic>.from(
        songData,
      );

      final songId =
          songMap['id'] as String?;

      if (songId == null ||
          seenSongIds.contains(songId)) {
        continue;
      }

      seenSongIds.add(songId);

      try {
        songs.add(
          Song.fromMap(songMap),
        );
      } catch (_) {
        // Abaikan record yang tidak valid.
      }

      if (songs.length >= limit) {
        break;
      }
    }

    return songs;
  }
}