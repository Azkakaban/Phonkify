import 'package:flutter/material.dart';

import '../../music/models/song.dart';
import '../services/progressive_recommendation_service.dart';

class ProgressiveRecommendationTestPage
    extends StatefulWidget {
  const ProgressiveRecommendationTestPage({
    super.key,
  });

  @override
  State<ProgressiveRecommendationTestPage>
      createState() =>
          _ProgressiveRecommendationTestPageState();
}

class _ProgressiveRecommendationTestPageState
    extends State<ProgressiveRecommendationTestPage> {
  final ProgressiveRecommendationService
      _recommendationService =
      ProgressiveRecommendationService.instance;

  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _testResults.clear();
    });

    try {
      final songs = _createTestSongs();

      final scores = <String, double>{
        'A': 0,
        'B': 0,
        'C': 0,
        'D': 0,
        'E': 0,
        'F': 0,
        'G': 0,
        'H': 0,
        'I': 0,
        'J': 0,
        'K': 8,
        'L': 6,
        'M': 10,
        'Z': 7,
      };

      var recommendations =
          songs.take(10).toList();

      _addResult(
        'Awal',
        recommendations,
      );

      recommendations =
          _recommendationService
              .updateRecommendations(
        currentRecommendations:
            recommendations,
        candidates: [
          songs.firstWhere(
            (song) => song.id == 'K',
          ),
        ],
        scores: scores,
      );

      _addResult(
        'Setelah K (+8)',
        recommendations,
      );

      recommendations =
          _recommendationService
              .updateRecommendations(
        currentRecommendations:
            recommendations,
        candidates: [
          songs.firstWhere(
            (song) => song.id == 'L',
          ),
        ],
        scores: scores,
      );

      _addResult(
        'Setelah L (+6)',
        recommendations,
      );

      recommendations =
          _recommendationService
              .updateRecommendations(
        currentRecommendations:
            recommendations,
        candidates: [
          songs.firstWhere(
            (song) => song.id == 'M',
          ),
        ],
        scores: scores,
      );

      _addResult(
        'Setelah M (+10)',
        recommendations,
      );

      recommendations =
          _recommendationService
              .updateRecommendations(
        currentRecommendations:
            recommendations,
        candidates: [
          songs.firstWhere(
            (song) => song.id == 'Z',
          ),
        ],
        scores: scores,
      );

      _addResult(
        'Setelah Z (+7)',
        recommendations,
      );

      if (!mounted) return;

      setState(() {
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

  List<Song> _createTestSongs() {
    const ids = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'Z',
    ];

    return ids
        .map(
          (id) => Song(
            id: id,
            title: 'Song $id',
            artist: 'Test Artist',
            audioUrl: '',
            coverUrl: '',
            duration: 100,
          ),
        )
        .toList();
  }

  void _addResult(
    String label,
    List<Song> recommendations,
  ) {
    _testResults.add(
      '$label:\n'
      '${recommendations.map((song) => song.id).join(', ')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progressive Recommendation Test',
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

    return RefreshIndicator(
      onRefresh: _runTest,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _testResults.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _testResults[index],
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}