import 'package:flutter/material.dart';

import '../../music/models/song.dart';
import '../../player/pages/full_player_page.dart';
import '../../player/services/audio_player_service.dart';
import '../../player/services/playback_queue.dart';
import '../services/favorite_service.dart';

class FavoriteSongsPage
    extends StatefulWidget {
  const FavoriteSongsPage({
    super.key,
  });

  @override
  State<FavoriteSongsPage> createState() =>
      _FavoriteSongsPageState();
}

class _FavoriteSongsPageState
    extends State<FavoriteSongsPage> {
  final FavoriteService
      _favoriteService =
      FavoriteService.instance;

  final AudioPlayerService
      _audioPlayerService =
      AudioPlayerService.instance;

  final PlaybackQueue
      _playbackQueue =
      PlaybackQueue.instance;

  List<Song> _songs = [];

  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final songs =
          await _favoriteService
              .getFavoriteSongs();

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

  Future<void> _playSong(
    Song song,
  ) async {
    final index =
        _songs.indexWhere(
      (item) => item.id == song.id,
    );

    if (index < 0) {
      return;
    }

    _playbackQueue.setQueue(
      songs: _songs,
      startIndex: index,
      context: PlaybackContext.catalog,
    );

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FullPlayerPage(
          song: song,
        ),
      ),
    );

    try {
      await _audioPlayerService
          .playSong(song);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memutar lagu: $error',
          ),
        ),
      );
    }
  }

  Future<void> _removeFavorite(
    Song song,
  ) async {
    try {
      await _favoriteService
          .toggleFavorite(
        song.id,
      );

      if (!mounted) return;

      setState(() {
        _songs.removeWhere(
          (item) => item.id == song.id,
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${song.title} dihapus dari Favorite',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus Favorite: $error',
          ),
        ),
      );
    }
  }

  Future<String?> _getCoverUrl(
    String? coverPath,
  ) async {
    if (coverPath == null ||
        coverPath.isEmpty) {
      return null;
    }

    try {
      return await _audioPlayerService
          .getSignedCoverUrl(
        coverPath,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'Gagal memuat Favorite',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              FilledButton(
                onPressed:
                    _loadFavorites,
                child: const Text(
                  'Coba Lagi',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 72,
                color:
                    Theme.of(context)
                        .colorScheme
                        .primary,
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                'Belum ada Favorite',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              const Text(
                'Lagu yang kamu sukai '
                'akan muncul di sini.',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _songs.length,
        separatorBuilder:
            (context, index) =>
                const SizedBox(
          height: 8,
        ),
        itemBuilder:
            (context, index) {
          final song =
              _songs[index];

          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: FutureBuilder<String?>(
                future: _getCoverUrl(
                  song.coverUrl,
                ),
                builder:
                    (context, snapshot) {
                  final url =
                      snapshot.data;

                  if (url == null) {
                    return Container(
                      width: 52,
                      height: 52,
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      child: const Icon(
                        Icons.music_note,
                      ),
                    );
                  }

                  return ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    child: Image.network(
                      url,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          width: 52,
                          height: 52,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .surfaceContainerHighest,
                          child:
                              const Icon(
                            Icons.music_note,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
              ),
              trailing:
                  PopupMenuButton<String>(
                onSelected:
                    (value) {
                  if (value ==
                      'play') {
                    _playSong(song);
                  }

                  if (value ==
                      'remove') {
                    _removeFavorite(
                      song,
                    );
                  }
                },
                itemBuilder:
                    (context) => const [
                  PopupMenuItem(
                    value: 'play',
                    child: Text(
                      'Putar',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      'Hapus dari Favorite',
                    ),
                  ),
                ],
              ),
              onTap: () {
                _playSong(song);
              },
            ),
          );
        },
      ),
    );
  }
}