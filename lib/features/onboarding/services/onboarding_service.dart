import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';

class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance =
      OnboardingService._();

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

  Future<bool> hasCompletedOnboarding() async {
    final response =
        await _supabase
            .from('user_preferences')
            .select('song_id')
            .eq(
              'user_id',
              _userId,
            )
            .limit(5);

    return (response as List).length >= 5;
  }

  Future<List<Song>> getSongsForOnboarding() async {
    final response =
        await _supabase
            .from('songs')
            .select()
            .order(
              'created_at',
              ascending: true,
            );

    return (response as List)
        .map(
          (item) => Song.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  Future<Set<String>> getSelectedSongIds() async {
    final response =
        await _supabase
            .from('user_preferences')
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

  Future<void> savePreferences(
    List<String> songIds,
  ) async {
    if (songIds.length < 5) {
      throw Exception(
        'Pilih minimal 5 lagu.',
      );
    }

    final uniqueSongIds =
        songIds.toSet().toList();

    if (uniqueSongIds.length < 5) {
      throw Exception(
        'Pilih minimal 5 lagu.',
      );
    }

    final existing =
        await _supabase
            .from('user_preferences')
            .select('song_id')
            .eq(
              'user_id',
              _userId,
            );

    final existingIds =
        (existing as List)
            .map(
              (item) =>
                  item['song_id'] as String,
            )
            .toSet();

    final newSongIds =
        uniqueSongIds
            .where(
              (songId) =>
                  !existingIds.contains(
                songId,
              ),
            )
            .toList();

    if (newSongIds.isEmpty) {
      return;
    }

    await _supabase
        .from('user_preferences')
        .insert(
      newSongIds
          .map(
            (songId) => {
              'user_id': _userId,
              'song_id': songId,
            },
          )
          .toList(),
    );
  }
}