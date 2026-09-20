import '../../music/models/song.dart';
import 'progressive_recommendation_service.dart';
import 'recommendation_cache_service.dart';
import 'recommendation_scoring_service.dart';

class AiRecommendationService {
  AiRecommendationService._();

  static final AiRecommendationService instance =
      AiRecommendationService._();

  final RecommendationCacheService
      _cacheService =
      RecommendationCacheService.instance;

  final RecommendationScoringService
      _scoringService =
      RecommendationScoringService.instance;

  final ProgressiveRecommendationService
      _progressiveService =
      ProgressiveRecommendationService.instance;

  Future<List<CachedRecommendation>>
      getCurrentRecommendations() async {
    return _cacheService
        .getRecommendations();
  }

  Future<List<CachedRecommendation>>
      updateWithCandidates({
    required List<Song> candidates,
  }) async {
    final currentCache =
        await _cacheService
            .getRecommendations();

    final scores =
        await _scoringService
            .calculateRecommendationScores();

    final currentSongs =
        currentCache
            .map(
              (item) => item.song,
            )
            .toList();

    final updatedSongs =
        _progressiveService
            .updateRecommendations(
      currentRecommendations:
          currentSongs,
      candidates: candidates,
      scores: scores,
    );

    if (updatedSongs.isEmpty) {
      return currentCache;
    }

    final cacheScores =
        <String, double>{};

    for (final song
        in updatedSongs) {
      cacheScores[song.id] =
          scores[song.id] ?? 0;
    }

    await _cacheService
        .saveRecommendations(
      songs: updatedSongs,
      scores: cacheScores,
      source: 'BEHAVIORAL',
    );

    return _cacheService
        .getRecommendations();
  }
}