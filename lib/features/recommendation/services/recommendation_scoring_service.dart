import 'behavioral_scoring_service.dart';
import 'explicit_preference_service.dart';

class RecommendationScoringService {
  RecommendationScoringService._();

  static final RecommendationScoringService instance =
      RecommendationScoringService._();

  final BehavioralScoringService
      _behavioralScoringService =
      BehavioralScoringService.instance;

  final ExplicitPreferenceService
      _explicitPreferenceService =
      ExplicitPreferenceService.instance;

  Future<Map<String, double>>
      calculateRecommendationScores() async {
    final results = await Future.wait([
      _behavioralScoringService
          .calculateSongBehaviorScores(),
      _explicitPreferenceService
          .calculateExplicitPreferenceScores(),
    ]);

    final behavioralScores = results[0];

    final explicitScores = results[1];

    final songIds = <String>{
      ...behavioralScores.keys,
      ...explicitScores.keys,
    };

    final recommendationScores =
        <String, double>{};

    for (final songId in songIds) {
      final behavioralScore =
          behavioralScores[songId] ?? 0;

      final explicitScore =
          explicitScores[songId] ?? 0;

      final recommendationScore =
          behavioralScore + explicitScore;

      recommendationScores[songId] =
          recommendationScore;
    }

    return recommendationScores;
  }
}