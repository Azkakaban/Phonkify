import 'package:flutter/material.dart';

import '../../music/models/song.dart';
import '../services/progressive_recommendation_service.dart';

class RecommendationRerankingTestPage
    extends StatelessWidget {
  RecommendationRerankingTestPage({
    super.key,
  });

  final ProgressiveRecommendationService
      _service =
      ProgressiveRecommendationService.instance;

  Song _song(String id) {
    return Song(
      id: id,
      title: id,
      artist: 'Test Artist',
      audioUrl: 'test/$id.mp3',
      coverUrl: null,
      duration: 180,
      albumId: null,
      bpm: null,
      energy: null,
      danceability: null,
      valence: null,
      subgenre: null,
      createdAt: null,
      updatedAt: null,
    );
  }

  String _formatSongs(
    List<Song> songs,
  ) {
    return songs
        .map((song) => song.id)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final tests = <Map<String, dynamic>>[];

    // TEST 1
    //
    // Existing B berubah menjadi score 10.
    // B harus naik ke posisi pertama.
    final result1 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
      ],
      candidates: [
        _song('B'),
      ],
      scores: {
        'A': 0,
        'B': 10,
        'C': 0,
        'D': 0,
      },
    );

    tests.add({
      'name': 'Test 1',
      'expected': 'B, A, C, D',
      'actual': _formatSongs(result1),
    });

    // TEST 2
    //
    // Existing C berubah menjadi score 8.
    // C harus naik ke posisi pertama.
    final result2 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
      ],
      candidates: [
        _song('C'),
      ],
      scores: {
        'A': 0,
        'B': -5,
        'C': 8,
        'D': 0,
      },
    );

    tests.add({
      'name': 'Test 2',
      'expected': 'C, A, D, B',
      'actual': _formatSongs(result2),
    });

    // TEST 3
    //
    // B dan C memiliki score sama.
    // B sudah lebih dulu berada di cache,
    // sehingga B harus tetap di depan C.
    final result3 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
      ],
      candidates: [
        _song('C'),
      ],
      scores: {
        'A': 0,
        'B': 5,
        'C': 5,
        'D': 0,
      },
    );

    tests.add({
      'name': 'Test 3 - Stable Tie',
      'expected': 'B, C, A, D',
      'actual': _formatSongs(result3),
    });

    // TEST 4
    //
    // Cache sudah penuh 10 lagu.
    // Existing J berubah menjadi score 10.
    // J harus naik ke posisi pertama,
    // bukan dianggap lagu baru.
    final result4 =
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
        _song('J'),
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
        'J': 10,
      },
    );

    tests.add({
      'name': 'Test 4 - Full Cache',
      'expected':
          'J, A, B, C, D, E, F, G, H, I',
      'actual': _formatSongs(result4),
    });

    // TEST 5
    //
    // Existing A mendapat score negatif.
    // A harus turun ke posisi paling belakang.
    final result5 =
        _service.updateRecommendations(
      currentRecommendations: [
        _song('A'),
        _song('B'),
        _song('C'),
        _song('D'),
      ],
      candidates: [
        _song('A'),
      ],
      scores: {
        'A': -5,
        'B': 2,
        'C': 1,
        'D': 0,
      },
    );

    tests.add({
      'name': 'Test 5 - Score Negative',
      'expected': 'B, C, D, A',
      'actual': _formatSongs(result5),
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recommendation Re-ranking Test',
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tests.length,
        itemBuilder: (
          context,
          index,
        ) {
          final test = tests[index];

          final expected =
              test['expected'] as String;

          final actual =
              test['actual'] as String;

          final passed =
              expected == actual;

          return Card(
            margin:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    test['name'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    'Expected: $expected',
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Actual: $actual',
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    passed
                        ? '✓ PASS'
                        : '✗ FAIL',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: passed
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}