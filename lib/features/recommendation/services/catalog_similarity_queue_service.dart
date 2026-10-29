import '../../music/models/song.dart';
import '../../music/services/song_service.dart';
import '../../player/services/playback_queue.dart';
import 'song_similarity_service.dart';

class CatalogSimilarityQueueService {
  CatalogSimilarityQueueService._();

  static final CatalogSimilarityQueueService instance =
      CatalogSimilarityQueueService._();

  final SongService _songService =
      SongService();

  final SongSimilarityService _similarityService =
      SongSimilarityService.instance;

  final PlaybackQueue _playbackQueue =
      PlaybackQueue.instance;

  Future<List<Song>> buildQueue({
    required Song selectedSong,
    int limit = 10,
  }) async {
    final songs =
        await _songService.getSongs();

    if (songs.isEmpty) {
      _playbackQueue.clear();
      return [];
    }

    final queueSongs =
        _similarityService.getSimilarSongs(
      seedSong: selectedSong,
      candidates: songs,
      limit: limit,
    );

    if (queueSongs.isEmpty) {
      _playbackQueue.clear();
      return [];
    }

    _playbackQueue.setQueue(
      songs: queueSongs,
      startIndex: 0,
      context: PlaybackContext.catalog,
    );

    return queueSongs;
  }
}