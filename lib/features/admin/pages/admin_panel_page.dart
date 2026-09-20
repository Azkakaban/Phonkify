import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../music/models/song.dart';
import '../../music/services/song_service.dart';
import '../../music/services/song_storage_service.dart';
import '../../trending/pages/trending_test_page.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.library_music,
              ),
              title: const Text(
                'Manage Songs',
              ),
              subtitle: const Text(
                'Tambah, edit, dan hapus lagu',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const AdminSongsPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.trending_up,
              ),
              title: const Text(
                'Manage Trending',
              ),
              subtitle: const Text(
                'Atur lagu dan urutan Trending',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const TrendingTestPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSongsPage extends StatefulWidget {
  const AdminSongsPage({super.key});

  @override
  State<AdminSongsPage> createState() =>
      _AdminSongsPageState();
}

class _AdminSongsPageState
    extends State<AdminSongsPage> {
  final SongService _songService =
      SongService();

  final TextEditingController _searchController =
      TextEditingController();

  List<Song> _songs = [];

  bool _isLoading = true;
  bool _isSearching = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final songs =
          await _songService.getSongs();

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

  Future<void> _searchSongs() async {
    final query =
        _searchController.text.trim();

    if (query.isEmpty) {
      await _loadSongs();
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final songs =
          await _songService.searchSongs(
        query,
      );

      if (!mounted) return;

      setState(() {
        _songs = songs;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSearching = false;
        _errorMessage =
            error.toString();
      });
    }
  }

  Future<void> _showSongForm({
    Song? song,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return SongFormDialog(
          song: song,
          songService: _songService,
        );
      },
    );

    if (result == true) {
      await _loadSongs();
    }
  }

  Future<void> _deleteSong(
    Song song,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Lagu?',
          ),
          content: Text(
            'Lagu "${song.title}" akan dihapus. '
            'Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false);
              },
              child: const Text(
                'Batal',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true);
              },
              child: const Text(
                'Hapus',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _songService.deleteSong(
        song.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Lagu berhasil dihapus',
          ),
        ),
      );

      await _loadSongs();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus lagu: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Songs',
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          _showSongForm();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Lagu'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller:
                  _searchController,
              textInputAction:
                  TextInputAction.search,
              onSubmitted: (_) {
                _searchSongs();
              },
              decoration:
                  InputDecoration(
                hintText:
                    'Cari judul atau artist...',
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    IconButton(
                  onPressed:
                      _searchSongs,
                  icon: const Icon(
                    Icons.search,
                  ),
                ),
                border:
                    const OutlineInputBorder(),
              ),
            ),
          ),
          if (_isSearching)
            const LinearProgressIndicator(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
          child: Text(
            'Gagal memuat songs:\n'
            '$_errorMessage',
            textAlign:
                TextAlign.center,
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
      onRefresh: _loadSongs,
      child: ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          100,
        ),
        itemCount: _songs.length,
        separatorBuilder:
            (context, index) =>
                const SizedBox(height: 8),
        itemBuilder:
            (context, index) {
          final song =
              _songs[index];

          return Card(
            child: ListTile(
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
                onSelected: (value) {
                  if (value == 'edit') {
                    _showSongForm(
                      song: song,
                    );
                  }

                  if (value == 'delete') {
                    _deleteSong(song);
                  }
                },
                itemBuilder:
                    (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      'Edit',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Hapus',
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

class SongFormDialog
    extends StatefulWidget {
  final Song? song;
  final SongService songService;

  const SongFormDialog({
    super.key,
    this.song,
    required this.songService,
  });

  @override
  State<SongFormDialog> createState() =>
      _SongFormDialogState();
}

class _SongFormDialogState
    extends State<SongFormDialog> {
  final SongStorageService
      _storageService =
      SongStorageService.instance;

  late final TextEditingController
      _titleController;

  late final TextEditingController
      _artistController;

  late final TextEditingController
      _albumIdController;

  late final TextEditingController
      _durationController;

  late final TextEditingController
      _bpmController;

  late final TextEditingController
      _energyController;

  late final TextEditingController
      _danceabilityController;

  late final TextEditingController
      _valenceController;

  late final TextEditingController
      _subgenreController;

  String? _audioPath;
  String? _coverPath;

  String? _audioFileName;
  String? _coverFileName;

  bool _isSaving = false;
  bool _isPickingAudio = false;
  bool _isPickingCover = false;

  bool get _isEdit =>
      widget.song != null;

  @override
  void initState() {
    super.initState();

    final song = widget.song;

    _titleController =
        TextEditingController(
      text: song?.title ?? '',
    );

    _artistController =
        TextEditingController(
      text: song?.artist ?? '',
    );

    _albumIdController =
        TextEditingController(
      text: song?.albumId ?? '',
    );

    _durationController =
        TextEditingController(
      text: song == null
          ? ''
          : song.duration.toString(),
    );

    _bpmController =
        TextEditingController(
      text:
          song?.bpm?.toString() ?? '',
    );

    _energyController =
        TextEditingController(
      text:
          song?.energy?.toString() ?? '',
    );

    _danceabilityController =
        TextEditingController(
      text:
          song?.danceability
                  ?.toString() ??
              '',
    );

    _valenceController =
        TextEditingController(
      text:
          song?.valence?.toString() ?? '',
    );

    _subgenreController =
        TextEditingController(
      text:
          song?.subgenre ?? '',
    );

    _audioPath =
        song?.audioUrl;

    _coverPath =
        song?.coverUrl;

    _audioFileName =
        song?.audioUrl;

    _coverFileName =
        song?.coverUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumIdController.dispose();
    _durationController.dispose();
    _bpmController.dispose();
    _energyController.dispose();
    _danceabilityController.dispose();
    _valenceController.dispose();
    _subgenreController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    setState(() {
      _isPickingAudio = true;
    });

    try {
      final files =
          await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'm4a',
          'wav',
          'aac',
          'ogg',
        ],
      );

      if (files.isEmpty) {
        return;
      }

      final file = files.first;

      final bytes =
          await file.readAsBytes();

      final path =
          await _storageService.uploadAudio(
        fileName: file.name,
        bytes: bytes,
      );

      if (!mounted) return;

      setState(() {
        _audioPath = path;
        _audioFileName =
            file.name;
      });
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Gagal memilih/upload audio: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingAudio = false;
        });
      }
    }
  }

  Future<void> _pickCover() async {
    setState(() {
      _isPickingCover = true;
    });

    try {
      final files =
          await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
      );

      if (files.isEmpty) {
        return;
      }

      final file = files.first;

      final bytes =
          await file.readAsBytes();

      final path =
          await _storageService.uploadCover(
        fileName: file.name,
        bytes: bytes,
      );

      if (!mounted) return;

      setState(() {
        _coverPath = path;
        _coverFileName =
            file.name;
      });
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Gagal memilih/upload cover: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingCover = false;
        });
      }
    }
  }

  double? _parseDouble(
    String value,
  ) {
    final trimmed =
        value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return double.tryParse(
      trimmed,
    );
  }

  bool _isValidFeature(
    double? value,
  ) {
    if (value == null) {
      return true;
    }

    return value >= 0 &&
        value <= 1;
  }

  String? _emptyToNull(
    String value,
  ) {
    final trimmed =
        value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  Future<void> _save() async {
    final title =
        _titleController.text.trim();

    final artist =
        _artistController.text.trim();

    final duration =
        int.tryParse(
      _durationController.text
          .trim(),
    );

    if (title.isEmpty ||
        artist.isEmpty ||
        _audioPath == null ||
        _audioPath!.isEmpty ||
        duration == null ||
        duration < 0) {
      _showError(
        'Title, artist, audio, dan duration wajib diisi.',
      );
      return;
    }

    final energy =
        _parseDouble(
      _energyController.text,
    );

    final danceability =
        _parseDouble(
      _danceabilityController.text,
    );

    final valence =
        _parseDouble(
      _valenceController.text,
    );

    final bpm =
        _parseDouble(
      _bpmController.text,
    );

    if (!_isValidFeature(
          energy,
        ) ||
        !_isValidFeature(
          danceability,
        ) ||
        !_isValidFeature(
          valence,
        )) {
      _showError(
        'Energy, danceability, dan valence harus antara 0 dan 1.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEdit) {
        await widget.songService
            .updateSong(
          id: widget.song!.id,
          title: title,
          artist: artist,
          albumId:
              _emptyToNull(
            _albumIdController.text,
          ),
          audioUrl: _audioPath!,
          coverUrl: _coverPath,
          duration: duration,
          bpm: bpm,
          energy: energy,
          danceability:
              danceability,
          valence: valence,
          subgenre:
              _emptyToNull(
            _subgenreController.text,
          ),
        );
      } else {
        await widget.songService
            .createSong(
          title: title,
          artist: artist,
          albumId:
              _emptyToNull(
            _albumIdController.text,
          ),
          audioUrl: _audioPath!,
          coverUrl: _coverPath,
          duration: duration,
          bpm: bpm,
          energy: energy,
          danceability:
              danceability,
          valence: valence,
          subgenre:
              _emptyToNull(
            _subgenreController.text,
          ),
        );
      }

      if (!mounted) return;

      Navigator.of(context)
          .pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        'Gagal menyimpan lagu: $error',
      );
    }
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  InputDecoration _decoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      border:
          const OutlineInputBorder(),
    );
  }

  Widget _buildFileButton({
    required String label,
    required String? fileName,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed:
              isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Icon(icon),
          label: Text(
            isLoading
                ? 'Uploading...'
                : label,
          ),
        ),
        if (fileName != null &&
            fileName.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 6,
            ),
            child: Text(
              fileName,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEdit
            ? 'Edit Lagu'
            : 'Tambah Lagu',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              TextField(
                controller:
                    _titleController,
                decoration:
                    _decoration(
                  'Title *',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    _artistController,
                decoration:
                    _decoration(
                  'Artist *',
                ),
              ),
              const SizedBox(height: 16),
              _buildFileButton(
                label:
                    'Pilih Audio MP3',
                fileName:
                    _audioFileName,
                icon:
                    Icons.audio_file,
                onPressed:
                    _pickAudio,
                isLoading:
                    _isPickingAudio,
              ),
              const SizedBox(height: 12),
              _buildFileButton(
                label:
                    'Pilih Cover',
                fileName:
                    _coverFileName,
                icon:
                    Icons.image,
                onPressed:
                    _pickCover,
                isLoading:
                    _isPickingCover,
              ),
              const SizedBox(height: 16),
              TextField(
                controller:
                    _durationController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    _decoration(
                  'Duration (detik) *',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    _albumIdController,
                decoration:
                    _decoration(
                  'Album ID',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    _subgenreController,
                decoration:
                    _decoration(
                  'Subgenre',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    _bpmController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    _decoration(
                  'BPM',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    _energyController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    _decoration(
                  'Energy (0-1)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    _danceabilityController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    _decoration(
                  'Danceability (0-1)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    _valenceController,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    _decoration(
                  'Valence (0-1)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ||
                  _isPickingAudio ||
                  _isPickingCover
              ? null
              : () {
                  Navigator.of(context)
                      .pop(false);
                },
          child:
              const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSaving ||
                  _isPickingAudio ||
                  _isPickingCover
              ? null
              : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isEdit
                      ? 'Simpan'
                      : 'Tambah',
                ),
        ),
      ],
    );
  }
}