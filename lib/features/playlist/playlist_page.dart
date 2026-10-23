import 'package:flutter/material.dart';

import '../favorites/pages/favorite_songs_page.dart';
import 'models/playlist.dart';
import 'pages/playlist_detail_page.dart';
import 'services/playlist_service.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() =>
      _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final PlaylistService _playlistService =
      PlaylistService.instance;

  List<Playlist> _playlists = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final playlists =
          await _playlistService.getMyPlaylists();

      if (!mounted) return;

      setState(() {
        _playlists = playlists;
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

  Future<void> _openFavorites() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const FavoriteSongsPage(),
      ),
    );
  }

  Future<void> _openPlaylist(
    Playlist playlist,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PlaylistDetailPage(
          playlist: playlist,
        ),
      ),
    );
  }

  void _disposeControllerAfterDialog(
    TextEditingController controller,
  ) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        controller.dispose();
      },
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buat Playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama Playlist',
              hintText: 'Contoh: Night Drive',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  value,
                );
              },
              child: const Text('Buat'),
            ),
          ],
        );
      },
    );

    if (name == null ||
        name.trim().isEmpty) {
      _disposeControllerAfterDialog(controller);
      return;
    }

    final playlistName = name.trim();

    try {
      await _playlistService.createPlaylist(
        playlistName,
      );

      if (!mounted) {
        _disposeControllerAfterDialog(controller);
        return;
      }

      await _loadPlaylists();

      if (!mounted) {
        _disposeControllerAfterDialog(controller);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Playlist berhasil dibuat',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        _disposeControllerAfterDialog(controller);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuat playlist: $error',
          ),
        ),
      );
    }

    _disposeControllerAfterDialog(controller);
  }

  Future<void> _showPlaylistMenu(
    Playlist playlist,
  ) async {
    final action =
        await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit,
                ),
                title: const Text(
                  'Rename',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    'rename',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                ),
                title: const Text(
                  'Delete',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    'delete',
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (action == 'rename') {
      await _renamePlaylist(playlist);
    }

    if (action == 'delete') {
      await _deletePlaylist(playlist);
    }
  }

  Future<void> _renamePlaylist(
    Playlist playlist,
  ) async {
    final controller =
        TextEditingController(
      text: playlist.name,
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Rename Playlist',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration:
                const InputDecoration(
              labelText: 'Nama Playlist',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Batal',
              ),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  value,
                );
              },
              child: const Text(
                'Simpan',
              ),
            ),
          ],
        );
      },
    );

    if (name == null ||
        name.trim().isEmpty) {
      _disposeControllerAfterDialog(controller);
      return;
    }

    final playlistName = name.trim();

    try {
      await _playlistService.renamePlaylist(
        playlist.id,
        playlistName,
      );

      await _loadPlaylists();

      if (!mounted) {
        _disposeControllerAfterDialog(controller);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Playlist berhasil diubah',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        _disposeControllerAfterDialog(controller);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengubah playlist: $error',
          ),
        ),
      );
    }

    _disposeControllerAfterDialog(controller);
  }

  Future<void> _deletePlaylist(
    Playlist playlist,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Playlist?',
          ),
          content: Text(
            'Playlist "${playlist.name}" '
            'akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Hapus',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _playlistService.deletePlaylist(
        playlist.id,
      );

      await _loadPlaylists();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Playlist berhasil dihapus',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus playlist: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Playlist',
          ),
        ),
        body: _buildBody(),
        floatingActionButton:
            FloatingActionButton.extended(
          onPressed:
              _showCreatePlaylistDialog,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Playlist',
          ),
        ),
      ),
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
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat playlist',
                style: TextStyle(
                  fontSize: 18,
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
              const SizedBox(height: 16),
              FilledButton(
                onPressed:
                    _loadPlaylists,
                child: const Text(
                  'Coba Lagi',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Text(
            'Library',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // FAVORITE
          Card(
            margin:
                const EdgeInsets.only(
              bottom: 10,
            ),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                  gradient:
                      LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary,
                      Theme.of(context)
                          .colorScheme
                          .secondary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                ),
              ),
              title: const Text(
                'Favorite',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Lagu yang kamu sukai',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: _openFavorites,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'My Playlists',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (_playlists.isEmpty)
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.queue_music,
                      size: 52,
                      color:
                          Theme.of(context)
                              .colorScheme
                              .primary,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      'Belum ada playlist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    const Text(
                      'Buat playlist sendiri '
                      'untuk mengatur lagu.',
                      textAlign:
                          TextAlign.center,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    FilledButton.icon(
                      onPressed:
                          _showCreatePlaylistDialog,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        'Buat Playlist',
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ..._playlists.map(
            (playlist) {
              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      color: Theme.of(
                        context,
                      )
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    child: const Icon(
                      Icons.queue_music,
                    ),
                  ),
                  title: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                  subtitle:
                      const Text(
                    'Playlist',
                  ),
                  trailing:
                      IconButton(
                    onPressed: () {
                      _showPlaylistMenu(
                        playlist,
                      );
                    },
                    icon: const Icon(
                      Icons.more_vert,
                    ),
                  ),
                  onTap: () {
                    _openPlaylist(
                      playlist,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}