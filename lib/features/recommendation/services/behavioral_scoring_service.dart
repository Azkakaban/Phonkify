import 'listening_behavior_service.dart';

class BehavioralScoringService {
  BehavioralScoringService._();

  static final BehavioralScoringService instance =
      BehavioralScoringService._();

  final ListeningBehaviorService
      _listeningBehaviorService =
      ListeningBehaviorService.instance;

  Future<Map<String, double>>
      calculateSongBehaviorScores() async {
    final behaviors =
        await _listeningBehaviorService
            .getListeningBehaviors();

    final scores =
        <String, double>{};

    for (final behavior in behaviors) {
      final songId = behavior.song.id;

      final score =
          _calculateBehaviorScore(
        behavior,
      );

      scores[songId] =
          (scores[songId] ?? 0) + score;
    }

    return scores;
  }

  double _calculateBehaviorScore(
    ListeningBehavior behavior,
  ) {
    double score = 0;

    final duration =
        behavior.song.duration;

    final played =
        behavior.durationPlayed;

    if (behavior.completed) {
      // Lagu yang selesai didengarkan
      // mendapatkan reward completion.
      score += 3;

      // Lagu completed dianggap telah
      // melewati 50% durasi.
      score += 2;
    } else if (duration > 0) {
      final playRatio =
          played / duration;

      if (playRatio >= 0.5) {
        score += 2;
      } else if (playRatio < 0.2) {
        score -= 1;
      }
    }

    if (behavior.skipped) {
      score -= 3;
    }

    return score;
  }
}