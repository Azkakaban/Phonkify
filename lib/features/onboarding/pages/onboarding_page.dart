import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../music/models/song.dart';
import '../../../recommendation/services/recommendation_cache_service.dart';
import '../../../recommendation/services/recommendation_service.dart';
import '../services/onboarding_service.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingPage({
    super.key,
    required this.onCompleted,
  });

  @override
  State<OnboardingPage> createState() =>
      _OnboardingPageState();
}

class _OnboardingPageState
    extends State<OnboardingPage> {
  final OnboardingService _onboardingService =
      OnboardingService.instance;

  final RecommendationService
      _recommendationService =
      RecommendationService.instance;

  final RecommendationCacheService
      _cacheService =
      RecommendationCacheService.instance;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // Player khusus preview onboarding.
  // Tidak memakai AudioPlayerService agar preview tidak
  // membuat listening history atau mengubah playback queue utama.
  final AudioPlayer _previewPlayer = AudioPlayer();

  String? _previewSongId;
  List<Song> _songs = [];

  final Set<String> _selectedSongIds =
      <String>{};

  final Map<String, String> _coverUrls =
      <String, String>{};

  final Set<String> _coverLoadingIds =
      <String>{};

  bool _isLoading = true;
  bool _isSaving = false;

  String? _errorMessage;

  static const int _minimumSelection = 5;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final songs =
          await _onboardingService
              .getSongsForOnboarding();

      final existingSelected =
          await _onboardingService
              .getSelectedSongIds();

      if (!mounted) return;

      setState(() {
        _songs = songs;
        _selectedSongIds.addAll(
          existingSelected,
        );
        _isLoading = false;
      });

      await _loadCoverUrls(songs);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            error.toString();
      });
    }
  }

  Future<void> _loadCoverUrls(
    List<Song> songs,
  ) async {
    for (final song in songs) {
      final coverPath = song.coverUrl;

      if (coverPath == null ||
          coverPath.isEmpty) {
        continue;
      }

      if (_coverUrls.containsKey(song.id)) {
        continue;
      }

      if (!mounted) return;

      setState(() {
        _coverLoadingIds.add(song.id);
      });

      try {
        final path =
            coverPath.startsWith('covers/')
                ? coverPath.substring(
                    'covers/'.length,
                  )
                : coverPath;

        final url =
            await _supabase.storage
                .from('covers')
                .createSignedUrl(
                  path,
                  3600,
                );

        if (!mounted) return;

        setState(() {
          _coverUrls[song.id] = url;
          _coverLoadingIds.remove(
            song.id,
          );
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _coverLoadingIds.remove(
            song.id,
          );
        });
      }
    }
  }

  Future<void> _toggleSong(
    String songId,
  ) async {
    if (_isSaving) return;

    final wasSelected =
        _selectedSongIds.contains(songId);

    setState(() {
      if (wasSelected) {
        _selectedSongIds.remove(songId);
      } else {
        _selectedSongIds.add(songId);
      }
    });

    // Setiap lagu yang dipilih langsung dipreview.
    // Jika lagu yang sama ditekan lagi untuk membatalkan pilihan,
    // preview dihentikan.
    if (wasSelected) {
      if (_previewSongId == songId) {
        await _stopPreview();
      }
      return;
    }

    final song = _songs.cast<Song?>().firstWhere(
          (item) => item?.id == songId,
          orElse: () => null,
        );

    if (song != null) {
      await _previewSong(song);
    }
  }

  Future<void> _previewSong(Song song) async {
    if (_isSaving) return;

    if (_previewSongId == song.id &&
        _previewPlayer.playing) {
      return;
    }

    setState(() {
      _previewSongId = song.id;
    });

    try {
      final audioPath = song.audioUrl;
      final path = audioPath.startsWith('audio/')
          ? audioPath.substring('audio/'.length)
          : audioPath;

      final signedUrl = await _supabase.storage
          .from('audio')
          .createSignedUrl(
            path,
            3600,
          );

      await _previewPlayer.setUrl(signedUrl);
      await _previewPlayer.play();

      if (!mounted) return;

      setState(() {
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _previewSongId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memutar preview: $error',
          ),
        ),
      );
    }
  }

  Future<void> _stopPreview() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {
      // Tidak mengganggu proses onboarding jika player gagal stop.
    }

    if (!mounted) return;

    setState(() {
      _previewSongId = null;
    });
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_selectedSongIds.length <
        _minimumSelection) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Pilih minimal '
            '$_minimumSelection lagu.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Preview hanya untuk membantu user memilih lagu.
    // Hentikan sebelum proses finalisasi onboarding.
    await _stopPreview();

    try {
      // 1. Simpan preferensi onboarding.
      await _onboardingService
          .savePreferences(
        _selectedSongIds.toList(),
      );

      // 2. Hitung cold-start recommendation
      //    berdasarkan music similarity.
      final recommendations =
          await _recommendationService
              .getColdStartRecommendationsWithScores(
        limit: 10,
      );

      // 3. Simpan hasil cold-start ke cache.
      if (recommendations.isNotEmpty) {
        final songs =
            recommendations
                .map(
                  (item) => item.song,
                )
                .toList();

        final scores =
            <String, double>{};

        for (final item
            in recommendations) {
          scores[item.song.id] =
              item.score;
        }

        await _cacheService
            .saveColdStartRecommendations(
          songs: songs,
          scores: scores,
        );
      }

      if (!mounted) return;

      // Onboarding ditampilkan langsung oleh AuthGate, bukan sebagai route terpisah.
      // Jadi jangan pop Navigator karena itu dapat mengosongkan route utama
      // dan menghasilkan layar hitam. Beri tahu AuthGate bahwa onboarding selesai.
      await _stopPreview();

      if (!mounted) return;

      widget.onCompleted();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyiapkan rekomendasi: '
            '$error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pilih Musik Favoritmu',
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
        bottomNavigationBar:
            _buildBottomButton(),
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
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat lagu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadSongs,
                child: const Text(
                  'Coba Lagi',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_songs.length <
        _minimumSelection) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.music_off,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Lagu belum cukup',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Onboarding membutuhkan '
                'minimal $_minimumSelection '
                'lagu di database.',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            12,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Kenali selera musikmu',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih setidaknya 5 lagu '
                'yang kamu suka. Pilihan '
                'ini akan digunakan sebagai '
                'preferensi awal.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedSongIds.length} '
                    'lagu dipilih',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• minimal '
                    '$_minimumSelection',
                    style: TextStyle(
                      color:
                          Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              20,
            ),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: _songs.length,
            itemBuilder:
                (context, index) {
              final song =
                  _songs[index];

              return _SongSelectionCard(
                key: ValueKey(song.id),
                song: song,
                selected:
                    _selectedSongIds
                        .contains(song.id),
                coverUrl:
                    _coverUrls[song.id],
                isCoverLoading:
                    _coverLoadingIds
                        .contains(song.id),
                onTap: () {
                  _toggleSong(
                    song.id,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final canContinue =
        _selectedSongIds.length >=
            _minimumSelection &&
        !_isSaving;

    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16,
        ),
        child: FilledButton(
          onPressed: canContinue
              ? _continue
              : null,
          style: FilledButton.styleFrom(
            minimumSize:
                const Size.fromHeight(
              52,
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _selectedSongIds.length <
                          _minimumSelection
                      ? 'Pilih minimal '
                          '$_minimumSelection lagu'
                      : 'Lanjut ke Phonkify',
                ),
        ),
      ),
    );
  }
}

class _SongSelectionCard
    extends StatelessWidget {
  final Song song;
  final bool selected;
  final String? coverUrl;
  final bool isCoverLoading;
  final VoidCallback onTap;

  const _SongSelectionCard({
    super.key,
    required this.song,
    required this.selected,
    required this.coverUrl,
    required this.isCoverLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior:
            Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildCover(context),
            ),
            Positioned.fill(
              child: AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 180,
                ),
                color: selected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(
                          alpha: 0.22,
                        )
                    : Colors.transparent,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration:
                    BoxDecoration(
                  gradient:
                      LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(
                        alpha: 0.78,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 34,
                  height: 34,
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
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(
    BuildContext context,
  ) {
    if (coverUrl != null &&
        coverUrl!.isNotEmpty) {
      return Image.network(
        coverUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return _buildPlaceholder(
            context,
            Icons.broken_image,
          );
        },
        loadingBuilder:
            (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return _buildPlaceholder(
            context,
            Icons.music_note,
            loading: true,
          );
        },
      );
    }

    if (isCoverLoading) {
      return _buildPlaceholder(
        context,
        Icons.music_note,
        loading: true,
      );
    }

    return _buildPlaceholder(
      context,
      Icons.music_note,
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    IconData icon, {
    bool loading = false,
  }) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest,
      child: Center(
        child: loading
            ? const SizedBox(
                width: 28,
                height: 28,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Icon(
                icon,
                size: 54,
              ),
      ),
    );
  }
}