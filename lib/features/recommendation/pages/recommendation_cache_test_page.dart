import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';
import '../services/recommendation_cache_service.dart';

class RecommendationCacheTestPage extends StatefulWidget {
  const RecommendationCacheTestPage({
    super.key,
  });

  @override
  State<RecommendationCacheTestPage> createState() =>
      _RecommendationCacheTestPageState();
}

class _RecommendationCacheTestPageState
    extends State<RecommendationCacheTestPage> {
  final RecommendationCacheService
      _cacheService =
      RecommendationCacheService.instance;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  List<CachedRecommendation> _recommendations = [];

  bool _loading = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<List<Song>> _getSongsForTesting() async {
    final response = await _supabase
        .from('songs')
        .select()
        .order(
          'created_at',
          ascending: true,
        )
        .limit(10);

    return (response as List)
        .map(
          (item) => Song.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> _saveTestRecommendations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final songs =
          await _getSongsForTesting();

      if (songs.isEmpty) {
        throw Exception(
          'Tidak ada lagu yang tersedia untuk test.',
        );
      }

      final scores =
          <String, double>{};

      for (var index = 0;
          index < songs.length;
          index++) {
        scores[songs[index].id] =
            (10 - index).toDouble();
      }

      await _cacheService
          .saveRecommendations(
        songs: songs,
        scores: scores,
        source: 'COLD_START',
      );

      await _loadRecommendations();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final recommendations =
          await _cacheService
              .getRecommendations();

      if (!mounted) return;

      setState(() {
        _recommendations =
            recommendations;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _clearRecommendations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _cacheService
          .clearRecommendations();

      await _loadRecommendations();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recommendation Cache Test',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading
                        ? null
                        : _saveTestRecommendations,
                    icon: const Icon(
                      Icons.save,
                    ),
                    label: const Text(
                      'Save Test',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : _loadRecommendations,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'Load',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : _clearRecommendations,
                icon: const Icon(
                  Icons.delete_outline,
                ),
                label: const Text(
                  'Clear Cache',
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_loading)
              const Padding(
                padding:
                    EdgeInsets.only(bottom: 16),
                child:
                    CircularProgressIndicator(),
              ),

            if (_error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(12),
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer,
                ),
                child: Text(
                  _error!,
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: _recommendations.isEmpty
                  ? const Center(
                      child: Text(
                        'Recommendation cache kosong.',
                        textAlign:
                            TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          _recommendations.length,
                      itemBuilder:
                          (context, index) {
                        final item =
                            _recommendations[
                                index];

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                '${item.position + 1}',
                              ),
                            ),
                            title: Text(
                              item.song.title,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                            subtitle: Text(
                              '${item.song.artist}\n'
                              'Score: ${item.recommendationScore}\n'
                              'Source: ${item.source}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}