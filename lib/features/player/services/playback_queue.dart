import '../../music/models/song.dart';

enum PlaybackContext {
  catalog,
  playlist,
  aiRecommendation,
}

enum RepeatMode {
  off,
  one,
  all,
}

class PlaybackQueue {
  PlaybackQueue._();

  static final PlaybackQueue instance =
      PlaybackQueue._();

  List<Song> _queue = [];

  PlaybackContext? _context;

  RepeatMode _repeatMode = RepeatMode.off;

  bool _shuffleEnabled = false;

  final List<int> _sessionHistory = [];

  int _historyCursor = -1;

  int _currentIndex = -1;

  List<Song> get queue =>
      List.unmodifiable(_queue);

  int get currentIndex =>
      _currentIndex;

  PlaybackContext? get context =>
      _context;

  RepeatMode get repeatMode =>
      _repeatMode;

  bool get shuffleEnabled =>
      _shuffleEnabled;

  Song? get currentSong {
    if (_currentIndex < 0 ||
        _currentIndex >= _queue.length) {
      return null;
    }

    return _queue[_currentIndex];
  }

  bool selectSong(Song song) {
    final index = _queue.indexWhere((item) => item.id == song.id);
    if (index < 0) return false;

    _currentIndex = index;

    if (_sessionHistory.isEmpty ||
        _historyCursor < 0 ||
        _sessionHistory[_historyCursor] != index) {
      if (_historyCursor + 1 < _sessionHistory.length) {
        _sessionHistory.removeRange(
          _historyCursor + 1,
          _sessionHistory.length,
        );
      }
      _sessionHistory.add(index);
      _historyCursor = _sessionHistory.length - 1;
    }

    return true;
  }

Song? get nextSong {
  if (_queue.isEmpty) {
    return null;
  }

  final nextIndex =
      _currentIndex + 1;

  if (nextIndex < _queue.length) {
    return _queue[nextIndex];
  }

  if (_repeatMode == RepeatMode.all) {
    return _queue.first;
  }

  return null;
}

  bool get hasNext {
  if (_queue.isEmpty) {
    return false;
  }

  if (_currentIndex + 1 <
      _queue.length) {
    return true;
  }

  return _repeatMode ==
      RepeatMode.all;
}

  bool get hasPrevious {
    return _historyCursor > 0;
  }

  void setQueue({
    required List<Song> songs,
    required int startIndex,
    required PlaybackContext context,
  }) {
    if (songs.isEmpty) {
      clear();
      return;
    }

    if (startIndex < 0 ||
        startIndex >= songs.length) {
      throw ArgumentError(
        'startIndex tidak valid',
      );
    }

    _queue =
        List<Song>.from(songs);

    _currentIndex =
        startIndex;

    _context =
        context;

    _repeatMode =
        RepeatMode.off;

    _shuffleEnabled =
        false;

    _sessionHistory.clear();

    _sessionHistory.add(
      startIndex,
    );

    _historyCursor = 0;
  }

  void setRepeatMode(
    RepeatMode mode,
  ) {
    _repeatMode = mode;
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode =
            RepeatMode.one;
        break;

      case RepeatMode.one:
        _repeatMode =
            RepeatMode.all;
        break;

      case RepeatMode.all:
        _repeatMode =
            RepeatMode.off;
        break;
    }
  }

  void setShuffleEnabled(
    bool enabled,
  ) {
    if (_queue.isEmpty) {
      _shuffleEnabled = false;
      return;
    }

    if (_shuffleEnabled ==
        enabled) {
      return;
    }

    _shuffleEnabled =
        enabled;

    if (enabled) {
      _shuffleQueue();
    }
  }

  void _shuffleQueue() {
    if (_queue.length <= 1) {
      return;
    }

    final current =
        currentSong;

    if (current == null) {
      return;
    }

    final remaining =
        List<Song>.from(_queue);

    remaining.removeAt(
      _currentIndex,
    );

    remaining.shuffle();

    _queue = [
      current,
      ...remaining,
    ];

    _currentIndex = 0;

    // Session dimulai ulang dari
    // lagu yang sedang dimainkan.
    _sessionHistory.clear();

    _sessionHistory.add(0);

    _historyCursor = 0;
  }

  Song? moveNext() {
    // Repeat One tidak membuat
    // history baru karena lagu
    // yang sama diputar ulang.
    if (_repeatMode ==
        RepeatMode.one) {
      return currentSong;
    }

    // Jika sebelumnya menekan Previous,
    // Next dapat kembali ke lagu yang
    // sudah pernah dimainkan.
    if (_historyCursor + 1 <
        _sessionHistory.length) {
      _historyCursor++;

      _currentIndex =
          _sessionHistory[
              _historyCursor];

      return currentSong;
    }

    final nextIndex =
        _currentIndex + 1;

    if (nextIndex <
        _queue.length) {
      _currentIndex =
          nextIndex;

      _sessionHistory.add(
        nextIndex,
      );

      _historyCursor =
          _sessionHistory.length - 1;

      return currentSong;
    }

    // Repeat All:
    // kembali ke awal queue.
    if (_repeatMode ==
        RepeatMode.all) {
      if (_queue.isEmpty) {
        return null;
      }

      _currentIndex = 0;

      _sessionHistory.add(0);

      _historyCursor =
          _sessionHistory.length - 1;

      return currentSong;
    }

    return null;
  }

  Song? movePrevious() {
    if (!hasPrevious) {
      return null;
    }

    _historyCursor--;

    _currentIndex =
        _sessionHistory[
            _historyCursor];

    return currentSong;
  }

  void clear() {
    _queue = [];

    _currentIndex = -1;

    _context = null;

    _repeatMode =
        RepeatMode.off;

    _shuffleEnabled =
        false;

    _sessionHistory.clear();

    _historyCursor = -1;
  }
}