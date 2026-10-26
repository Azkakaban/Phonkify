import 'package:flutter/material.dart';

import '../services/recommendation_cache_service.dart';
import '../services/recommendation_playback_service.dart';

class RecommendationPlaybackTestPage
    extends StatefulWidget {
  const RecommendationPlaybackTestPage({
    super.key,
  });

  @override
  State<RecommendationPlaybackTestPage>
      createState() =>
          _RecommendationPlaybackTestPageState();
}

class _RecommendationPlaybackTestPageState
    extends State<RecommendationPlaybackTestPage> {
  final RecommendationCacheService
      _cacheService =
      RecommendationCacheService.instance;

  final RecommendationPlaybackService
      _playbackService =
      RecommendationPlaybackService.instance;

  List<CachedRecommendation> _recommendations =
      [];

  bool _loading = true;
  bool _processing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _loading = true;
        _message = null;
      });

      final recommendations =
          await _cacheService
              .getRecommendations();

      if (!mounted) return;

      setState(() {
        _recommendations =
            recommendations;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _message =
            'Gagal membaca recommendation cache: $error';
      });
    }
  }

  Future<void> _processPlaybackEvent(
    CachedRecommendation recommendation,
  ) async {
    if (_processing) return;

    try {
      setState(() {
        _processing = true;
        _message =
            'Memproses playback event...';
      });

      await _playbackService
          .processPlaybackEvent(
        song: recommendation.song,
      );

      final updatedRecommendations =
          await _cacheService
              .getRecommendations();

      if (!mounted) return;

      setState(() {
        _recommendations =
            updatedRecommendations;
        _processing = false;
        _message =
            'Playback event berhasil diproses.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _processing = false;
        _message =
            'Gagal memproses playback event: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recommendation Playback Test',
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  _loadRecommendations,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Playback Event Test',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih lagu dari recommendation cache '
                    'untuk memproses playback event.',
                  ),
                  const SizedBox(height: 16),

                  if (_message != null) ...[
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),
                        child: Text(
                          _message!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_recommendations.isEmpty)
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(16),
                        child: Text(
                          'Recommendation cache kosong.',
                        ),
                      ),
                    ),

                  ..._recommendations.map(
                    (recommendation) {
                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              '${recommendation.position + 1}',
                            ),
                          ),
                          title: Text(
                            recommendation.song.title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${recommendation.song.artist}\n'
                            'Score: ${recommendation.recommendationScore}\n'
                            'Source: ${recommendation.source}',
                          ),
                          isThreeLine: true,
                          trailing:
                              _processing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.play_arrow,
                                      ),
                                      tooltip:
                                          'Process Playback Event',
                                      onPressed:
                                          () =>
                                              _processPlaybackEvent(
                                        recommendation,
                                      ),
                                    ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}