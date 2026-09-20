import '../../music/models/song.dart';
import 'ai_recommendation_service.dart';

class RecommendationPlaybackService {
  RecommendationPlaybackService._();

  static final RecommendationPlaybackService instance =
      RecommendationPlaybackService._();

  final AiRecommendationService
      _aiRecommendationService =
      AiRecommendationService.instance;

  Future<void> processPlaybackEvent({
    required Song song,
  }) async {
    try {
      await _aiRecommendationService
          .updateWithCandidates(
        candidates: [
          song,
        ],
      );
    } catch (_) {
      // Recommendation error tidak boleh
      // menghentikan playback.
    }
  }
}