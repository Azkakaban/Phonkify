import 'package:flutter/material.dart';

import '../../music/models/song.dart';
import '../../music/services/song_service.dart';
import '../services/explicit_preference_service.dart';

class ExplicitPreferenceTestPage extends StatefulWidget {
  const ExplicitPreferenceTestPage({
    super.key,
  });

  @override
  State<ExplicitPreferenceTestPage> createState() =>
      _ExplicitPreferenceTestPageState();
}

class _ExplicitPreferenceTestPageState
    extends State<ExplicitPreferenceTestPage> {
  final ExplicitPreferenceService
      _explicitPreferenceService =
      ExplicitPreferenceService.instance;

  final SongService _songService =
      SongService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Song> _songs = [];
  Set<String> _favoriteSongIds = {};
  Set<String> _playlistSongIds = {};
  Map<String, double> _scores = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _songService.getSongs(),
        _explicitPreferenceService
            .getFavoriteSongIds(),
        _explicitPreferenceService
            .getPlaylistSongIds(),
        _explicitPreferenceService
            .calculateExplicitPreferenceScores(),
      ]);

      if (!mounted) return;

      setState(() {
        _songs = results[0] as List<Song>;
        _favoriteSongIds =
            results[1] as Set<String>;
        _playlistSongIds =
            results[2] as Set<String>;
        _scores =
            results[3] as Map<String, double>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explicit Preference Test',
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

    if (_songs.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada lagu.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];

          final isFavorite =
              _favoriteSongIds.contains(
            song.id,
          );

          final isInPlaylist =
              _playlistSongIds.contains(
            song.id,
          );

          final score =
              _scores[song.id] ?? 0;

          return Card(
            margin: const EdgeInsets.only(
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
                    song.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(song.artist),
                  const SizedBox(height: 12),
                  Text(
                    'Favorite: '
                    '${isFavorite ? "YA" : "TIDAK"}',
                  ),
                  Text(
                    'Playlist: '
                    '${isInPlaylist ? "YA" : "TIDAK"}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explicit Preference Score: '
                    '${score.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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