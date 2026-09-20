import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';

class ColdStartRecommendation {
  final Song song;
  final double score;

  const ColdStartRecommendation({
    required this.song,
    required this.score,
  });
}

class RecommendationService {
  RecommendationService._();

  static final RecommendationService instance =
      RecommendationService._();

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

  Future<List<Song>> getColdStartRecommendations({
    int limit = 10,
  }) async {
    final recommendations =
        await getColdStartRecommendationsWithScores(
      limit: limit,
    );

    return recommendations
        .map(
          (item) => item.song,
        )
        .toList();
  }

  Future<List<ColdStartRecommendation>>
      getColdStartRecommendationsWithScores({
    int limit = 10,
  }) async {
    if (limit <= 0) {
      return [];
    }

    final results = await Future.wait([
      _getPreferredSongs(),
      _getAllSongs(),
    ]);

    final preferredSongs = results[0];
    final allSongs = results[1];

    if (preferredSongs.isEmpty ||
        allSongs.isEmpty) {
      return [];
    }

    final scoredSongs =
        <_ScoredSong>[];

    for (final candidate in allSongs) {
      final score =
          _calculateRecommendationScore(
        candidate: candidate,
        preferredSongs: preferredSongs,
      );

      scoredSongs.add(
        _ScoredSong(
          song: candidate,
          score: score,
        ),
      );
    }

    scoredSongs.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return scoredSongs
        .take(limit)
        .map(
          (item) => ColdStartRecommendation(
            song: item.song,
            score: item.score,
          ),
        )
        .toList();
  }

  Future<List<Song>> _getPreferredSongs() async {
    final response = await _supabase
        .from('user_preferences')
        .select('''
          song_id,
          songs(*)
        ''')
        .eq(
          'user_id',
          _userId,
        );

    final songs = <Song>[];

    for (final item in response as List) {
      final map =
          Map<String, dynamic>.from(item);

      final songData = map['songs'];

      if (songData is! Map) continue;

      try {
        final songMap =
            Map<String, dynamic>.from(
          songData,
        );

        songs.add(
          Song.fromMap(songMap),
        );
      } catch (_) {}
    }

    return songs;
  }

  Future<List<Song>> _getAllSongs() async {
    final response = await _supabase
        .from('songs')
        .select()
        .order(
          'created_at',
          ascending: true,
        );

    return (response as List)
        .map(
          (item) => Song.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  double _calculateRecommendationScore({
    required Song candidate,
    required List<Song> preferredSongs,
  }) {
    if (preferredSongs.isEmpty) {
      return 0;
    }

    final scores = preferredSongs
        .map(
          (preferredSong) =>
              _calculateSongSimilarity(
            candidate: candidate,
            preferredSong: preferredSong,
          ),
        )
        .toList();

    if (scores.isEmpty) {
      return 0;
    }

    scores.sort(
      (a, b) => b.compareTo(a),
    );

    final topCount =
        min(3, scores.length);

    final topScores =
        scores.take(topCount);

    return topScores.reduce(
          (a, b) => a + b,
        ) /
        topCount;
  }

  double _calculateSongSimilarity({
    required Song candidate,
    required Song preferredSong,
  }) {
    double totalScore = 0;
    double totalWeight = 0;

    if (candidate.subgenre != null &&
        preferredSong.subgenre != null) {
      final candidateSubgenre =
          candidate.subgenre!
              .trim()
              .toLowerCase();

      final preferredSubgenre =
          preferredSong.subgenre!
              .trim()
              .toLowerCase();

      final score =
          candidateSubgenre ==
                  preferredSubgenre
              ? 1.0
              : 0.0;

      totalScore +=
          score * 0.35;

      totalWeight += 0.35;
    }

    if (candidate.bpm != null &&
        preferredSong.bpm != null) {
      final score =
          _numericSimilarity(
        candidate.bpm!,
        preferredSong.bpm!,
        maxDifference: 80,
      );

      totalScore +=
          score * 0.15;

      totalWeight += 0.15;
    }

    if (candidate.energy != null &&
        preferredSong.energy != null) {
      final score =
          _numericSimilarity(
        candidate.energy!,
        preferredSong.energy!,
        maxDifference: 1,
      );

      totalScore +=
          score * 0.20;

      totalWeight += 0.20;
    }

    if (candidate.danceability != null &&
        preferredSong.danceability != null) {
      final score =
          _numericSimilarity(
        candidate.danceability!,
        preferredSong.danceability!,
        maxDifference: 1,
      );

      totalScore +=
          score * 0.15;

      totalWeight += 0.15;
    }

    if (candidate.valence != null &&
        preferredSong.valence != null) {
      final score =
          _numericSimilarity(
        candidate.valence!,
        preferredSong.valence!,
        maxDifference: 1,
      );

      totalScore +=
          score * 0.10;

      totalWeight += 0.10;
    }

    if (candidate.artist.trim().isNotEmpty &&
        preferredSong.artist.trim().isNotEmpty) {
      final score =
          candidate.artist
                      .trim()
                      .toLowerCase() ==
                  preferredSong.artist
                      .trim()
                      .toLowerCase()
              ? 1.0
              : 0.0;

      totalScore +=
          score * 0.05;

      totalWeight += 0.05;
    }

    if (totalWeight == 0) {
      return 0;
    }

    return totalScore /
        totalWeight;
  }

  double _numericSimilarity(
    double first,
    double second, {
    required double maxDifference,
  }) {
    final difference =
        (first - second).abs();

    final normalizedDifference =
        difference /
            maxDifference;

    return (1 -
            normalizedDifference)
        .clamp(0.0, 1.0);
  }
}

class _ScoredSong {
  final Song song;
  final double score;

  const _ScoredSong({
    required this.song,
    required this.score,
  });
}