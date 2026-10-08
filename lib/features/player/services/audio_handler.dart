import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../favorites/services/favorite_service.dart';
import '../../music/models/song.dart';
import '../services/audio_player_service.dart';
import 'shared_audio_player.dart';

class PhonkifyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  PhonkifyAudioHandler();

  final AudioPlayer _player =
      SharedAudioPlayer.instance;

  final AudioPlayerService _audioPlayerService =
      AudioPlayerService.instance;

  final FavoriteService _favoriteService =
      FavoriteService.instance;

  StreamSubscription<PlayerState>?
      _playerStateSubscription;

  StreamSubscription<Duration>?
      _positionSubscription;

  StreamSubscription<Duration?>?
      _durationSubscription;

  StreamSubscription<bool>?
      _playingSubscription;

  StreamSubscription<Song?>?
      _currentSongSubscription;

  AudioPlayer get player => _player;

  Future<void> initialize() async {
    _playerStateSubscription =
        _player.playerStateStream.listen(
      (state) {
        _publishPlaybackState(
          playing: state.playing,
          processingState:
              _mapProcessingState(
            state.processingState,
          ),
        );
      },
    );

    _positionSubscription =
        _player.positionStream.listen(
      (position) {
        playbackState.add(
          playbackState.value.copyWith(
            updatePosition: position,
            bufferedPosition:
                _player.bufferedPosition,
            speed: _player.speed,
            systemActions: const {
              MediaAction.seek,
            },
          ),
        );
      },
    );

    _durationSubscription =
        _player.durationStream.listen(
      (duration) {
        if (duration == null) {
          return;
        }

        final currentItem =
            mediaItem.value;

        if (currentItem != null) {
          mediaItem.add(
            currentItem.copyWith(
              duration: duration,
            ),
          );
        }

        playbackState.add(
          playbackState.value.copyWith(
            updatePosition:
                _player.position,
            bufferedPosition:
                _player.bufferedPosition,
            speed: _player.speed,
            systemActions: const {
              MediaAction.seek,
            },
          ),
        );
      },
    );

    _playingSubscription =
        _player.playingStream.listen(
      (playing) {
        _publishPlaybackState(
          playing: playing,
          processingState:
              _mapProcessingState(
            _player.processingState,
          ),
        );
      },
    );

    _currentSongSubscription =
        _audioPlayerService.currentSongStream.listen(
      _handleCurrentSong,
    );

    final currentSong =
        _audioPlayerService.currentSong;

    if (currentSong != null) {
      await _handleCurrentSong(
        currentSong,
      );
    }
  }

  List<MediaControl> _buildNotificationControls(
    bool playing,
  ) {
    return [
      MediaControl.skipToPrevious,

      if (playing)
        MediaControl.pause
      else
        MediaControl.play,

      MediaControl.skipToNext,

      MediaControl(
        androidIcon:
            'drawable/ic_close',
        label: 'Tutup',
        action: MediaAction.stop,
      ),
    ];
  }

  void _publishPlaybackState({
    required bool playing,
    required AudioProcessingState processingState,
  }) {
    playbackState.add(
      playbackState.value.copyWith(
        playing: playing,
        processingState:
            processingState,
        controls:
            _buildNotificationControls(
          playing,
        ),
        androidCompactActionIndices: const [
          1,
          2,
          3,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        updatePosition:
            _player.position,
        bufferedPosition:
            _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  Future<void> _handleCurrentSong(
    Song? song,
  ) async {
    if (song == null) {
      return;
    }

    String? artworkUri;

    if (song.coverUrl != null &&
        song.coverUrl!.isNotEmpty) {
      try {
        artworkUri =
            await _audioPlayerService
                .getSignedCoverUrl(
          song.coverUrl!,
        );
      } catch (_) {
        artworkUri = null;
      }
    }

    final duration =
        song.duration > 0
            ? Duration(
                seconds: song.duration,
              )
            : _player.duration;

    mediaItem.add(
      MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        duration: duration,
        artUri: artworkUri == null
            ? null
            : Uri.parse(
                artworkUri,
              ),
      ),
    );

    playbackState.add(
      playbackState.value.copyWith(
        updatePosition:
            _player.position,
        bufferedPosition:
            _player.bufferedPosition,
        speed: _player.speed,
        systemActions: const {
          MediaAction.seek,
        },
      ),
    );
  }

  AudioProcessingState _mapProcessingState(
    ProcessingState state,
  ) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;

      case ProcessingState.loading:
        return AudioProcessingState.loading;

      case ProcessingState.buffering:
        return AudioProcessingState.buffering;

      case ProcessingState.ready:
        return AudioProcessingState.ready;

      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() async {
    await _audioPlayerService.resume();
  }

  @override
  Future<void> pause() async {
    await _audioPlayerService.pause();
  }

  @override
  Future<void> seek(
    Duration position,
  ) async {
    await _audioPlayerService.seek(
      position,
    );
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioPlayerService.setSpeed(speed);

    playbackState.add(
      playbackState.value.copyWith(
        speed: _player.speed,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await _audioPlayerService.stop();

    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState:
            AudioProcessingState.idle,
        systemActions: const {
          MediaAction.seek,
        },
      ),
    );
  }

  @override
  Future<void> skipToNext() async {
    await _audioPlayerService.playNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await _audioPlayerService.playPrevious();
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    debugPrint(
      '[NOTIFICATION ACTION] $name',
    );

    if (name == 'phonkify_favorite') {
      final song =
          _audioPlayerService.currentSong;

      if (song == null) {
        debugPrint(
          '[NOTIFICATION FAVORITE] '
          'currentSong null',
        );
        return;
      }

      try {
        await _favoriteService.toggleFavorite(
          song.id,
        );

        debugPrint(
          '[NOTIFICATION FAVORITE] '
          'Berhasil toggle: ${song.id}',
        );
      } catch (error) {
        debugPrint(
          '[NOTIFICATION FAVORITE] '
          'Error: $error',
        );
      }

      return;
    }

    return super.customAction(
      name,
      extras,
    );
  }

  Future<void> disposeHandler() async {
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playingSubscription?.cancel();
    await _currentSongSubscription?.cancel();
  }
}