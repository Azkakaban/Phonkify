import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/playlist.dart';

class PlaylistService {
  PlaylistService._();

  static final PlaylistService instance =
      PlaylistService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  String get _userId {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    return user.id;
  }

  Future<List<Playlist>> getMyPlaylists() async {
    final response = await _supabase
        .from('playlists')
        .select(
          'id, user_id, name, created_at, updated_at',
        )
        .eq('user_id', _userId)
        .order('created_at');

    return (response as List)
        .map(
          (item) => Playlist.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<Playlist> createPlaylist(
    String name,
  ) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Nama playlist tidak boleh kosong');
    }

    final response = await _supabase
        .from('playlists')
        .insert({
          'user_id': _userId,
          'name': trimmedName,
        })
        .select()
        .single();

    return Playlist.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<void> renamePlaylist(
    String playlistId,
    String name,
  ) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Nama playlist tidak boleh kosong');
    }

    await _supabase
        .from('playlists')
        .update({
          'name': trimmedName,
        })
        .eq('id', playlistId)
        .eq('user_id', _userId);
  }

  Future<void> deletePlaylist(
    String playlistId,
  ) async {
    await _supabase
        .from('playlists')
        .delete()
        .eq('id', playlistId)
        .eq('user_id', _userId);
  }
}