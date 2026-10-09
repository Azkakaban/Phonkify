import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';
import '../../music/services/song_service.dart';
import '../services/audio_player_service.dart';

class TestPlayerPage extends StatefulWidget {
  const TestPlayerPage({super.key});

  @override
  State<TestPlayerPage> createState() => _TestPlayerPageState();
}

class _TestPlayerPageState extends State<TestPlayerPage> {
  final SongService _songService = SongService();
  final AudioPlayerService _audioPlayerService =
    AudioPlayerService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Song? _song;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSong();
  }

  Future<void> _loadSong() async {
    try {
      final songs = await _songService.getSongs();

      if (!mounted) return;

      if (songs.isEmpty) {
        setState(() {
          _errorMessage = 'Belum ada lagu.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _song = songs.first;
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

  Future<void> _togglePlayPause() async {
    if (_song == null) return;

    try {
      if (_audioPlayerService.player.playing) {
        await _audioPlayerService.pause();
      } else {
        await _audioPlayerService.playSong(_song!);
      }

      if (!mounted) return;

      setState(() {});
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memutar lagu: $error'),
        ),
      );
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayerService.seek(position);
  }

  Future<String?> _getCoverUrl(String? coverPath) async {
    if (coverPath == null || coverPath.isEmpty) {
      return null;
    }

    final path = coverPath.startsWith('covers/')
        ? coverPath.substring('covers/'.length)
        : coverPath;

    try {
      return await _supabase.storage
          .from('covers')
          .createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Test Player'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Gagal memuat lagu:\n$_errorMessage',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_song == null) {
      return const Scaffold(
        body: Center(
          child: Text('Lagu tidak ditemukan'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // COVER LAGU
            FutureBuilder<String?>(
              future: _getCoverUrl(_song!.coverUrl),
              builder: (context, snapshot) {
                final coverUrl = snapshot.data;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 280,
                    height: 280,
                    color: Theme.of(context).colorScheme.surface,
                    child: coverUrl == null
                        ? const Icon(
                            Icons.music_note,
                            size: 80,
                          )
                        : Image.network(
                            coverUrl,
                            width: 280,
                            height: 280,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                size: 80,
                              );
                            },
                            loadingBuilder:
                                (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // JUDUL LAGU
            Text(
              _song!.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // ARTIST
            Text(
              _song!.artist,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 32),

            // PROGRESS + SEEK
            StreamBuilder<Duration>(
              stream: _audioPlayerService.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;

                return StreamBuilder<Duration?>(
                  stream: _audioPlayerService.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration =
                        durationSnapshot.data ?? Duration.zero;

                    final maxSeconds = duration.inSeconds > 0
                        ? duration.inSeconds.toDouble()
                        : 1.0;

                    final currentSeconds = position.inSeconds
                        .clamp(
                          0,
                          duration.inSeconds > 0
                              ? duration.inSeconds
                              : 0,
                        )
                        .toDouble();

                    return Column(
                      children: [
                        Slider(
                          value: currentSeconds.clamp(
                            0,
                            maxSeconds,
                          ),
                          max: maxSeconds,
                          onChanged: duration.inSeconds > 0
                              ? (value) {
                                  _seek(
                                    Duration(
                                      seconds: value.round(),
                                    ),
                                  );
                                }
                              : null,
                        ),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                            ),
                            Text(
                              _formatDuration(duration),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // PLAY / PAUSE SATU TOMBOL
            StreamBuilder<bool>(
              stream: _audioPlayerService.player.playingStream,
              initialData: false,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;

                return IconButton.filled(
                  onPressed: _togglePlayPause,
                  iconSize: 36,
                  padding: const EdgeInsets.all(18),
                  icon: Icon(
                    isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
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