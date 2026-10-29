import '../../music/models/song.dart';

class SongSimilarityService {
  SongSimilarityService._();

  static final SongSimilarityService instance =
      SongSimilarityService._();

  List<Song> getSimilarSongs({
    required Song seedSong,
    required List<Song> candidates,
    int limit = 10,
  }) {
    if (limit <= 0) {
      return [seedSong];
    }

    final scoredSongs = <SimilarityResult>[];

    for (final candidate in candidates) {
      if (candidate.id == seedSong.id) {
        continue;
      }

      final score = calculateSimilarity(
        seedSong: seedSong,
        candidate: candidate,
      );

      scoredSongs.add(
        SimilarityResult(
          song: candidate,
          score: score,
        ),
      );
    }

    scoredSongs.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    final similarSongs = scoredSongs
        .take(limit)
        .map((item) => item.song)
        .toList();

    return [
      seedSong,
      ...similarSongs,
    ];
  }

  List<SimilarityResult> getSimilarityResults({
    required Song seedSong,
    required List<Song> candidates,
  }) {
    final results = <SimilarityResult>[];

    for (final candidate in candidates) {
      if (candidate.id == seedSong.id) {
        continue;
      }

      final score = calculateSimilarity(
        seedSong: seedSong,
        candidate: candidate,
      );

      results.add(
        SimilarityResult(
          song: candidate,
          score: score,
        ),
      );
    }

    results.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return results;
  }

  double calculateSimilarity({
    required Song seedSong,
    required Song candidate,
  }) {
    double totalScore = 0;
    double totalWeight = 0;

    if (seedSong.subgenre != null &&
        candidate.subgenre != null) {
      final seedSubgenre =
          seedSong.subgenre!.trim().toLowerCase();

      final candidateSubgenre =
          candidate.subgenre!.trim().toLowerCase();

      final score =
          seedSubgenre == candidateSubgenre
              ? 1.0
              : 0.0;

      totalScore += score * 0.35;
      totalWeight += 0.35;
    }

    if (seedSong.bpm != null &&
        candidate.bpm != null) {
      final score = _numericSimilarity(
        seedSong.bpm!,
        candidate.bpm!,
        maxDifference: 80,
      );

      totalScore += score * 0.20;
      totalWeight += 0.20;
    }

    if (seedSong.energy != null &&
        candidate.energy != null) {
      final score = _numericSimilarity(
        seedSong.energy!,
        candidate.energy!,
        maxDifference: 1,
      );

      totalScore += score * 0.20;
      totalWeight += 0.20;
    }

    if (seedSong.danceability != null &&
        candidate.danceability != null) {
      final score = _numericSimilarity(
        seedSong.danceability!,
        candidate.danceability!,
        maxDifference: 1,
      );

      totalScore += score * 0.15;
      totalWeight += 0.15;
    }

    if (seedSong.valence != null &&
        candidate.valence != null) {
      final score = _numericSimilarity(
        seedSong.valence!,
        candidate.valence!,
        maxDifference: 1,
      );

      totalScore += score * 0.10;
      totalWeight += 0.10;
    }

    if (totalWeight == 0) {
      return 0;
    }

    return totalScore / totalWeight;
  }

  double _numericSimilarity(
    double first,
    double second, {
    required double maxDifference,
  }) {
    final difference =
        (first - second).abs();

    final normalizedDifference =
        difference / maxDifference;

    return (1 - normalizedDifference)
        .clamp(0.0, 1.0);
  }
}

class SimilarityResult {
  final Song song;
  final double score;

  const SimilarityResult({
    required this.song,
    required this.score,
  });
}