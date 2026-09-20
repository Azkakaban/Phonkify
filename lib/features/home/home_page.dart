import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../recommendation/services/catalog_similarity_queue_service.dart';
import '../history/services/listening_history_service.dart';
import '../music/models/song.dart';
import '../player/pages/full_player_page.dart';
import '../player/services/audio_player_service.dart';
import '../player/services/playback_queue.dart';
import '../profile/services/profile_service.dart';
import '../recommendation/services/recommendation_cache_service.dart';
import '../search/pages/search_page.dart';
import '../trending/pages/trending_test_page.dart';
import '../trending/services/trending_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final AudioPlayerService _audioPlayerService =
      AudioPlayerService.instance;

  final PlaybackQueue _playbackQueue =
      PlaybackQueue.instance;

  final ProfileService _profileService =
      ProfileService();

  final TrendingService _trendingService =
      TrendingService.instance;

  final ListeningHistoryService _historyService =
      ListeningHistoryService.instance;

  final RecommendationCacheService
      _recommendationCacheService =
      RecommendationCacheService.instance;

    final CatalogSimilarityQueueService
    _catalogSimilarityQueueService =
    CatalogSimilarityQueueService.instance;

  final TextEditingController _searchController =
      TextEditingController();

  List<Song> _songs = [];
  List<Map<String, dynamic>> _trendingSongs = [];
  List<Song> _recentlyPlayedSongs = [];
  List<Song> _aiRecommendationSongs = [];

  bool _isLoadingSongs = true;
  bool _isLoadingTrending = true;
  bool _isLoadingRecentlyPlayed = true;
  bool _isLoadingAiRecommendation = true;

  String? _songsError;
  String? _trendingError;
  String? _recentlyPlayedError;
  String? _aiRecommendationError;

  bool _isAdmin = false;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _loadProfile();
    _loadSongs();
    _loadTrendingSongs();
    _loadRecentlyPlayed();
    _loadAiRecommendation();

    _searchController.addListener(
      _onSearchChanged,
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _onSearchChanged,
    );

    _searchController.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _searchQuery =
          _searchController.text.trim();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final profile =
          await _profileService.getCurrentProfile();

      if (!mounted) return;

      setState(() {
        _isAdmin =
            profile?['role'] == 'ADMIN';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isAdmin = false;
      });
    }
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

    if (!mounted) return;

    setState(() {
      _songs = songs;
      _isLoadingSongs = false;
      _songsError = null;
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _isLoadingSongs = false;
      _songsError = error.toString();
    });
  }
}
  Future<void> _loadTrendingSongs() async {
    try {
      final response =
          await _trendingService
              .getTrendingSongs();

      if (!mounted) return;

      setState(() {
        _trendingSongs = response;
        _isLoadingTrending = false;
        _trendingError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingTrending = false;
        _trendingError =
            error.toString();
      });
    }
  }

  Future<void> _loadRecentlyPlayed() async {
    try {
      final songs =
          await _historyService
              .getRecentlyPlayed(
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        _recentlyPlayedSongs = songs;
        _isLoadingRecentlyPlayed = false;
        _recentlyPlayedError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingRecentlyPlayed = false;
        _recentlyPlayedError =
            error.toString();
      });
    }
  }

  Future<void> _loadAiRecommendation() async {
    try {
      final cachedRecommendations =
          await _recommendationCacheService
              .getRecommendations();

              for (final recommendation
    in cachedRecommendations) {
  debugPrint(
    '[AI HOME] '
    'position=${recommendation.position} '
    'score=${recommendation.recommendationScore} '
    'song=${recommendation.song.title}',
  );
}

      final songs = cachedRecommendations
          .map(
            (recommendation) =>
                recommendation.song,
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _aiRecommendationSongs = songs;
        _isLoadingAiRecommendation = false;
        _aiRecommendationError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingAiRecommendation = false;
        _aiRecommendationError =
            error.toString();
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

    if (!mounted) return;

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

  Future<void> _playTrendingSong(
  Song song,
) async {
  try {
    await _catalogSimilarityQueueService
        .buildQueue(
      selectedSong: song,
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

  Future<void> _playRecentlyPlayedSong(
  Song song,
) async {
  try {
    await _catalogSimilarityQueueService
        .buildQueue(
      selectedSong: song,
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

  Future<void> _playAiRecommendationSong(
    Song song,
  ) async {
    final index =
        _aiRecommendationSongs.indexWhere(
      (item) => item.id == song.id,
    );

    if (index < 0) {
      return;
    }

    _playbackQueue.setQueue(
      songs: _aiRecommendationSongs,
      startIndex: index,
      context: PlaybackContext.aiRecommendation,
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

  void _openTrendingTest() {
    if (!_isAdmin) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const TrendingTestPage(),
      ),
    );
  }

  Song? _songFromTrendingItem(
    Map<String, dynamic> item,
  ) {
    final songData =
        item['songs'];

    if (songData is! Map) {
      return null;
    }

    try {
      return Song.fromMap(
        Map<String, dynamic>.from(
          songData,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildSearchBar() {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SearchPage(),
        ),
      );
    },
    child: IgnorePointer(
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari lagu atau artis...',
          prefixIcon: const Icon(
            Icons.search,
          ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSearchResults() {
    final results =
        _filteredSongs;

    if (_isLoadingSongs) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 24,
        ),
        child: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_songsError != null) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      vertical: 24,
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
          ),
          const SizedBox(height: 8),
          const Text(
            'Gagal memuat pencarian.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadSongs,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );
}

    if (results.isEmpty) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 24,
        ),
        child: Center(
          child: Text(
            'Lagu atau artis tidak ditemukan.',
          ),
        ),
      );
    }

    return Column(
      children:
          results.map(
        (song) {
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
      ).toList(),
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Trending',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            if (_isAdmin)
              IconButton(
                tooltip:
                    'Trending Test',
                icon: const Icon(
                  Icons
                      .local_fire_department,
                ),
                onPressed:
                    _openTrendingTest,
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTrendingContent(),
      ],
    );
  }

  Widget _buildTrendingContent() {
    if (_isLoadingTrending) {
      return const SizedBox(
        height: 220,
        child: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_trendingError != null) {
  return SizedBox(
    height: 180,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
          ),
          const SizedBox(height: 8),
          const Text(
            'Gagal memuat Trending.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadTrendingSongs,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );
}

    if (_trendingSongs.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Belum ada lagu Trending.',
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.only(
          right: 24,
        ),
        itemCount:
            _trendingSongs.length,
        separatorBuilder:
            (context, index) =>
                const SizedBox(
          width: 12,
        ),
        itemBuilder:
            (context, index) {
          final item =
              _trendingSongs[index];

          final song =
              _songFromTrendingItem(
            item,
          );

          if (song == null) {
            return const SizedBox
                .shrink();
          }

          return _TrendingCard(
            key: ValueKey(song.id),
            song: song,
            rank: index + 1,
            onTap: () =>
                _playTrendingSong(
              song,
            ),
            getCoverUrl:
                _audioPlayerService
                    .getSignedCoverUrl,
          );
        },
      ),
    );
  }

  Widget _buildRecentlyPlayedSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Recently Played',
          style: TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildRecentlyPlayedContent(),
      ],
    );
  }

  Widget _buildRecentlyPlayedContent() {
    if (_isLoadingRecentlyPlayed) {
      return const SizedBox(
        height: 160,
        child: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_recentlyPlayedError != null) {
  return SizedBox(
    height: 140,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
          ),
          const SizedBox(height: 8),
          const Text(
            'Gagal memuat Recently Played.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadRecentlyPlayed,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );
}

    if (_recentlyPlayedSongs.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Belum ada riwayat pemutaran.',
          ),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.only(
          right: 24,
        ),
        itemCount:
            _recentlyPlayedSongs.length,
        separatorBuilder:
            (context, index) =>
                const SizedBox(
          width: 12,
        ),
        itemBuilder:
            (context, index) {
          final song =
              _recentlyPlayedSongs[index];

          return _RecentlyPlayedCard(
            key: ValueKey(song.id),
            song: song,
            onTap: () =>
                _playRecentlyPlayedSong(
              song,
            ),
            getCoverUrl:
                _audioPlayerService
                    .getSignedCoverUrl,
          );
        },
      ),
    );
  }

  Widget _buildAiRecommendationSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Recommendation',
          style: TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildAiRecommendationContent(),
      ],
    );
  }

  Widget _buildAiRecommendationContent() {
    if (_isLoadingAiRecommendation) {
      return const SizedBox(
        height: 190,
        child: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_aiRecommendationError != null) {
  return SizedBox(
    height: 140,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
          ),
          const SizedBox(height: 8),
          const Text(
            'Gagal memuat AI Recommendation.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadAiRecommendation,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );
}

    if (_aiRecommendationSongs.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(20),
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(16),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
        ),
        child: const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 28,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Belum ada rekomendasi musik '
                'untukmu.',
              ),
            ),
          ],
        ),
      );
    }

    return Directionality(
  textDirection: TextDirection.ltr,
  child: SizedBox(
    height: 190,
    child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.only(
          right: 24,
        ),
        itemCount:
            _aiRecommendationSongs.length,
        separatorBuilder:
            (context, index) =>
                const SizedBox(
          width: 12,
        ),
        itemBuilder:
            (context, index) {
          final song =
              _aiRecommendationSongs[
                  index];

          return _AiRecommendationCard(
            key: ValueKey(song.id),
            song: song,
            onTap: () =>
                _playAiRecommendationSong(
              song,
            ),
            getCoverUrl:
                _audioPlayerService
                    .getSignedCoverUrl,
          );
        },
      ),
    )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching =
        _searchQuery.isNotEmpty;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadSongs(),
            _loadTrendingSongs(),
            _loadRecentlyPlayed(),
            _loadAiRecommendation(),
          ]);
        },
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            100,
          ),
          children: [
           Row(
  children: [
    Image.asset(
      'assets/icons/phonkify_icon.png',
      width: 38,
      height: 38,
    ),

    const SizedBox(width: 10),

    const Expanded(
      child: Text(
        'Phonkify',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
                if (_isAdmin)
                  IconButton(
                    tooltip:
                        'Trending Test',
                    icon: const Icon(
                      Icons
                          .local_fire_department,
                    ),
                    onPressed:
                        _openTrendingTest,
                  ),
              ],
            ),

            const SizedBox(height: 18),

            _buildSearchBar(),

            if (isSearching) ...[
              const SizedBox(height: 24),

              const Text(
                'Hasil Pencarian',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              _buildSearchResults(),
            ] else ...[
              const SizedBox(height: 28),

              _buildTrendingSection(),

              const SizedBox(height: 32),

              _buildRecentlyPlayedSection(),

              const SizedBox(height: 32),

              _buildAiRecommendationSection(),
            ],
          ],
        ),
      ),
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

      if (!mounted) return;

      setState(() {
        _coverUrl = url;
      });
    } catch (_) {
      // Placeholder digunakan jika
      // cover gagal dimuat.
    }
  }

  @override
  Widget build(BuildContext context) {
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
      trailing:
          const Icon(
        Icons.play_arrow,
      ),
      onTap: widget.onTap,
    );
  }
}

class _RecentlyPlayedCard
    extends StatefulWidget {
  final Song song;
  final VoidCallback onTap;

  final Future<String> Function(
    String coverPath,
  ) getCoverUrl;

  const _RecentlyPlayedCard({
    super.key,
    required this.song,
    required this.onTap,
    required this.getCoverUrl,
  });

  @override
  State<_RecentlyPlayedCard> createState() =>
      _RecentlyPlayedCardState();
}

class _RecentlyPlayedCardState
    extends State<_RecentlyPlayedCard> {
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

      if (!mounted) return;

      setState(() {
        _coverUrl = url;
      });
    } catch (_) {
      // Placeholder digunakan jika
      // cover gagal dimuat.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 135,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 135,
              height: 135,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(16),
                child: Container(
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .surfaceContainerHighest,
                  child:
                      _coverUrl == null
                          ? const Icon(
                              Icons.history,
                              size: 48,
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
                                  Icons
                                      .broken_image,
                                  size: 48,
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
                                      CircularProgressIndicator(),
                                );
                              },
                            ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.song.title,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.song.artist,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiRecommendationCard
    extends StatefulWidget {
  final Song song;
  final VoidCallback onTap;

  final Future<String> Function(
    String coverPath,
  ) getCoverUrl;

  const _AiRecommendationCard({
    super.key,
    required this.song,
    required this.onTap,
    required this.getCoverUrl,
  });

  @override
  State<_AiRecommendationCard> createState() =>
      _AiRecommendationCardState();
}

class _AiRecommendationCardState
    extends State<_AiRecommendationCard> {
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

      if (!mounted) return;

      setState(() {
        _coverUrl = url;
      });
    } catch (_) {
      // Placeholder digunakan jika
      // cover gagal dimuat.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 135,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 135,
              height: 135,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .surfaceContainerHighest,
                      child:
                          _coverUrl == null
                              ? const Icon(
                                  Icons
                                      .auto_awesome,
                                  size: 48,
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
                                      Icons
                                          .broken_image,
                                      size: 48,
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
                                          CircularProgressIndicator(),
                                    );
                                  },
                                ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .primary,
                        ),
                        child:
                            const Padding(
                          padding:
                              EdgeInsets.all(
                            9,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.song.title,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.song.artist,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingCard
    extends StatefulWidget {
  final Song song;
  final int rank;
  final VoidCallback onTap;

  final Future<String> Function(
    String coverPath,
  ) getCoverUrl;

  const _TrendingCard({
    super.key,
    required this.song,
    required this.rank,
    required this.onTap,
    required this.getCoverUrl,
  });

  @override
  State<_TrendingCard> createState() =>
      _TrendingCardState();
}

class _TrendingCardState
    extends State<_TrendingCard> {
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

      if (!mounted) return;

      setState(() {
        _coverUrl = url;
      });
    } catch (_) {
      // Placeholder digunakan jika
      // cover gagal dimuat.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: widget.onTap,
        child: Card(
          clipBehavior:
              Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .surfaceContainerHighest,
                      child:
                          _coverUrl == null
                              ? const Icon(
                                  Icons.music_note,
                                  size: 56,
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
                                      Icons
                                          .broken_image,
                                      size: 56,
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
                                          CircularProgressIndicator(),
                                    );
                                  },
                                ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.black
                              .withValues(
                            alpha: 0.75,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child: Text(
                          '#${widget.rank}',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        decoration:
                            BoxDecoration(
                          shape:
                              BoxShape.circle,
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .primary,
                        ),
                        child:
                            const Padding(
                          padding:
                              EdgeInsets.all(
                            9,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  10,
                  12,
                  12,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      widget.song.artist,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}