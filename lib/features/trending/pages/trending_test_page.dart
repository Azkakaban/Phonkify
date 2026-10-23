import 'package:flutter/material.dart';

import '../services/trending_service.dart';

class TrendingTestPage extends StatefulWidget {
  const TrendingTestPage({
    super.key,
  });

  @override
  State<TrendingTestPage> createState() =>
      _TrendingTestPageState();
}

class _TrendingTestPageState
    extends State<TrendingTestPage> {
  final TrendingService _trendingService =
      TrendingService.instance;

  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _trendingSongs = [];

  bool _isLoadingSongs = true;
  bool _isLoadingTrending = true;

  @override
  void initState() {
    super.initState();

    _loadSongs();
    _loadTrendingSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final response =
          await _trendingService.getAllSongsForTesting();

      if (!mounted) return;

      setState(() {
        _songs = response;
        _isLoadingSongs = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingSongs = false;
      });

      _showMessage(
        'Gagal mengambil lagu: $error',
      );
    }
  }

  Future<void> _loadTrendingSongs() async {
    try {
      final response =
          await _trendingService.getTrendingSongs();

      if (!mounted) return;

      setState(() {
        _trendingSongs = response;
        _isLoadingTrending = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingTrending = false;
      });

      _showMessage(
        'Gagal mengambil Trending: $error',
      );
    }
  }

  Future<void> _addToTrending(
    String songId,
    String title,
  ) async {
    try {
      await _trendingService.addSongToTrending(
        songId: songId,
      );

      await _loadTrendingSongs();

      if (!mounted) return;

      _showMessage(
        '$title berhasil ditambahkan ke Trending',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Gagal menambahkan "$title": $error',
      );
    }
  }

  Future<void> _removeFromTrending(
    String songId,
    String title,
  ) async {
    try {
      await _trendingService.removeSongFromTrending(
        songId: songId,
      );

      await _loadTrendingSongs();

      if (!mounted) return;

      _showMessage(
        '$title dihapus dari Trending',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Gagal menghapus "$title": $error',
      );
    }
  }

  Future<void> _moveUp(
    String songId,
  ) async {
    try {
      await _trendingService.moveSongUp(
        songId: songId,
      );

      await _loadTrendingSongs();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Gagal menaikkan ranking: $error',
      );
    }
  }

  Future<void> _moveDown(
    String songId,
  ) async {
    try {
      await _trendingService.moveSongDown(
        songId: songId,
      );

      await _loadTrendingSongs();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Gagal menurunkan ranking: $error',
      );
    }
  }

  bool _isTrending(String songId) {
    return _trendingSongs.any(
      (item) => item['song_id'] == songId,
    );
  }

  int? _getTrendingPosition(
    String songId,
  ) {
    for (final item in _trendingSongs) {
      if (item['song_id'] == songId) {
        return item['position'] as int?;
      }
    }

    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Test'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadSongs();
          await _loadTrendingSongs();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Current Trending',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (_isLoadingTrending)
              const Center(
                child:
                    CircularProgressIndicator(),
              )
            else if (_trendingSongs.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Belum ada lagu di Trending.',
                  ),
                ),
              )
            else
              ..._trendingSongs.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final item = entry.value;

                  final song =
                      item['songs']
                          as Map<String, dynamic>?;

                  final title =
                      song?['title'] as String? ??
                          'Unknown';

                  final artist =
                      song?['artist'] as String? ??
                          'Unknown';

                  final position =
                      item['position'] as int? ??
                          index;

                  final songId =
                      item['song_id'] as String;

                  final isFirst = index == 0;
                  final isLast =
                      index ==
                          _trendingSongs.length - 1;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          '${position + 1}',
                        ),
                      ),
                      title: Text(title),
                      subtitle: Text(artist),
                      trailing: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip:
                                'Naikkan ranking',
                            onPressed: isFirst
                                ? null
                                : () {
                                    _moveUp(
                                      songId,
                                    );
                                  },
                            icon: const Icon(
                              Icons
                                  .keyboard_arrow_up,
                            ),
                          ),
                          IconButton(
                            tooltip:
                                'Turunkan ranking',
                            onPressed: isLast
                                ? null
                                : () {
                                    _moveDown(
                                      songId,
                                    );
                                  },
                            icon: const Icon(
                              Icons
                                  .keyboard_arrow_down,
                            ),
                          ),
                          IconButton(
                            tooltip:
                                'Hapus dari Trending',
                            icon: const Icon(
                              Icons.delete_outline,
                            ),
                            onPressed: () {
                              _removeFromTrending(
                                songId,
                                title,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            const Text(
              'Semua Lagu',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (_isLoadingSongs)
              const Center(
                child:
                    CircularProgressIndicator(),
              )
            else if (_songs.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Belum ada lagu.',
                  ),
                ),
              )
            else
              ..._songs.map(
                (song) {
                  final songId =
                      song['id'] as String;

                  final title =
                      song['title'] as String? ??
                          'Unknown';

                  final artist =
                      song['artist'] as String? ??
                          'Unknown';

                  final isTrending =
                      _isTrending(songId);

                  final position =
                      _getTrendingPosition(
                    songId,
                  );

                  return Card(
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text(artist),
                      trailing: isTrending
                          ? Chip(
                              label: Text(
                                'Trending #${(position ?? 0) + 1}',
                              ),
                            )
                          : IconButton(
                              tooltip:
                                  'Tambah ke Trending',
                              icon: const Icon(
                                Icons.add,
                              ),
                              onPressed: () {
                                _addToTrending(
                                  songId,
                                  title,
                                );
                              },
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