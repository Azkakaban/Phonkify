import 'package:flutter/material.dart';

import '../../music/models/song.dart';
import '../../music/services/song_service.dart';
import '../services/song_similarity_service.dart';

class SimilarityTestPage extends StatefulWidget {
  const SimilarityTestPage({
    super.key,
  });

  @override
  State<SimilarityTestPage> createState() =>
      _SimilarityTestPageState();
}

class _SimilarityTestPageState
    extends State<SimilarityTestPage> {
  final SongService _songService =
      SongService();

  final SongSimilarityService
      _similarityService =
      SongSimilarityService.instance;

  List<Song> _songs = [];

  Song? _selectedSong;

  List<SimilarityResult> _results = [];

  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final songs =
          await _songService.getSongs();

      if (!mounted) return;

      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            error.toString();
      });
    }
  }

  void _calculateForSong(
    Song song,
  ) {
    final results =
        _similarityService
            .getSimilarityResults(
      seedSong: song,
      candidates: _songs,
    );

    setState(() {
      _selectedSong = song;
      _results = results;
    });
  }

  String _formatScore(
    double score,
  ) {
    return score.toStringAsFixed(3);
  }

  String _formatPercentage(
    double score,
  ) {
    return '${(score * 100).toStringAsFixed(1)}%';
  }

  Widget _buildFeatureRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSongFeatures(
    Song song,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildFeatureRow(
          'Subgenre',
          song.subgenre ?? '-',
        ),
        _buildFeatureRow(
          'BPM',
          song.bpm?.toString() ?? '-',
        ),
        _buildFeatureRow(
          'Energy',
          song.energy
                  ?.toStringAsFixed(3) ??
              '-',
        ),
        _buildFeatureRow(
          'Danceability',
          song.danceability
                  ?.toStringAsFixed(3) ??
              '-',
        ),
        _buildFeatureRow(
          'Valence',
          song.valence
                  ?.toStringAsFixed(3) ??
              '-',
        ),
      ],
    );
  }

  Widget _buildSeedCard() {
    final song = _selectedSong;

    if (song == null) {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(16),
          child: Text(
            'Pilih lagu untuk melihat '
            'similarity.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'SEED SONG',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(song.artist),
            const SizedBox(height: 12),
            _buildSongFeatures(song),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required int position,
    required SimilarityResult result,
  }) {
    final score = result.score;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    '$position',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.song.title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        result.song.artist,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatScore(score),
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatPercentage(
                        score,
                      ),
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSongFeatures(
              result.song,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongSelector() {
    if (_songs.isEmpty) {
      return const Text(
        'Belum ada lagu.',
      );
    }

    return DropdownButtonFormField<Song>(
      initialValue: _selectedSong,
      isExpanded: true,
      decoration:
          const InputDecoration(
        labelText: 'Pilih Seed Song',
        border:
            OutlineInputBorder(),
      ),
      items: _songs.map((song) {
        return DropdownMenuItem<Song>(
          value: song,
          child: Text(
            '${song.title} — ${song.artist}',
            overflow:
                TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (song) {
        if (song == null) return;
        _calculateForSong(song);
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Similarity Test',
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      child: Text(
                        'Gagal memuat lagu:\n'
                        '$_errorMessage',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadSongs,
                    child: ListView(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      children: [
                        const Text(
                          'Similarity Test',
                          style:
                              TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        const Text(
                          'Pilih satu lagu sebagai '
                          'seed. Semua lagu lain '
                          'akan dihitung similarity '
                          'dan diurutkan dari nilai '
                          'tertinggi.',
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        _buildSongSelector(),
                        const SizedBox(
                          height: 16,
                        ),
                        _buildSeedCard(),
                        const SizedBox(
                          height: 20,
                        ),
                        if (_results.isNotEmpty)
                          Text(
                            'HASIL SIMILARITY '
                            '(${_results.length} lagu)',
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        const SizedBox(
                          height: 10,
                        ),
                        ..._results.asMap().entries.map(
                          (entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                bottom: 10,
                              ),
                              child:
                                  _buildResultCard(
                                position:
                                    entry.key + 1,
                                result:
                                    entry.value,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}