import 'package:flutter/material.dart';

import '../../favorites/services/favorite_service.dart';
import '../../music/models/song.dart';
import '../services/audio_player_service.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.onTap,
  });

  @override
  State<MiniPlayer> createState() =>
      _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioPlayerService _audioPlayerService =
      AudioPlayerService.instance;

  final FavoriteService _favoriteService =
      FavoriteService.instance;

  Song? _song;

  String? _coverUrl;

  bool _isFavorite = false;

  bool _isFavoriteLoading = false;

  @override
  void initState() {
    super.initState();

    _song = _audioPlayerService.currentSong;

    if (_song != null) {
      _loadSongData(_song!);
    }

    _audioPlayerService.currentSongStream.listen(
      _onCurrentSongChanged,
    );

    _favoriteService.changes.listen(
      _onFavoriteChanged,
    );
  }

  Future<void> _loadSongData(
    Song song,
  ) async {
    await Future.wait([
      _loadCoverUrl(song),
      _loadFavoriteStatus(song),
    ]);
  }

  Future<void> _loadCoverUrl(
    Song song,
  ) async {
    if (song.coverUrl == null ||
        song.coverUrl!.isEmpty) {
      if (!mounted) return;

      setState(() {
        _coverUrl = null;
      });

      return;
    }

    try {
      final coverPath =
          song.coverUrl!.startsWith('covers/')
              ? song.coverUrl!
                  .substring('covers/'.length)
              : song.coverUrl!;

      final coverUrl =
          await _audioPlayerService
              .getSignedCoverUrl(coverPath);

      if (!mounted) return;

      if (_song?.id != song.id) return;

      setState(() {
        _coverUrl = coverUrl;
      });
    } catch (_) {
      if (!mounted) return;

      if (_song?.id != song.id) return;

      setState(() {
        _coverUrl = null;
      });
    }
  }

  Future<void> _loadFavoriteStatus(
    Song song,
  ) async {
    try {
      final isFavorite =
          await _favoriteService.isFavorite(
        song.id,
      );

      if (!mounted) return;

      if (_song?.id != song.id) return;

      setState(() {
        _isFavorite = isFavorite;
      });
    } catch (_) {
      if (!mounted) return;

      if (_song?.id != song.id) return;

      setState(() {
        _isFavorite = false;
      });
    }
  }

  Future<void> _onCurrentSongChanged(
    Song? song,
  ) async {
    if (!mounted) return;

    if (song == null) {
      setState(() {
        _song = null;
        _coverUrl = null;
        _isFavorite = false;
      });

      return;
    }

    setState(() {
      _song = song;
      _coverUrl = null;
      _isFavorite = false;
    });

    await _loadSongData(song);
  }

  void _onFavoriteChanged(FavoriteChange change) {
    if (!mounted || _song?.id != change.songId) {
      return;
    }

    setState(() {
      _isFavorite = change.isFavorite;
    });
  }

  Future<void> _togglePlayPause() async {
    if (_song == null) return;

    try {
      if (_audioPlayerService.player.playing) {
        await _audioPlayerService.pause();
      } else {
        await _audioPlayerService.playSong(
          _song!,
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memutar lagu: $error',
          ),
        ),
      );
    }
  }

  Future<void> _playNext() async {
    try {
      await _audioPlayerService.playNext();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memutar lagu berikutnya: $error',
          ),
        ),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final song = _song;

    if (song == null || _isFavoriteLoading) {
      return;
    }

    final previousValue = _isFavorite;

    setState(() {
      _isFavoriteLoading = true;
      _isFavorite = !previousValue;
    });

    try {
      await _favoriteService.toggleFavorite(
        song.id,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFavorite = previousValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengubah favorite: $error',
          ),
        ),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isFavoriteLoading = false;
    });
  }

  Future<void> _seekTo(
    double value,
  ) async {
    final duration =
        _audioPlayerService.player.duration;

    if (duration == null ||
        duration.inMilliseconds <= 0) {
      return;
    }

    final position =
        Duration(milliseconds: value.round());

    await _audioPlayerService.seek(position);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_song == null) {
      return const SizedBox.shrink();
    }

    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color: const Color(0xFF202027),
      child: StreamBuilder<Duration>(
        stream:
            _audioPlayerService.positionStream,
        initialData: Duration.zero,
        builder: (
          context,
          positionSnapshot,
        ) {
          return StreamBuilder<Duration?>(
            stream:
                _audioPlayerService.durationStream,
            initialData:
                _audioPlayerService.player.duration,
            builder: (
              context,
              durationSnapshot,
            ) {
              final position =
                  positionSnapshot.data ??
                      Duration.zero;

              final duration =
                  durationSnapshot.data ??
                      Duration.zero;

              final maxMilliseconds =
                  duration.inMilliseconds > 0
                      ? duration.inMilliseconds
                      : 1;

              final positionMilliseconds =
                  position.inMilliseconds.clamp(
                0,
                maxMilliseconds,
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 60,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(6),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: _coverUrl == null
                                  ? const ColoredBox(
                                      color: Colors.black26,
                                      child: Icon(
                                        Icons.music_note,
                                        size: 26,
                                      ),
                                    )
                                  : Image.network(
                                      _coverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const ColoredBox(
                                          color: Colors.black26,
                                          child: Icon(
                                            Icons.music_note,
                                            size: 26,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: InkWell(
                              onTap: widget.onTap,
                              borderRadius:
                                  BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _song!.title,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _song!.artist,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          IconButton(
                            tooltip: _isFavorite
                                ? 'Hapus dari Favorite'
                                : 'Tambah ke Favorite',
                            onPressed:
                                _isFavoriteLoading
                                    ? null
                                    : _toggleFavorite,
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? colorScheme.primary
                                  : null,
                            ),
                          ),

                          StreamBuilder<bool>(
                            stream:
                                _audioPlayerService
                                    .playingStream,
                            initialData: false,
                            builder: (
                              context,
                              snapshot,
                            ) {
                              final isPlaying =
                                  snapshot.data ?? false;

                              return IconButton(
                                tooltip: isPlaying
                                    ? 'Pause'
                                    : 'Putar',
                                onPressed:
                                    _togglePlayPause,
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                              );
                            },
                          ),

                          IconButton(
                            tooltip: 'Lagu Berikutnya',
                            onPressed: _playNext,
                            icon: const Icon(
                              Icons.skip_next,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 8,
                    child: SliderTheme(
                      data:
                          SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        overlayShape:
                            const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        trackShape:
                            const RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        padding: EdgeInsets.zero,
                        value:
                            positionMilliseconds.toDouble(),
                        min: 0,
                        max:
                            maxMilliseconds.toDouble(),
                        onChanged:
                            duration.inMilliseconds <= 0
                                ? null
                                : _seekTo,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}