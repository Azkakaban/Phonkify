import 'package:flutter/material.dart';

import '../services/behavioral_scoring_service.dart';
import '../services/listening_behavior_service.dart';

class BehavioralScoringTestPage extends StatefulWidget {
  const BehavioralScoringTestPage({
    super.key,
  });

  @override
  State<BehavioralScoringTestPage> createState() =>
      _BehavioralScoringTestPageState();
}

class _BehavioralScoringTestPageState
    extends State<BehavioralScoringTestPage> {
  final BehavioralScoringService
      _scoringService =
      BehavioralScoringService.instance;

  final ListeningBehaviorService
      _listeningBehaviorService =
      ListeningBehaviorService.instance;

  bool _isLoading = true;
  String? _errorMessage;

  List<ListeningBehavior> _behaviors = [];
  Map<String, double> _scores = {};

  @override
  void initState() {
    super.initState();
    _loadScoring();
  }

  Future<void> _loadScoring() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _listeningBehaviorService
            .getListeningBehaviors(),
        _scoringService
            .calculateSongBehaviorScores(),
      ]);

      if (!mounted) return;

      setState(() {
        _behaviors =
            results[0] as List<ListeningBehavior>;
        _scores =
            results[1] as Map<String, double>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  List<ListeningBehavior> _getSongBehaviors(
    String songId,
  ) {
    return _behaviors
        .where(
          (behavior) =>
              behavior.song.id == songId,
        )
        .toList();
  }

  String _formatDateTime(
    DateTime dateTime,
  ) {
    final local = dateTime.toLocal();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${local.day}/'
        '${local.month}/'
        '${local.year} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}:'
        '${twoDigits(local.second)}';
  }

  double _calculateHistoryScore(
    ListeningBehavior behavior,
  ) {
    double score = 0;

    final duration =
        behavior.song.duration;

    final played =
        behavior.durationPlayed;

    if (behavior.completed) {
      score += 5;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Behavioral Scoring Test',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_behaviors.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada listening history.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final songIds = _scores.keys.toList();

    return RefreshIndicator(
      onRefresh: _loadScoring,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: songIds.length,
        itemBuilder: (context, index) {
          final songId = songIds[index];

          final songBehaviors =
              _getSongBehaviors(songId);

          if (songBehaviors.isEmpty) {
            return const SizedBox.shrink();
          }

          final latestBehavior =
              songBehaviors.first;

          final score =
              _scores[songId] ?? 0;

          final historyCount =
              songBehaviors.length;

          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            child: ExpansionTile(
              title: Text(
                latestBehavior.song.title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${latestBehavior.song.artist}\n'
                'Total Behavioral Score: '
                '${score.toStringAsFixed(2)}\n'
                'Jumlah Playback: $historyCount',
              ),
              childrenPadding:
                  const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16,
              ),
              children: [
                const Divider(),

                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'History Playback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                ...songBehaviors
                    .asMap()
                    .entries
                    .map(
                  (entry) {
                    final historyIndex =
                        entry.key;

                    final behavior =
                        entry.value;

                    final historyScore =
                        _calculateHistoryScore(
                      behavior,
                    );

                    return Container(
                      width: double.infinity,
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      padding:
                          const EdgeInsets.all(
                        12,
                      ),
                      decoration:
                          BoxDecoration(
                        border: Border.all(
                          color: Theme.of(
                            context,
                          )
                              .dividerColor,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Playback '
                            '#${historyCount - historyIndex}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            'Started At: '
                            '${_formatDateTime(
                              behavior.startedAt,
                            )}',
                          ),
                          Text(
                            'Duration Played: '
                            '${behavior.durationPlayed} detik',
                          ),
                          Text(
                            'Completed: '
                            '${behavior.completed}',
                          ),
                          Text(
                            'Skipped: '
                            '${behavior.skipped}',
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            'History Score: '
                            '${historyScore.toStringAsFixed(2)}',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),

                Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Total Score = '
                    '${score.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}