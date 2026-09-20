import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';

class CachedRecommendation {
  final String id;
  final String userId;
  final String songId;
  final int position;
  final double recommendationScore;
  final String source;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Song song;

  const CachedRecommendation({
    required this.id,
    required this.userId,
    required this.songId,
    required this.position,
    required this.recommendationScore,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.song,
  });

  factory CachedRecommendation.fromMap(
    Map<String, dynamic> map,
  ) {
    final songData = map['songs'];

    if (songData is! Map) {
      throw Exception(
        'Data song tidak ditemukan pada recommendation cache.',
      );
    }

    return CachedRecommendation(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      songId: map['song_id'] as String,
      position: (map['position'] as num).toInt(),
      recommendationScore:
          (map['recommendation_score'] as num).toDouble(),
      source: map['source'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(
              map['created_at'] as String,
            )
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(
              map['updated_at'] as String,
            )
          : null,
      song: Song.fromMap(
        Map<String, dynamic>.from(songData),
      ),
    );
  }
}

class RecommendationCacheService {
  RecommendationCacheService._();

  static final RecommendationCacheService instance =
      RecommendationCacheService._();

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

  Future<void> saveRecommendations({
    required List<Song> songs,
    required Map<String, double> scores,
    String source = 'COLD_START',
  }) async {
    _userId;

    if (songs.isEmpty) {
      return;
    }

    final limitedSongs =
        songs.take(10).toList();

    final items =
        <Map<String, dynamic>>[];

    for (var index = 0;
        index < limitedSongs.length;
        index++) {
      final song =
          limitedSongs[index];

      items.add({
        'song_id': song.id,
        'position': index,
        'recommendation_score':
            scores[song.id] ?? 0,
        'source': source,
      });
    }

    await _supabase.rpc(
      'save_recommendation_cache',
      params: {
        'p_items': items,
      },
    );
  }

  Future<void> saveColdStartRecommendations({
    required List<Song> songs,
    required Map<String, double> scores,
  }) async {
    await saveRecommendations(
      songs: songs,
      scores: scores,
      source: 'COLD_START',
    );
  }

  Future<List<CachedRecommendation>>
      getRecommendations() async {
    final response = await _supabase
        .from('recommendation_cache')
        .select('''
          id,
          user_id,
          song_id,
          position,
          recommendation_score,
          source,
          created_at,
          updated_at,
          songs(*)
        ''')
        .eq(
          'user_id',
          _userId,
        )
        .order(
          'position',
          ascending: true,
        );

    return (response as List)
        .map(
          (item) =>
              CachedRecommendation.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> clearRecommendations() async {
    _userId;

    await _supabase.rpc(
      'clear_recommendation_cache',
    );
  }
}