import 'package:flutter/material.dart';

import '../../music/models/song.dart';
import '../../player/pages/full_player_page.dart';
import '../../player/services/audio_player_service.dart';
import '../../player/services/playback_queue.dart';
import '../../player/widgets/mini_player.dart';
import '../models/playlist.dart';
import '../services/playlist_song_service.dart';

class PlaylistDetailPage extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistDetailPage> createState() =>
      _PlaylistDetailPageState();
}

class _PlaylistDetailPageState
    extends State<PlaylistDetailPage> {
  final PlaylistSongService _playlistSongService =
      PlaylistSongService.instance;

  final AudioPlayerService _audioPlayerService =
      AudioPlayerService.instance;

  List<Map<String, dynamic>> _songs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response =
          await _playlistSongService
              .getPlaylistSongsWithDetails(
        widget.playlist.id,
      );

      if (!mounted) return;

      setState(() {
        _songs = response;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _playSong(int index) async {
    if (index < 0 || index >= _songs.length) {
      return;
    }

    try {
      final songs = _songs
          .map((item) {
            final map = item['songs'];

            if (map == null) {
              return null;
            }

            return Song.fromMap(
              Map<String, dynamic>.from(map),
            );
          })
          .whereType<Song>()
          .toList();

      if (index >= songs.length) {
        return;
      }

      final song = songs[index];

      PlaybackQueue.instance.setQueue(
        songs: songs,
        startIndex: index,
        context: PlaybackContext.playlist,
      );

      await _audioPlayerService.playSong(song);
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

  void _openFullPlayer() {
    final currentSong =
        _audioPlayerService.currentSong;

    if (currentSong == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullPlayerPage(
          song: currentSong,
        ),
      ),
    );
  }

  Future<void> _moveUp(int index) async {
    if (index <= 0 ||
        index >= _songs.length) {
      return;
    }

    final song =
        _songs[index]['songs']
            as Map<String, dynamic>?;

    final songId = song?['id']?.toString();

    if (songId == null || songId.isEmpty) {
      return;
    }

    try {
      await _playlistSongService.moveSongUp(
        playlistId: widget.playlist.id,
        songId: songId,
      );

      await _loadSongs();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memindahkan lagu: $error',
          ),
        ),
      );
    }
  }

  Future<void> _moveDown(int index) async {
    if (index < 0 ||
        index >= _songs.length - 1) {
      return;
    }

    final song =
        _songs[index]['songs']
            as Map<String, dynamic>?;

    final songId = song?['id']?.toString();

    if (songId == null || songId.isEmpty) {
      return;
    }

    try {
      await _playlistSongService.moveSongDown(
        playlistId: widget.playlist.id,
        songId: songId,
      );

      await _loadSongs();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memindahkan lagu: $error',
          ),
        ),
      );
    }
  }

  Future<void> _deleteSong(int index) async {
    if (index < 0 || index >= _songs.length) {
      return;
    }

    final song =
        _songs[index]['songs']
            as Map<String, dynamic>?;

    final songId = song?['id']?.toString();

    final title =
        song?['title']?.toString() ??
            'lagu ini';

    if (songId == null || songId.isEmpty) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus dari Playlist?',
          ),
          content: Text(
            'Apakah kamu yakin ingin menghapus '
            '"$title" dari playlist ini?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _playlistSongService
          .removeSongFromPlaylist(
        playlistId: widget.playlist.id,
        songId: songId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"$title" berhasil dihapus dari playlist',
          ),
        ),
      );

      await _loadSongs();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus lagu: $error',
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
          .getSignedCoverUrl(coverPath);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: MiniPlayer(
          key: ValueKey(
            _audioPlayerService.currentSong?.id,
          ),
          onTap: _openFullPlayer,
        ),
      ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat lagu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadSongs,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Playlist masih kosong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Belum ada lagu di playlist ini.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSongs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final item = _songs[index];

          final song =
              item['songs']
                  as Map<String, dynamic>?;

          final title =
              song?['title']?.toString() ??
                  'Unknown Song';

          final artist =
              song?['artist']?.toString() ??
                  'Unknown Artist';

          final coverPath =
              song?['cover_url']?.toString();

          return _PlaylistSongTile(
            key: ValueKey(
              '${widget.playlist.id}-$index-${song?['id']}',
            ),
            index: index,
            title: title,
            artist: artist,
            coverPath: coverPath,
            getCoverUrl: _getCoverUrl,
            onTap: () => _playSong(index),
            onMoveUp: index == 0
                ? null
                : () => _moveUp(index),
            onMoveDown:
                index == _songs.length - 1
                    ? null
                    : () => _moveDown(index),
            onDelete: () => _deleteSong(index),
          );
        },
      ),
    );
  }
}

class _PlaylistSongTile extends StatefulWidget {
  final int index;
  final String title;
  final String artist;
  final String? coverPath;
  final Future<String?> Function(String?) getCoverUrl;
  final VoidCallback onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  const _PlaylistSongTile({
    super.key,
    required this.index,
    required this.title,
    required this.artist,
    required this.coverPath,
    required this.getCoverUrl,
    required this.onTap,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
  });

  @override
  State<_PlaylistSongTile> createState() =>
      _PlaylistSongTileState();
}

class _PlaylistSongTileState
    extends State<_PlaylistSongTile> {
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    final url = await widget.getCoverUrl(
      widget.coverPath,
    );

    if (!mounted) return;

    setState(() {
      _coverUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        onTap: widget.onTap,

        leading: SizedBox(
          width: 52,
          height: 52,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(8),
            child: Container(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              child: _coverUrl == null
                  ? const Icon(
                      Icons.music_note,
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
                        return const Icon(
                          Icons.broken_image,
                        );
                      },
                      loadingBuilder:
                          (
                        context,
                        child,
                        loadingProgress,
                      ) {
                        if (loadingProgress ==
                            null) {
                          return child;
                        }

                        return const Center(
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),

        title: Text(
          widget.title,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),

        subtitle: Text(
          widget.artist,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),

        trailing: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Move Up',
              onPressed: widget.onMoveUp,
              icon: const Icon(
                Icons.keyboard_arrow_up,
              ),
            ),
            IconButton(
              tooltip: 'Move Down',
              onPressed:
                  widget.onMoveDown,
              icon: const Icon(
                Icons.keyboard_arrow_down,
              ),
            ),
            IconButton(
              tooltip:
                  'Hapus dari Playlist',
              onPressed: widget.onDelete,
              icon: const Icon(
                Icons.delete_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}