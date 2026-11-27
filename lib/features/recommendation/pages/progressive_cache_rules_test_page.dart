import 'package:flutter/material.dart';

import '../../music/models/song.dart';
import '../services/progressive_recommendation_service.dart';

class ProgressiveCacheRulesTestPage
    extends StatefulWidget {
  const ProgressiveCacheRulesTestPage({
    super.key,
  });

  @override
  State<ProgressiveCacheRulesTestPage>
      createState() =>
          _ProgressiveCacheRulesTestPageState();
}

class _ProgressiveCacheRulesTestPageState
    extends State<
        ProgressiveCacheRulesTestPage> {
  final ProgressiveRecommendationService
      _service =
      ProgressiveRecommendationService
          .instance;

  final List<String> _results = [];

  Song _song(String id) {
    return Song(
      id: id,
      title: 'Song $id',
      artist: 'Test Artist',
      audioUrl: '',
      coverUrl: null,
      duration: 100,
      albumId: null,
      createdAt: null,
      updatedAt: null,
      bpm: null,
      energy: null,
      danceability: null,
      valence: null,
      subgenre: null,
    );
  }

  String _formatResult(List<Song> songs) {
    return songs
        .map(
          (song) => song.id,
        )
        .join(', ');
  }

  void _runTests() {
    final results = <String>[];

    // =========================================================
    // Test 1
    // Cache penuh 10 lagu.
    // Kandidat K score +8 harus menggusur
    // lagu dengan score terendah.
    // =========================================================

    final result1 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
        _song('E'),
        _song('F'),
        _song('G'),
        _song('H'),
        _song('I'),
        _song('J'),
      ],
      candidates: [
        _song('K'),
      ],
      scores: {
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
      },
    );

    final expected1 =
        'K, A, B, C, D, E, F, G, H, I';

    results.add(
      'Test 1: ${_formatResult(result1)} '
      '${_formatResult(result1) == expected1 ? '✓' : '✗'}',
    );

    // =========================================================
    // Test 2
    // Dari cache awal, L score +6.
    // L harus masuk setelah K dan sebelum
    // lagu-lagu score 0.
    // =========================================================

    final result2 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('K'),
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
        _song('E'),
        _song('F'),
        _song('G'),
        _song('H'),
        _song('I'),
      ],
      candidates: [
        _song('L'),
      ],
      scores: {
        'K': 8,
        'A': 0,
        'B': 0,
        'C': 0,
        'D': 0,
        'E': 0,
        'F': 0,
        'G': 0,
        'H': 0,
        'I': 0,
        'L': 6,
      },
    );

    final expected2 =
        'K, L, A, B, C, D, E, F, G, H';

    results.add(
      'Test 2: ${_formatResult(result2)} '
      '${_formatResult(result2) == expected2 ? '✓' : '✗'}',
    );

    // =========================================================
    // Test 3
    // Kandidat M score +10.
    // M harus menjadi posisi pertama.
    // =========================================================

    final result3 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('K'),
        _song('L'),
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
        _song('E'),
        _song('F'),
        _song('G'),
        _song('H'),
      ],
      candidates: [
        _song('M'),
      ],
      scores: {
        'K': 8,
        'L': 6,
        'A': 0,
        'B': 0,
        'C': 0,
        'D': 0,
        'E': 0,
        'F': 0,
        'G': 0,
        'H': 0,
        'M': 10,
      },
    );

    final expected3 =
        'M, K, L, A, B, C, D, E, F, G';

    results.add(
      'Test 3: ${_formatResult(result3)} '
      '${_formatResult(result3) == expected3 ? '✓' : '✗'}',
    );

    // =========================================================
    // Test 4
    // Kandidat Z score +7.
    // Z harus masuk setelah K (+8)
    // dan sebelum L (+6).
    // =========================================================

    final result4 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('M'),
        _song('K'),
        _song('L'),
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
        _song('E'),
        _song('F'),
        _song('G'),
      ],
      candidates: [
        _song('Z'),
      ],
      scores: {
        'M': 10,
        'K': 8,
        'L': 6,
        'A': 0,
        'B': 0,
        'C': 0,
        'D': 0,
        'E': 0,
        'F': 0,
        'G': 0,
        'Z': 7,
      },
    );

    final expected4 =
        'M, K, Z, L, A, B, C, D, E, F';

    results.add(
      'Test 4: ${_formatResult(result4)} '
      '${_formatResult(result4) == expected4 ? '✓' : '✗'}',
    );

    // =========================================================
    // Test 5
    // Cache penuh.
    // Kandidat score 0 tidak boleh masuk
    // karena score terendah juga 0.
    // =========================================================

    final result5 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
        _song('E'),
        _song('F'),
        _song('G'),
        _song('H'),
        _song('I'),
        _song('J'),
      ],
      candidates: [
        _song('Z'),
      ],
      scores: {
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
        'Z': 0,
      },
    );

    final expected5 =
        'A, B, C, D, E, F, G, H, I, J';

    results.add(
      'Test 5: ${_formatResult(result5)} '
      '${_formatResult(result5) == expected5 ? '✓' : '✗'}',
    );

    // =========================================================
    // Test 6
    // Cache penuh.
    // Kandidat score negatif tidak boleh masuk.
    // =========================================================

    final result6 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
        _song('E'),
        _song('F'),
        _song('G'),
        _song('H'),
        _song('I'),
        _song('J'),
      ],
      candidates: [
        _song('Z'),
      ],
      scores: {
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
        'Z': -5,
      },
    );

    final expected6 =
        'A, B, C, D, E, F, G, H, I, J';

    results.add(
      'Test 6: ${_formatResult(result6)} '
      '${_formatResult(result6) == expected6 ? '✓' : '✗'}',
    );

    setState(() {
      _results
        ..clear()
        ..addAll(results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progressive Cache Rules Test',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _runTests,
                child: const Text(
                  'Run Tests',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text(
                        'Tekan Run Tests.',
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          _results.length,
                      itemBuilder:
                          (context, index) {
                        return Card(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(16),
                            child: Text(
                              _results[index],
                              style:
                                  const TextStyle(
                                fontSize: 16,
                              ),
                            ),
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