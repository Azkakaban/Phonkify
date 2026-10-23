import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';
import '../../player/pages/full_player_page.dart';
import '../../player/services/audio_player_service.dart';
import '../../recommendation/services/catalog_similarity_queue_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final AudioPlayerService _audioPlayerService =
      AudioPlayerService.instance;

  final CatalogSimilarityQueueService
      _catalogSimilarityQueueService =
      CatalogSimilarityQueueService.instance;

  final TextEditingController _searchController =
      TextEditingController();

  final FocusNode _searchFocusNode =
      FocusNode();

  List<Song> _songs = [];

  bool _isLoading = true;

  String? _error;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _loadSongs();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        _searchFocusNode.requestFocus();
      },
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _onSearchChanged,
    );

    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _searchQuery =
          _searchController.text.trim();
    });
  }

  Future<void> _loadSongs() async {
    try {
      final response = await _supabase
          .from('songs')
          .select(
            'id, title, artist, album_id, audio_url, cover_url, '
            'duration, bpm, energy, danceability, valence, subgenre, '
            'created_at, updated_at',
          )
          .order(
            'created_at',
            ascending: true,
          );

      final songs = (response as List)
          .map(
            (item) => Song.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _songs = songs;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  List<Song> get _filteredSongs {
    if (_searchQuery.isEmpty) {
      return [];
    }

    final query =
        _searchQuery.toLowerCase();

    return _songs.where((song) {
      final title =
          song.title.toLowerCase();

      final artist =
          song.artist.toLowerCase();

      return title.contains(query) ||
          artist.contains(query);
    }).toList();
  }

  Future<void> _playSong(
    Song song,
  ) async {
    try {
      await _catalogSimilarityQueueService
          .buildQueue(
        selectedSong: song,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              FullPlayerPage(
            song: song,
          ),
        ),
      );

      await _audioPlayerService
          .playSong(song);
    } catch (error) {
      if (!mounted) {
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    final results = _filteredSongs;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            FocusManager.instance.primaryFocus
                ?.unfocus();

            Navigator.of(context).pop();
          },
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: false,
          textInputAction:
              TextInputAction.search,
          decoration: InputDecoration(
            hintText:
                'Cari lagu atau artis...',
            border: InputBorder.none,
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                        tooltip:
                            'Hapus pencarian',
                        icon: const Icon(
                          Icons.clear,
                        ),
                        onPressed: () {
                          _searchController
                              .clear();
                        },
                      )
                    : null,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(results),
      ),
    );
  }

  Widget _buildBody(
    List<Song> results,
  ) {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
                size: 40,
              ),
              const SizedBox(height: 8),
              const Text(
                'Gagal memuat pencarian.',
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadSongs,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Coba Lagi',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 56,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Cari lagu atau artis',
              style: TextStyle(
                color:
                    Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'Lagu atau artis tidak ditemukan.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24,
      ),
      itemCount: results.length,
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: 4),
      itemBuilder:
          (context, index) {
        final song = results[index];

        return _SearchSongTile(
          key: ValueKey(song.id),
          song: song,
          getCoverUrl:
              _audioPlayerService
                  .getSignedCoverUrl,
          onTap: () =>
              _playSong(song),
        );
      },
    );
  }
}

class _SearchSongTile
    extends StatefulWidget {
  final Song song;

  final Future<String> Function(
    String coverPath,
  ) getCoverUrl;

  final VoidCallback onTap;

  const _SearchSongTile({
    super.key,
    required this.song,
    required this.getCoverUrl,
    required this.onTap,
  });

  @override
  State<_SearchSongTile> createState() =>
      _SearchSongTileState();
}

class _SearchSongTileState
    extends State<_SearchSongTile> {
  String? _coverUrl;

  @override
  void initState() {
    super.initState();

    _loadCover();
  }

  Future<void> _loadCover() async {
    final coverPath =
        widget.song.coverUrl;

    if (coverPath == null ||
        coverPath.isEmpty) {
      return;
    }

    try {
      final url =
          await widget.getCoverUrl(
        coverPath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _coverUrl = url;
      });
    } catch (_) {
      // Placeholder digunakan jika
      // cover gagal dimuat.
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListTile(
      contentPadding:
          EdgeInsets.zero,
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
        widget.song.title,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
      ),
      subtitle: Text(
        widget.song.artist,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.play_arrow,
      ),
      onTap: widget.onTap,
    );
  }
}