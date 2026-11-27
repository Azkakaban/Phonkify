import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../favorites/services/favorite_service.dart';
import '../../music/models/song.dart';
import '../../playlist/services/playlist_add_song_service.dart';
import '../../profile/services/profile_service.dart';
import '../../trending/services/trending_service.dart';
import '../services/audio_player_service.dart';
import '../services/playback_queue.dart' as playback_queue;

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _MarqueeText({
    super.key,
    required this.text,
    this.style,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  final ScrollController _scrollController = ScrollController();
  Timer? _restartTimer;
  bool _shouldScroll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartMarquee();
    });
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _stopMarquee();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndStartMarquee();
      });
    }
  }

  void _checkAndStartMarquee() {
    if (!mounted || !_scrollController.hasClients) return;

    final shouldScroll =
        _scrollController.position.maxScrollExtent > 0;

    if (_shouldScroll != shouldScroll) {
      setState(() {
        _shouldScroll = shouldScroll;
      });
    }

    if (shouldScroll) {
      _startMarquee();
    }
  }

  void _startMarquee() {
    _restartTimer?.cancel();

    if (!mounted || !_shouldScroll || !_scrollController.hasClients) {
      return;
    }

    _restartTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted || !_shouldScroll || !_scrollController.hasClients) {
        return;
      }

      final maxExtent = _scrollController.position.maxScrollExtent;

      while (mounted && _shouldScroll && _scrollController.hasClients) {
        final current = _scrollController.offset;

        if (current >= maxExtent) {
          await Future<void>.delayed(const Duration(milliseconds: 700));

          if (!mounted || !_shouldScroll || !_scrollController.hasClients) {
            return;
          }

          await _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );

          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }

        final remaining = maxExtent - current;
        final durationMs = (remaining * 45).round().clamp(1000, 12000);

        await _scrollController.animateTo(
          maxExtent,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );
      }
    });
  }

  void _stopMarquee() {
    _restartTimer?.cancel();
    _restartTimer = null;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    if (_shouldScroll && mounted) {
      setState(() {
        _shouldScroll = false;
      });
    }
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: widget.style?.fontSize != null
              ? (widget.style!.fontSize! * 1.3)
              : 24,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              style: widget.style,
            ),
          ),
        );
      },
    );
  }
}

class _SpeedChoiceButton extends StatelessWidget {
  final double value;
  final bool selected;
  final VoidCallback onPressed;

  const _SpeedChoiceButton({
    required this.value,
    this.selected = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            '${value.toStringAsFixed(value == value.roundToDouble() ? 1 : 2)}x',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class FullPlayerPage extends StatefulWidget {
  final Song song;

  const FullPlayerPage({
    super.key,
    required this.song,
  });

  @override
  State<FullPlayerPage> createState() =>
      _FullPlayerPageState();
}

class _FullPlayerPageState
    extends State<FullPlayerPage> {
  final AudioPlayerService _audioPlayerService =
      AudioPlayerService.instance;

  final playback_queue.PlaybackQueue _playbackQueue =
      playback_queue.PlaybackQueue.instance;

  final ProfileService _profileService =
      ProfileService();

  final TrendingService _trendingService =
      TrendingService.instance;

  Song? _currentSong;

  String? _coverUrl;

  bool _isFavorite = false;
  bool _isFavoriteLoading = true;
  bool _isAddingToPlaylist = false;

  bool _isAdmin = false;
  bool _isTrending = false;
  bool _isTrendingLoading = true;
  bool _isTrendingActionLoading = false;

  double _nextUpExtent = 44.0;

  double get _nextUpMinExtent => 44.0;

  bool get _shuffleEnabled =>
      _playbackQueue.shuffleEnabled;

  playback_queue.RepeatMode get _repeatMode =>
      _playbackQueue.repeatMode;

  @override
  void initState() {
    super.initState();

    _currentSong =
        _audioPlayerService.currentSong ??
        widget.song;

    _loadCoverUrl(_currentSong!);
    _loadFavoriteStatus();
    _loadAdminStatus();
    _loadTrendingStatus();

    _audioPlayerService.currentSongStream.listen(
      _onCurrentSongChanged,
    );

    FavoriteService.instance.changes.listen(
      _onFavoriteChanged,
    );
  }

  void _onFavoriteChanged(FavoriteChange change) {
    if (!mounted || _currentSong?.id != change.songId) {
      return;
    }

    setState(() {
      _isFavorite = change.isFavorite;
      _isFavoriteLoading = false;
    });
  }

  Future<void> _onCurrentSongChanged(
    Song? song,
  ) async {
    if (song == null || !mounted) return;

    setState(() {
      _currentSong = song;
      _coverUrl = null;

      _isFavorite = false;
      _isFavoriteLoading = true;

      _isTrending = false;
      _isTrendingLoading = true;
    });

    await _loadCoverUrl(song);
    await _loadFavoriteStatus();
    await _loadTrendingStatus();
  }

  Future<void> _loadCoverUrl(
    Song song,
  ) async {
    final coverPath = song.coverUrl;

    if (coverPath == null ||
        coverPath.isEmpty) {
      return;
    }

    try {
      final url =
          await _audioPlayerService
              .getSignedCoverUrl(coverPath);

      if (!mounted) return;

      setState(() {
        _coverUrl = url;
      });
    } catch (_) {
      // Placeholder digunakan jika cover gagal.
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final song = _currentSong;

      if (song == null) return;

      final isFavorite =
          await FavoriteService.instance.isFavorite(
        song.id,
      );

      if (!mounted) return;

      setState(() {
        _isFavorite = isFavorite;
        _isFavoriteLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isFavoriteLoading = false;
      });
    }
  }

  Future<void> _loadAdminStatus() async {
    try {
      final profile =
          await _profileService.getCurrentProfile();

      if (!mounted) return;

      final isAdmin =
          profile?['role'] == 'ADMIN';

      setState(() {
        _isAdmin = isAdmin;
        if (!isAdmin) {
          _isTrendingLoading = false;
        }
      });

      // _loadTrendingStatus() sebelumnya dipanggil bersamaan dengan
      // _loadAdminStatus() di initState(). Akibatnya, pada saat method
      // tersebut berjalan _isAdmin masih false sehingga status Trending
      // langsung return dan tidak pernah dimuat. Ini terutama terlihat
      // ketika Full Player dibuka kembali dari Mini Player.
      if (isAdmin) {
        await _loadTrendingStatus();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isAdmin = false;
        _isTrendingLoading = false;
      });
    }
  }

  Future<void> _loadTrendingStatus() async {
    if (!_isAdmin) {
      return;
    }

    final song = _currentSong;

    if (song == null) return;

    try {
      final isTrending =
          await _trendingService.isSongTrending(
        song.id,
      );

      if (!mounted) return;

      setState(() {
        _isTrending = isTrending;
        _isTrendingLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isTrendingLoading = false;
      });
    }
  }

  Future<void> _toggleTrending() async {
    if (!_isAdmin ||
        _isTrendingActionLoading) {
      return;
    }

    final song = _currentSong;

    if (song == null) return;

    try {
      setState(() {
        _isTrendingActionLoading = true;
      });

      if (_isTrending) {
        await _trendingService
            .removeSongFromTrending(
          songId: song.id,
        );

        if (!mounted) return;

        setState(() {
          _isTrending = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              '${song.title} dihapus dari Trending',
            ),
          ),
        );
      } else {
        await _trendingService
            .addSongToTrending(
          songId: song.id,
        );

        if (!mounted) return;

        setState(() {
          _isTrending = true;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              '${song.title} berhasil ditambahkan ke Trending',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengubah Trending: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTrendingActionLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final song = _currentSong;

    if (song == null ||
        _isFavoriteLoading) {
      return;
    }

    try {
      await FavoriteService.instance.toggleFavorite(
        song.id,
      );

      if (!mounted) return;

      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengubah favorite: $error',
          ),
        ),
      );
    }
  }

  Future<void> _showAddToPlaylist() async {
    if (_isAddingToPlaylist) {
      return;
    }

    final song = _currentSong;

    if (song == null) {
      return;
    }

    try {
      setState(() {
        _isAddingToPlaylist = true;
      });

      final playlists =
          await PlaylistAddSongService.instance
              .getMyPlaylists();

      if (!mounted) return;

      if (playlists.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Belum ada playlist. Buat playlist terlebih dahulu.',
            ),
          ),
        );

        return;
      }

      final selectedPlaylist =
          await showModalBottomSheet<
              Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    12,
                  ),
                  child: Text(
                    'Tambahkan ke Playlist',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                ...playlists.map(
                  (playlist) {
                    return ListTile(
                      leading: const Icon(
                        Icons.queue_music,
                      ),
                      title: Text(
                        playlist['name']
                            as String,
                      ),
                      onTap: () {
                        Navigator.of(context)
                            .pop(playlist);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      );

      if (selectedPlaylist == null) {
        return;
      }

      final playlistId =
          selectedPlaylist['id'] as String;

      final playlistName =
          selectedPlaylist['name'] as String;

      final alreadyExists =
          await PlaylistAddSongService.instance
              .isSongInPlaylist(
        playlistId: playlistId,
        songId: song.id,
      );

      if (alreadyExists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              '${song.title} sudah ada di "$playlistName"',
            ),
          ),
        );

        return;
      }

      await PlaylistAddSongService.instance
          .addSongToPlaylist(
        playlistId: playlistId,
        songId: song.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${song.title} berhasil ditambahkan ke "$playlistName"',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menambahkan lagu: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToPlaylist = false;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    final song = _currentSong;

    if (song == null) return;

    try {
      if (_audioPlayerService.player.playing) {
        await _audioPlayerService.pause();
      } else {
        await _audioPlayerService.playSong(song);
      }
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

  Future<void> _playNext() async {
    try {
      await _audioPlayerService.playNext();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memutar lagu berikutnya: $error',
          ),
        ),
      );
    }
  }

  Future<void> _playPrevious() async {
    try {
      await _audioPlayerService.playPrevious();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memutar lagu sebelumnya: $error',
          ),
        ),
      );
    }
  }

  Future<void> _seek(
    Duration position,
  ) async {
    await _audioPlayerService.seek(position);
  }

  String _formatSpeed(double speed) {
    final isTenth = (speed * 10).roundToDouble() == speed * 10;
    return speed.toStringAsFixed(isTenth ? 1 : 2);
  }

  Future<void> _showSpeedSheet() async {
    final initialSpeed = _audioPlayerService.speed;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF181818),
      isScrollControlled: false,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: StreamBuilder<double>(
              stream: _audioPlayerService.speedStream,
              initialData: initialSpeed,
              builder: (context, snapshot) {
                final speed = (snapshot.data ?? initialSpeed)
                    .clamp(0.5, 3.0)
                    .toDouble();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SESUAIKAN KECEPATAN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${_formatSpeed(speed)}x',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        0.5,
                        0.75,
                        1.0,
                        1.25,
                        1.5,
                        2.0,
                        3.0,
                      ].map((value) {
                        return _SpeedChoiceButton(
                          value: value,
                          selected: (speed - value).abs() < 0.001,
                          onPressed: () {
                            _audioPlayerService.setSpeed(value);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    Slider(
                      min: 0.5,
                      max: 3.0,
                      divisions: 50,
                      value: speed,
                      label: '${_formatSpeed(speed)}x',
                      onChanged: (value) {
                        final snapped =
                            (value * 20).round() / 20;
                        _audioPlayerService.setSpeed(snapped);
                      },
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0.5x',
                            style: TextStyle(
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            '3.0x',
                            style: TextStyle(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _toggleShuffle() {
    setState(() {
      _playbackQueue.setShuffleEnabled(
        !_playbackQueue.shuffleEnabled,
      );
    });
  }

  void _cycleRepeat() {
    setState(() {
      _playbackQueue.cycleRepeatMode();
    });
  }

  double _nextUpMaxExtent(double availableHeight) {
    final maxExtent = availableHeight * 0.47;
    return maxExtent < _nextUpMinExtent
        ? _nextUpMinExtent
        : maxExtent;
  }

  void _updateNextUpExtent(
    double delta,
    double maxExtent,
  ) {
    setState(() {
      _nextUpExtent = (_nextUpExtent - delta).clamp(
        _nextUpMinExtent,
        maxExtent,
      ).toDouble();
    });
  }

  void _finishNextUpDrag(double maxExtent) {
    final midpoint =
        _nextUpMinExtent +
        ((maxExtent - _nextUpMinExtent) * 0.35);

    setState(() {
      _nextUpExtent = _nextUpExtent > midpoint
          ? maxExtent
          : _nextUpMinExtent;
    });
  }

  Future<void> _playQueuedSong(Song song) async {
    try {
      final selected = _playbackQueue.selectSong(song);

      if (!selected) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lagu tidak ditemukan di queue.'),
          ),
        );
        return;
      }

      await _audioPlayerService.playSong(song);

      if (!mounted) return;
      setState(() {
        _currentSong = song;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memutar lagu: $error'),
        ),
      );
    }
  }

  List<Song> _getNextUpSongs() {
    final queue = _playbackQueue.queue;
    final start = _playbackQueue.currentIndex + 1;

    if (start < 0 || start >= queue.length) {
      return const <Song>[];
    }

    final end = (start + 10 < queue.length)
        ? start + 10
        : queue.length;

    return queue.sublist(start, end);
  }

  Widget _buildNextUpPanel(
    BuildContext context,
    double maxExtent,
  ) {
    final isOpen = _nextUpExtent > _nextUpMinExtent + 4;
    final nextSongs = _getNextUpSongs();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _nextUpExtent,
      child: Material(
        color: Colors.black,
        elevation: 18,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _nextUpExtent = isOpen
                      ? _nextUpMinExtent
                      : maxExtent;
                });
              },
              onVerticalDragUpdate: (details) {
                _updateNextUpExtent(
                  details.primaryDelta ?? 0,
                  maxExtent,
                );
              },
              onVerticalDragEnd: (_) {
                _finishNextUpDrag(maxExtent);
              },
              child: SizedBox(
                width: double.infinity,
                height: 32,
                child: Center(
                  child: AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
            if (isOpen) ...[
                const Text(
                  'Berikutnya',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Expanded(
                  child: nextSongs.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada lagu berikutnya',
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: nextSongs.length,
                          itemBuilder: (context, index) {
                            final nextSong = nextSongs[index];
                            return ListTile(
                              onTap: () => _playQueuedSong(nextSong),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 1,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: nextSong.coverUrl == null ||
                                          nextSong.coverUrl!.isEmpty
                                      ? const ColoredBox(
                                          color: Color(0xFF202020),
                                          child: Icon(
                                            Icons.music_note,
                                            color: Colors.white54,
                                          ),
                                        )
                                      : FutureBuilder<String>(
                                          future: _audioPlayerService
                                              .getSignedCoverUrl(
                                            nextSong.coverUrl!,
                                          ),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const ColoredBox(
                                                color: Color(0xFF202020),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 17,
                                                    height: 17,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                            return Image.network(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const ColoredBox(
                                                  color: Color(0xFF202020),
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white54,
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ),
                              title: Text(
                                nextSong.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                nextSong.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                ),
            ],
            ],
          ),
        ),
    );
  }

  String _formatDuration(
    Duration duration,
  ) {
    final minutes = duration.inMinutes;

    final seconds =
        duration.inSeconds % 60;

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final song = _currentSong;

    if (song == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Tidak ada lagu yang sedang diputar.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bodyConstraints) {
            // Non-scrollable player: make the artwork responsive to the
            // available height so short phone screens never overflow.
            final availableWidth = bodyConstraints.maxWidth - 40;
            final coverSize = (bodyConstraints.maxHeight * 0.40)
                .clamp(220.0, 360.0)
                .clamp(0.0, availableWidth)
                .toDouble();

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 4),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: coverSize,
                      height: coverSize,
                      child: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: _coverUrl == null
                            ? const Icon(
                                Icons.music_note,
                                size: 90,
                              )
                            : Image.network(
                                _coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 90,
                                  );
                                },
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }

                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),

              const SizedBox(height: 34),

              _MarqueeText(
                key: ValueKey('title-${song.id}'),
                text: song.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              _MarqueeText(
                key: ValueKey('artist-${song.id}'),
                text: song.artist,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey.shade400,
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: StreamBuilder<double>(
                  stream: _audioPlayerService.speedStream,
                  initialData: _audioPlayerService.speed,
                  builder: (context, snapshot) {
                    final speed = (snapshot.data ??
                            _audioPlayerService.speed)
                        .clamp(0.5, 3.0)
                        .toDouble();

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: _showSpeedSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.speed,
                                size: 17,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatSpeed(speed)}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 2),

              StreamBuilder<Duration>(
                stream:
                    _audioPlayerService
                        .positionStream,
                builder:
                    (context, positionSnapshot) {
                  final position =
                      positionSnapshot.data ??
                          Duration.zero;

                  return StreamBuilder<
                      Duration?>(
                    stream:
                        _audioPlayerService
                            .durationStream,
                    builder: (
                      context,
                      durationSnapshot,
                    ) {
                      final duration =
                          durationSnapshot.data ??
                              Duration.zero;

                      final maxSeconds =
                          duration.inSeconds >
                                  0
                              ? duration.inSeconds
                                  .toDouble()
                              : 1.0;

                      final currentSeconds =
                          position.inSeconds
                              .clamp(
                                0,
                                duration.inSeconds >
                                        0
                                    ? duration
                                        .inSeconds
                                    : 0,
                              )
                              .toDouble();

                      return Column(
                        children: [
                          Slider(
                            value: currentSeconds
                                .clamp(
                              0,
                              maxSeconds,
                            ),
                            max: maxSeconds,
                            onChanged:
                                duration.inSeconds >
                                        0
                                    ? (value) {
                                        _seek(
                                          Duration(
                                            seconds:
                                                value.round(),
                                          ),
                                        );
                                      }
                                    : null,
                          ),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                  position,
                                ),
                              ),
                              Text(
                                _formatDuration(
                                  duration,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),


              StreamBuilder<bool>(
                stream:
                    _audioPlayerService
                        .playingStream,
                initialData: false,
                builder:
                    (context, snapshot) {
                  final isPlaying =
                      snapshot.data ?? false;

                  return Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed:
                            _toggleShuffle,
                        tooltip: 'Shuffle',
                        icon: Icon(
                          Icons.shuffle,
                          size: 24,
                          color:
                              _shuffleEnabled
                                  ? Theme.of(
                                      context,
                                    )
                                      .colorScheme
                                      .primary
                                  : null,
                        ),
                      ),

                      const SizedBox(width: 8),

                      IconButton(
                        onPressed:
                            _playbackQueue
                                    .hasPrevious
                                ? _playPrevious
                                : null,
                        iconSize: 32,
                        icon: const Icon(
                          Icons.skip_previous,
                        ),
                      ),

                      const SizedBox(width: 12),

                      IconButton.filled(
                        onPressed:
                            _togglePlayPause,
                        iconSize: 40,
                        padding:
                            const EdgeInsets.all(
                          18,
                        ),
                        icon: Icon(
                          isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                      ),

                      const SizedBox(width: 12),

                      IconButton(
                        onPressed:
                            _playbackQueue
                                    .hasNext
                                ? _playNext
                                : null,
                        iconSize: 32,
                        icon: const Icon(
                          Icons.skip_next,
                        ),
                      ),

                      const SizedBox(width: 8),

                      IconButton(
                        onPressed:
                            _cycleRepeat,
                        tooltip: 'Repeat',
                        icon: Stack(
                          alignment:
                              Alignment.center,
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 24,
                              color:
                                  _repeatMode !=
                                          playback_queue
                                              .RepeatMode
                                              .off
                                      ? Theme.of(
                                          context,
                                        )
                                          .colorScheme
                                          .primary
                                      : null,
                            ),
                            if (_repeatMode ==
                                playback_queue
                                    .RepeatMode
                                    .one)
                              Text(
                                '1',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color:
                                      Theme.of(
                                    context,
                                  )
                                          .colorScheme
                                          .primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed:
                        _isFavoriteLoading
                            ? null
                            : _toggleFavorite,
                    tooltip: 'Favorite',
                    icon: Icon(
                      _isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 30,
                      color: _isFavorite
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                          : null,
                    ),
                  ),

                  const SizedBox(width: 16),

                  OutlinedButton.icon(
                    onPressed:
                        _isAddingToPlaylist
                            ? null
                            : _showAddToPlaylist,
                    icon: _isAddingToPlaylist
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.playlist_add,
                          ),
                    label: Text(
                      _isAddingToPlaylist
                          ? 'Menambahkan...'
                          : 'Add to Playlist',
                    ),
                  ),

                  if (_isAdmin) ...[
                    const SizedBox(width: 16),

                    IconButton(
                      onPressed:
                          _isTrendingLoading ||
                                  _isTrendingActionLoading
                              ? null
                              : _toggleTrending,
                      tooltip: _isTrending
                          ? 'Hapus dari Trending'
                          : 'Tambah ke Trending',
                      icon:
                          _isTrendingActionLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _isTrending
                                      ? Icons
                                          .local_fire_department
                                      : Icons
                                          .local_fire_department_outlined,
                                  size: 30,
                                  color: _isTrending
                                      ? Theme.of(
                                          context,
                                        )
                                          .colorScheme
                                          .primary
                                      : null,
                                ),
                    ),
                  ],
                ],
              ),
            ],
          ),
                ),
                if (_nextUpExtent > _nextUpMinExtent + 4)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _nextUpExtent = _nextUpMinExtent;
                        });
                      },
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 10,
                          sigmaY: 10,
                        ),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.38),
                        ),
                      ),
                    ),
                  ),
                _buildNextUpPanel(
                  context,
                  _nextUpMaxExtent(bodyConstraints.maxHeight),
                ),
              ],
            );
      },
    ),
      )
  );
  }
}