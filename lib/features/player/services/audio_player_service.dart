import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../history/services/listening_history_service.dart';
import '../../music/models/song.dart';
import '../../recommendation/services/recommendation_playback_service.dart';
import 'playback_queue.dart';
import 'shared_audio_player.dart';

class AudioPlayerService {
  AudioPlayerService._() {
    _player.playerStateStream.listen(
      _handlePlayerState,
    );
  }

  static final AudioPlayerService instance =
      AudioPlayerService._();

  final AudioPlayer _player =
      SharedAudioPlayer.instance;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final PlaybackQueue _playbackQueue =
      PlaybackQueue.instance;

  final ListeningHistoryService _historyService =
      ListeningHistoryService.instance;

  final RecommendationPlaybackService
      _recommendationPlaybackService =
      RecommendationPlaybackService.instance;

  String? _currentAudioPath;

  Song? _currentSong;

  final StreamController<Song?>
      _currentSongController =
      StreamController<Song?>.broadcast();

  bool _handlingCompletion = false;

  String? _currentHistoryId;

  final Map<String, _SignedCoverCacheEntry>
      _signedCoverUrlCache = {};

  final Map<String, Future<String>>
      _signedCoverUrlRequests = {};

  AudioPlayer get player => _player;

  Song? get currentSong => _currentSong;

  Stream<Song?> get currentSongStream =>
      _currentSongController.stream;

  Stream<Duration> get positionStream =>
      _player.positionStream;

  Stream<Duration?> get durationStream =>
      _player.durationStream;

  Stream<PlayerState> get playerStateStream =>
      _player.playerStateStream;

  Stream<bool> get playingStream =>
      _player.playingStream;

  Stream<double> get speedStream =>
      _player.speedStream;

  double get speed => _player.speed;

  Future<String> _getSignedAudioUrl(
    String audioPath,
  ) async {
    final path = audioPath.startsWith('audio/')
        ? audioPath.substring('audio/'.length)
        : audioPath;

    return await _supabase.storage
        .from('audio')
        .createSignedUrl(
          path,
          3600,
        );
  }

  Future<String> getSignedCoverUrl(
    String coverPath,
  ) async {
    final path = coverPath.startsWith('covers/')
        ? coverPath.substring('covers/'.length)
        : coverPath;

    final cachedEntry =
        _signedCoverUrlCache[path];

    if (cachedEntry != null &&
        cachedEntry.isValid) {
      return cachedEntry.url;
    }

    final pendingRequest =
        _signedCoverUrlRequests[path];

    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _createSignedCoverUrl(path);

    _signedCoverUrlRequests[path] = request;

    try {
      return await request;
    } finally {
      _signedCoverUrlRequests.remove(path);
    }
  }

  Future<String> _createSignedCoverUrl(
    String path,
  ) async {
    final url = await _supabase.storage
        .from('covers')
        .createSignedUrl(
          path,
          3600,
        );

    _signedCoverUrlCache[path] =
        _SignedCoverCacheEntry(
      url: url,
      expiresAt: DateTime.now().toUtc().add(
            const Duration(minutes: 50),
          ),
    );

    return url;
  }

  Future<void> _finishCurrentHistory({
    required bool completed,
    required bool skipped,
  }) async {
    final historyId = _currentHistoryId;

    if (historyId == null) {
      debugPrint(
        '[HISTORY DEBUG] _finishCurrentHistory() '
        'SKIP - historyId=null '
        'completed=$completed '
        'skipped=$skipped '
        'song=${_currentSong?.title}',
      );

      return;
    }

    debugPrint(
      '[HISTORY DEBUG] _finishCurrentHistory() '
      'START '
      'song=${_currentSong?.title} '
      'historyId=$historyId '
      'position=${_player.position.inSeconds}s '
      'completed=$completed '
      'skipped=$skipped',
    );

    _currentHistoryId = null;

    final durationPlayed =
        _player.position.inSeconds;

    try {
      await _historyService.finishListening(
        historyId: historyId,
        durationPlayed: durationPlayed,
        completed: completed,
        skipped: skipped,
      );

      debugPrint(
        '[HISTORY DEBUG] _finishCurrentHistory() '
        'SUCCESS '
        'song=${_currentSong?.title} '
        'historyId=$historyId '
        'duration=$durationPlayed '
        'completed=$completed '
        'skipped=$skipped',
      );
    } catch (error) {
      debugPrint(
        '[HISTORY DEBUG] _finishCurrentHistory() '
        'ERROR '
        'song=${_currentSong?.title} '
        'historyId=$historyId '
        'error=$error',
      );
    }
  }

  Future<void> _processRecommendationEvent(
    Song? song,
  ) async {
    if (song == null) {
      return;
    }

    try {
      await _recommendationPlaybackService
          .processPlaybackEvent(
        song: song,
      );
    } catch (_) {
      // Error recommendation tidak boleh
      // menghentikan playback.
    }
  }

  Future<void> _finishAndProcessCurrentSong({
    required bool completed,
    required bool skipped,
  }) async {
    final song = _currentSong;

    final historyId = _currentHistoryId;

    if (historyId == null) {
      debugPrint(
        '[HISTORY DEBUG] _finishAndProcessCurrentSong() '
        'SKIP - historyId=null '
        'song=${song?.title} '
        'completed=$completed '
        'skipped=$skipped',
      );

      return;
    }

    debugPrint(
      '[HISTORY DEBUG] _finishAndProcessCurrentSong() '
      'song=${song?.title} '
      'historyId=$historyId '
      'position=${_player.position.inSeconds}s '
      'completed=$completed '
      'skipped=$skipped',
    );

    await _finishCurrentHistory(
      completed: completed,
      skipped: skipped,
    );

    await _processRecommendationEvent(
      song,
    );
  }

  Future<void> _startHistoryForSong(
    Song song,
  ) async {
    try {
      final historyId =
          await _historyService.startListening(
        songId: song.id,
      );

      _currentHistoryId = historyId;

      debugPrint(
        '[HISTORY DEBUG] START HISTORY '
        'song=${song.title} '
        'historyId=$historyId',
      );
    } catch (error) {
      debugPrint(
        '[HISTORY DEBUG] START HISTORY ERROR '
        'song=${song.title} '
        'error=$error',
      );
    }
  }

  Future<void> playSong(Song song) async {
    final audioPath = song.audioUrl;

    debugPrint(
      '[HISTORY DEBUG] playSong() '
      'song=${song.title} '
      'historyId=$_currentHistoryId '
      'position=${_player.position.inSeconds}s '
      'processingState=${_player.processingState}',
    );

    // Lagu yang sama masih loaded.
    //
    // Jika sebelumnya hanya di-pause,
    // jangan membuat history baru.
    if (_currentAudioPath == audioPath &&
        _player.processingState !=
            ProcessingState.completed) {
      _currentSong = song;

      _currentSongController.add(
        _currentSong,
      );

      await _player.play();

      return;
    }

    // Jika ada history dari sesi sebelumnya,
    // selesaikan sebagai skipped.
    if (_currentHistoryId != null) {
      debugPrint(
        '[HISTORY DEBUG] playSong() '
        'will finish previous history as SKIPPED '
        'song=${_currentSong?.title} '
        'historyId=$_currentHistoryId '
        'position=${_player.position.inSeconds}s',
      );

      await _finishAndProcessCurrentSong(
        completed: false,
        skipped: true,
      );
    }

    final signedUrl =
        await _getSignedAudioUrl(
      audioPath,
    );

    await _player.setUrl(
      signedUrl,
    );

    _currentAudioPath = audioPath;

    _currentSong = song;

    _currentSongController.add(
      _currentSong,
    );

    await _startHistoryForSong(song);

    await _player.play();
  }

  Future<void> _handlePlayerState(
    PlayerState state,
  ) async {
    if (state.processingState !=
        ProcessingState.completed) {
      return;
    }

    debugPrint(
      '[HISTORY DEBUG] COMPLETED STATE '
      'song=${_currentSong?.title} '
      'historyId=$_currentHistoryId '
      'position=${_player.position.inSeconds}s',
    );

    if (_handlingCompletion) {
      debugPrint(
        '[HISTORY DEBUG] COMPLETED STATE '
        'IGNORED - already handling completion',
      );

      return;
    }

    _handlingCompletion = true;

    try {
      final completedSong = _currentSong;

      // Lagu selesai secara normal.
      //
      // History difinalisasi sebagai completed.
      debugPrint(
        '[HISTORY DEBUG] COMPLETION HANDLER '
        'FINISH AS COMPLETED '
        'song=${completedSong?.title} '
        'historyId=$_currentHistoryId '
        'position=${_player.position.inSeconds}s',
      );

      await _finishAndProcessCurrentSong(
        completed: true,
        skipped: false,
      );

      final repeatMode =
          _playbackQueue.repeatMode;

      // Repeat One.
      if (repeatMode == RepeatMode.one) {
        debugPrint(
          '[HISTORY DEBUG] REPEAT ONE '
          'song=${completedSong?.title}',
        );

        await _player.seek(
          Duration.zero,
        );

        await _player.play();

        if (completedSong != null) {
          await _startHistoryForSong(
            completedSong,
          );
        }

        return;
      }

      // Ambil lagu berikutnya dari
      // playback session history / queue.
      final nextSong =
          _playbackQueue.moveNext();

      debugPrint(
        '[HISTORY DEBUG] COMPLETION NEXT SONG '
        'current=${completedSong?.title} '
        'next=${nextSong?.title}',
      );

      if (nextSong != null) {
        await playSong(nextSong);
      }
    } catch (error) {
      debugPrint(
        '[HISTORY DEBUG] COMPLETION HANDLER ERROR '
        'error=$error',
      );
    } finally {
      _handlingCompletion = false;
    }
  }

  Future<void> play(
    String audioPath,
  ) async {
    if (_currentAudioPath == audioPath &&
        _player.processingState ==
            ProcessingState.completed) {
      await _player.seek(
        Duration.zero,
      );

      await _player.play();

      return;
    }

    if (_currentAudioPath == audioPath) {
      await _player.play();

      return;
    }

    final signedUrl =
        await _getSignedAudioUrl(
      audioPath,
    );

    await _player.setUrl(
      signedUrl,
    );

    _currentAudioPath = audioPath;

    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();

    final historyId =
        _currentHistoryId;

    debugPrint(
      '[HISTORY DEBUG] pause() '
      'song=${_currentSong?.title} '
      'historyId=$historyId '
      'position=${_player.position.inSeconds}s',
    );

    if (historyId == null) {
      return;
    }

    try {
      await _historyService.finishListening(
        historyId: historyId,
        durationPlayed:
            _player.position.inSeconds,
        completed: false,
        skipped: false,
      );

      debugPrint(
        '[HISTORY DEBUG] pause() '
        'UPDATED '
        'historyId=$historyId '
        'duration=${_player.position.inSeconds}s',
      );
    } catch (error) {
      debugPrint(
        '[HISTORY DEBUG] pause() ERROR '
        'historyId=$historyId '
        'error=$error',
      );
    }
  }

  Future<void> resume() async {
    debugPrint(
      '[HISTORY DEBUG] resume() '
      'song=${_currentSong?.title} '
      'historyId=$_currentHistoryId',
    );

    await _player.play();
  }

  Future<void> stop() async {
    debugPrint(
      '[HISTORY DEBUG] stop() '
      'song=${_currentSong?.title} '
      'historyId=$_currentHistoryId '
      'position=${_player.position.inSeconds}s',
    );

    await _finishAndProcessCurrentSong(
      completed: false,
      skipped: true,
    );

    await _player.stop();
  }

  Future<void> playNext() async {
    debugPrint(
      '[HISTORY DEBUG] playNext() '
      'song=${_currentSong?.title} '
      'historyId=$_currentHistoryId '
      'position=${_player.position.inSeconds}s',
    );

    if (_handlingCompletion) {
      debugPrint(
        '[HISTORY DEBUG] playNext() '
        'IGNORED - completion sedang diproses',
      );

      return;
    }

    final nextSong =
        _playbackQueue.moveNext();

    if (nextSong == null) {
      debugPrint(
        '[HISTORY DEBUG] playNext() '
        'NO NEXT SONG',
      );

      return;
    }

    await _finishAndProcessCurrentSong(
      completed: false,
      skipped: true,
    );

    await playSong(nextSong);
  }

  Future<void> playPrevious() async {
    debugPrint(
      '[HISTORY DEBUG] playPrevious() '
      'song=${_currentSong?.title} '
      'historyId=$_currentHistoryId '
      'position=${_player.position.inSeconds}s',
    );

    if (_handlingCompletion) {
      debugPrint(
        '[HISTORY DEBUG] playPrevious() '
        'IGNORED - completion sedang diproses',
      );

      return;
    }

    final previousSong =
        _playbackQueue.movePrevious();

    if (previousSong == null) {
      debugPrint(
        '[HISTORY DEBUG] playPrevious() '
        'NO PREVIOUS SONG',
      );

      return;
    }

    await _finishAndProcessCurrentSong(
      completed: false,
      skipped: true,
    );

    await playSong(previousSong);
  }

  Future<void> seek(
    Duration position,
  ) async {
    await _player.seek(
      position,
    );
  }

  Future<void> setSpeed(double speed) async {
    final clampedSpeed = speed.clamp(0.5, 3.0).toDouble();
    final snappedSpeed =
        (clampedSpeed * 20).round() / 20;

    await _player.setSpeed(snappedSpeed);
  }

  Future<void> clearForLogout() async {
  debugPrint(
    '[LOGOUT AUDIO] Membersihkan audio session sebelum logout',
  );

  // Jika lagu masih sedang dimainkan, simpan history terakhir
  // sebagai belum selesai dan bukan skipped.
  if (_currentHistoryId != null &&
      _player.playing) {
    await _finishCurrentHistory(
      completed: false,
      skipped: false,
    );
  } else {
    // Jika sebelumnya sudah pause, history biasanya sudah
    // diperbarui oleh pause().
    _currentHistoryId = null;
  }

  // Hentikan player tanpa menggunakan stop(), karena stop()
  // mempunyai logic "skipped".
  await _player.stop();

  // Bersihkan state lagu aktif.
  _currentAudioPath = null;
  _currentSong = null;

  // Bersihkan playback session akun sebelumnya.
  _playbackQueue.clear();

  // Reset completion guard.
  _handlingCompletion = false;

  // Beritahu seluruh listener bahwa tidak ada lagu aktif.
  _currentSongController.add(null);

  debugPrint(
    '[LOGOUT AUDIO] Audio session berhasil dibersihkan',
  );
}

  Future<void> dispose() async {
    _signedCoverUrlCache.clear();
    _signedCoverUrlRequests.clear();

    await _currentSongController.close();

    await _player.dispose();
  }
}

class _SignedCoverCacheEntry {
  final String url;
  final DateTime expiresAt;

  const _SignedCoverCacheEntry({
    required this.url,
    required this.expiresAt,
  });

  bool get isValid =>
      DateTime.now().toUtc().isBefore(
        expiresAt,
      );
}