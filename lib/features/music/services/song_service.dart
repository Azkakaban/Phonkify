import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/song.dart';

class SongService {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<Song>> getSongs() async {
    final response = await _supabase
        .from('songs')
        .select()
        .order(
          'created_at',
          ascending: false,
        );

    return (response as List)
        .map(
          (item) => Song.fromMap(item),
        )
        .toList();
  }

  Future<Song?> getSongById(
    String id,
  ) async {
    final response = await _supabase
        .from('songs')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Song.fromMap(response);
  }

  Future<List<Song>> searchSongs(
    String query,
  ) async {
    final trimmedQuery =
        query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('songs')
        .select()
        .or(
          'title.ilike.%$trimmedQuery%,'
          'artist.ilike.%$trimmedQuery%',
        )
        .order(
          'title',
          ascending: true,
        );

    return (response as List)
        .map(
          (item) => Song.fromMap(item),
        )
        .toList();
  }

  Future<Song> createSong({
    required String title,
    required String artist,
    String? albumId,
    required String audioUrl,
    String? coverUrl,
    required int duration,
    double? bpm,
    double? energy,
    double? danceability,
    double? valence,
    String? subgenre,
  }) async {
    final response = await _supabase
        .from('songs')
        .insert({
          'title': title.trim(),
          'artist': artist.trim(),
          'album_id': albumId,
          'audio_url': audioUrl.trim(),
          'cover_url': coverUrl?.trim(),
          'duration': duration,
          'bpm': bpm,
          'energy': energy,
          'danceability': danceability,
          'valence': valence,
          'subgenre': subgenre?.trim(),
        })
        .select()
        .single();

    return Song.fromMap(response);
  }

  Future<Song> updateSong({
    required String id,
    required String title,
    required String artist,
    String? albumId,
    required String audioUrl,
    String? coverUrl,
    required int duration,
    double? bpm,
    double? energy,
    double? danceability,
    double? valence,
    String? subgenre,
  }) async {
    final response = await _supabase
        .from('songs')
        .update({
          'title': title.trim(),
          'artist': artist.trim(),
          'album_id': albumId,
          'audio_url': audioUrl.trim(),
          'cover_url': coverUrl?.trim(),
          'duration': duration,
          'bpm': bpm,
          'energy': energy,
          'danceability': danceability,
          'valence': valence,
          'subgenre': subgenre?.trim(),
        })
        .eq('id', id)
        .select()
        .single();

    return Song.fromMap(response);
  }

  Future<void> deleteSong(
    String id,
  ) async {
    await _supabase
        .from('songs')
        .delete()
        .eq('id', id);
  }
}