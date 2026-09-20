import '../../music/models/song.dart';

class ProgressiveRecommendationService {
  ProgressiveRecommendationService._();

  static final ProgressiveRecommendationService instance =
      ProgressiveRecommendationService._();

  static const int maxRecommendations = 10;

  List<Song> updateRecommendations({
    required List<Song> currentRecommendations,
    required List<Song> candidates,
    required Map<String, double> scores,
  }) {
    final orderedSongs =
        <Song>[];

    // Masukkan cache lama terlebih dahulu.
    //
    // Urutan ini penting untuk stable tie:
    // jika dua lagu memiliki score sama,
    // lagu yang lebih dulu ada tetap berada
    // di depan.
    for (final song
        in currentRecommendations) {
      if (!orderedSongs.any(
        (item) => item.id == song.id,
      )) {
        orderedSongs.add(song);
      }
    }

    // Tambahkan kandidat baru.
    //
    // Lagu yang sudah ada tidak ditambahkan lagi,
    // tetapi score terbarunya tetap akan digunakan
    // ketika seluruh list di-ranking ulang.
    for (final candidate in candidates) {
      if (orderedSongs.any(
        (song) => song.id == candidate.id,
      )) {
        continue;
      }

      orderedSongs.add(candidate);
    }

    // Ranking ulang seluruh lagu berdasarkan
    // score terbaru.
    //
    // Kita menggunakan insertion secara manual,
    // bukan List.sort(), supaya stable tie benar-benar
    // terjaga.
    final rankedSongs =
        <Song>[];

    for (final song in orderedSongs) {
      final songScore =
          scores[song.id] ?? 0;

      var insertIndex =
          rankedSongs.length;

      for (var index = 0;
          index < rankedSongs.length;
          index++) {
        final currentSong =
            rankedSongs[index];

        final currentScore =
            scores[currentSong.id] ?? 0;

        // Hanya score yang lebih tinggi yang
        // boleh mendahului lagu sebelumnya.
        //
        // Jika sama, insert setelah lagu lama.
        if (songScore > currentScore) {
          insertIndex = index;
          break;
        }
      }

      rankedSongs.insert(
        insertIndex,
        song,
      );
    }

    // Cache selalu maksimal 10 lagu.
    if (rankedSongs.length >
        maxRecommendations) {
      return rankedSongs
          .take(maxRecommendations)
          .toList();
    }

    return rankedSongs;
  }
}