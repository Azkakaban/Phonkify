import 'package:flutter/material.dart';

import 'models/song.dart';
import 'services/song_service.dart';

class TestMusicPage extends StatefulWidget {
  const TestMusicPage({super.key});

  @override
  State<TestMusicPage> createState() => _TestMusicPageState();
}

class _TestMusicPageState extends State<TestMusicPage> {
  final SongService _songService = SongService();

  List<Song> _songs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _songService.getSongs();

      if (!mounted) return;

      setState(() {
        _songs = songs;
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
        appBar: AppBar(title: const Text('Test Music')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Gagal mengambil lagu:\n$_errorMessage',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Music'),
      ),
      body: ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];

          return ListTile(
            title: Text(song.title),
            subtitle: Text(song.artist),
            trailing: Text(song.subgenre ?? '-'),
          );
        },
      ),
    );
  }
}