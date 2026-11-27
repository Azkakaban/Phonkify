import 'package:flutter/material.dart';

import '../../music/models/song.dart';
import '../../music/services/song_service.dart';
import '../services/behavioral_scoring_service.dart';
import '../services/explicit_preference_service.dart';
import '../services/recommendation_scoring_service.dart';

class RecommendationScoringTestPage extends StatefulWidget {
  const RecommendationScoringTestPage({
    super.key,
  });

  @override
  State<RecommendationScoringTestPage> createState() =>
      _RecommendationScoringTestPageState();
}

class _RecommendationScoringTestPageState
    extends State<RecommendationScoringTestPage> {
  final SongService _songService = SongService();

  final BehavioralScoringService _behavioralService =
      BehavioralScoringService.instance;

  final ExplicitPreferenceService _explicitService =
      ExplicitPreferenceService.instance;

  final RecommendationScoringService _recommendationService =
      RecommendationScoringService.instance;

  List<Song> _songs = [];

  Map<String, double> _behavioralScores = {};

  Map<String, double> _explicitScores = {};

  Map<String, double> _finalScores = {};

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _songService.getSongs(),
        _behavioralService.calculateSongBehaviorScores(),
        _explicitService.calculateExplicitPreferenceScores(),
        _recommendationService.calculateRecommendationScores(),
      ]);

      if (!mounted) return;

      setState(() {
        _songs = results[0] as List<Song>;
        _behavioralScores =
            results[1] as Map<String, double>;
        _explicitScores =
            results[2] as Map<String, double>;
        _finalScores =
            results[3] as Map<String, double>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  double _getBehavioralScore(String songId) {
    return _behavioralScores[songId] ?? 0;
  }

  double _getExplicitScore(String songId) {
    return _explicitScores[songId] ?? 0;
  }

  double _getFinalScore(String songId) {
    return _finalScores[songId] ?? 0;
  }

  String _formatScore(double score) {
    return score.toStringAsFixed(2);
  }

  Widget _buildScoreRow({
    required String label,
    required double score,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Text(
            _formatScore(score),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongCard(Song song) {
    final behavioralScore =
        _getBehavioralScore(song.id);

    final explicitScore =
        _getExplicitScore(song.id);

    final finalScore =
        _getFinalScore(song.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              song.title,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              song.artist,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            _buildScoreRow(
              label: 'Behavioral Score',
              score: behavioralScore,
            ),
            _buildScoreRow(
              label: 'Explicit Preference',
              score: explicitScore,
            ),
            const SizedBox(height: 6),
            const Divider(),
            const SizedBox(height: 6),
            _buildScoreRow(
              label: 'FINAL RECOMMENDATION SCORE',
              score: finalScore,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recommendation Scoring Test',
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(24),
                      child: Text(
                        'Gagal menghitung score:\n$_error',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadScores,
                    child: ListView(
                      padding:
                          const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Recommendation Scoring',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Halaman ini menampilkan '
                          'Behavioral Score, Explicit '
                          'Preference Score, dan hasil '
                          'penggabungan keduanya.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Final Score = Behavioral Score '
                          '+ Explicit Preference Score',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  OutlinedButton.icon(
                                onPressed: _loading
                                    ? null
                                    : _loadScores,
                                icon: const Icon(
                                  Icons.refresh,
                                ),
                                label: const Text(
                                  'Refresh Score',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_songs.isEmpty)
                          const Center(
                            child: Padding(
                              padding:
                                  EdgeInsets.all(24),
                              child: Text(
                                'Belum ada lagu.',
                              ),
                            ),
                          )
                        else
                          ..._songs.map(
                            _buildSongCard,
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}