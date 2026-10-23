import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';

class SearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Song>> search(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('songs')
        .select()
        .or(
          'title.ilike.%$trimmedQuery%,artist.ilike.%$trimmedQuery%',
        )
        .order('title', ascending: true);

    return (response as List)
        .map((item) => Song.fromMap(item))
        .toList();
  }
}