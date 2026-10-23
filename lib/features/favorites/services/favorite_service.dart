import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';

class FavoriteChange {
  final String songId;
  final bool isFavorite;

  const FavoriteChange({
    required this.songId,
    required this.isFavorite,
  });
}

class FavoriteService {
  FavoriteService._();

  static final FavoriteService instance =
      FavoriteService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final StreamController<FavoriteChange> _changesController =
      StreamController<FavoriteChange>.broadcast();

  Stream<FavoriteChange> get changes =>
      _changesController.stream;

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

  Future<bool> isFavorite(
    String songId,
  ) async {
    final response =
        await _supabase
            .from('favorites')
            .select('id')
            .eq('user_id', _userId)
            .eq('song_id', songId)
            .maybeSingle();

    return response != null;
  }

  Future<void> toggleFavorite(
    String songId,
  ) async {
    final existing =
        await _supabase
            .from('favorites')
            .select('id')
            .eq('user_id', _userId)
            .eq('song_id', songId)
            .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('favorites')
          .delete()
          .eq(
            'id',
            existing['id'],
          )
          .eq(
            'user_id',
            _userId,
          );

      _changesController.add(
        FavoriteChange(
          songId: songId,
          isFavorite: false,
        ),
      );

      return;
    }

    await _supabase
        .from('favorites')
        .insert({
      'user_id': _userId,
      'song_id': songId,
    });

    _changesController.add(
      FavoriteChange(
        songId: songId,
        isFavorite: true,
      ),
    );
  }

  Future<List<Song>> getFavoriteSongs() async {
    final response =
        await _supabase
            .from('favorites')
            .select('''
              id,
              song_id,
              created_at,
              songs(*)
            ''')
            .eq(
              'user_id',
              _userId,
            )
            .order(
              'created_at',
              ascending: false,
            );

    final songs = <Song>[];

    for (final item
        in response as List) {
      final map =
          Map<String, dynamic>.from(
        item,
      );

      final songData =
          map['songs'];

      if (songData is! Map) {
        continue;
      }

      try {
        final songMap =
            Map<String, dynamic>.from(
          songData,
        );

        songs.add(
          Song.fromMap(songMap),
        );
      } catch (_) {
        // Abaikan data lagu yang tidak valid.
      }
    }

    return songs;
  }
}