import 'package:supabase_flutter/supabase_flutter.dart';

class UserMusicProfileService {
  UserMusicProfileService._();

  static final UserMusicProfileService instance =
      UserMusicProfileService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  String get _userId {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    return user.id;
  }

  Future<void> updateProfile() async {
    final userId = _userId;

    final results = await Future.wait([
      _getListeningHistory(),
      _getFavorites(),
      _getPlaylistSongs(),
      _getOnboardingPreferences(),
    ]);

final listeningHistory = results[0];

final favorites = results[1];

final playlistSongs = results[2];

final onboardingPreferences = results[3];

    final signals = <_MusicSignal>[];

    for (final item in listeningHistory) {
      final song = item['songs'];

      if (song is! Map) {
        continue;
      }

      final signalWeight =
          _calculateListeningWeight(item);

      if (signalWeight <= 0) {
        continue;
      }

      signals.add(
        _MusicSignal(
          song: Map<String, dynamic>.from(song),
          weight: signalWeight,
        ),
      );
    }

    for (final item in favorites) {
      final song = item['songs'];

      if (song is! Map) {
        continue;
      }

      signals.add(
        _MusicSignal(
          song: Map<String, dynamic>.from(song),
          weight: 5,
        ),
      );
    }

    for (final item in playlistSongs) {
      final song = item['songs'];

      if (song is! Map) {
        continue;
      }

      signals.add(
        _MusicSignal(
          song: Map<String, dynamic>.from(song),
          weight: 4,
        ),
      );
    }

    for (final item in onboardingPreferences) {
      final song = item['songs'];

      if (song is! Map) {
        continue;
      }

      signals.add(
        _MusicSignal(
          song: Map<String, dynamic>.from(song),
          weight: 2,
        ),
      );
    }

    if (signals.isEmpty) {
      await _upsertProfile(
        userId: userId,
        preferredSubgenres: [],
        preferredEnergy: null,
        preferredBpmMin: null,
        preferredBpmMax: null,
        favoriteArtists: [],
        favoriteFeatures: {},
      );

      return;
    }

    final preferredSubgenres =
        _calculatePreferredSubgenres(signals);

    final preferredArtists =
        _calculateFavoriteArtists(signals);

    final preferredEnergy =
        _calculateWeightedAverage(
      signals: signals,
      field: 'energy',
    );

    final preferredBpm =
        _calculateBpmRange(signals);

    final favoriteFeatures =
        _calculateFavoriteFeatures(signals);

    await _upsertProfile(
      userId: userId,
      preferredSubgenres: preferredSubgenres,
      preferredEnergy: preferredEnergy,
      preferredBpmMin: preferredBpm['min'],
      preferredBpmMax: preferredBpm['max'],
      favoriteArtists: preferredArtists,
      favoriteFeatures: favoriteFeatures,
    );
  }

  double _calculateListeningWeight(
    Map<String, dynamic> item,
  ) {
    final completed =
        item['completed'] == true;

    final skipped =
        item['skipped'] == true;

    final durationPlayed =
        (item['duration_played'] as num?)?.toDouble() ?? 0;

    final songData = item['songs'];

    if (songData is! Map) {
      return 0;
    }

    final duration =
        (songData['duration'] as num?)?.toDouble() ?? 0;

    double weight = 0;

    if (completed) {
      weight += 3;
    }

    if (duration > 0) {
      final progress =
          durationPlayed / duration;

      if (progress >= 0.5) {
        weight += 2;
      } else if (progress < 0.2) {
        weight -= 1;
      }
    }

    if (skipped) {
      weight -= 3;
    }

    return weight;
  }

  List<String> _calculatePreferredSubgenres(
    List<_MusicSignal> signals,
  ) {
    final scores =
        <String, double>{};

    for (final signal in signals) {
      final value =
          signal.song['subgenre'];

      if (value == null) {
        continue;
      }

      final subgenre =
          value.toString().trim();

      if (subgenre.isEmpty) {
        continue;
      }

      final key =
          subgenre.toLowerCase();

      scores[key] =
          (scores[key] ?? 0) + signal.weight;
    }

    final entries =
        scores.entries.toList()
          ..sort(
            (a, b) =>
                b.value.compareTo(a.value),
          );

    return entries
        .take(5)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> _calculateFavoriteArtists(
    List<_MusicSignal> signals,
  ) {
    final scores =
        <String, double>{};

    for (final signal in signals) {
      final value =
          signal.song['artist'];

      if (value == null) {
        continue;
      }

      final artist =
          value.toString().trim();

      if (artist.isEmpty) {
        continue;
      }

      scores[artist] =
          (scores[artist] ?? 0) + signal.weight;
    }

    final entries =
        scores.entries.toList()
          ..sort(
            (a, b) =>
                b.value.compareTo(a.value),
          );

    return entries
        .take(10)
        .map((entry) => entry.key)
        .toList();
  }

  double? _calculateWeightedAverage({
    required List<_MusicSignal> signals,
    required String field,
  }) {
    double weightedTotal = 0;
    double totalWeight = 0;

    for (final signal in signals) {
      final value =
          (signal.song[field] as num?)?.toDouble();

      if (value == null) {
        continue;
      }

      weightedTotal +=
          value * signal.weight;

      totalWeight += signal.weight;
    }

    if (totalWeight <= 0) {
      return null;
    }

    return weightedTotal / totalWeight;
  }

  Map<String, double?> _calculateBpmRange(
    List<_MusicSignal> signals,
  ) {
    final weightedBpms =
        <_WeightedBpm>[];

    for (final signal in signals) {
      final bpm =
          (signal.song['bpm'] as num?)?.toDouble();

      if (bpm == null || bpm <= 0) {
        continue;
      }

      weightedBpms.add(
        _WeightedBpm(
          bpm: bpm,
          weight: signal.weight,
        ),
      );
    }

    if (weightedBpms.isEmpty) {
      return {
        'min': null,
        'max': null,
      };
    }

    weightedBpms.sort(
      (a, b) => a.bpm.compareTo(b.bpm),
    );

    final weightedAverage =
        _calculateWeightedBpmAverage(
      weightedBpms,
    );

    final minBpm =
        (weightedAverage - 30)
            .clamp(
              0,
              double.infinity,
            )
            .toDouble();

    final maxBpm =
        weightedAverage + 30;

    return {
      'min': minBpm,
      'max': maxBpm,
    };
  }

  double _calculateWeightedBpmAverage(
    List<_WeightedBpm> values,
  ) {
    double weightedTotal = 0;
    double totalWeight = 0;

    for (final item in values) {
      weightedTotal +=
          item.bpm * item.weight;

      totalWeight += item.weight;
    }

    if (totalWeight <= 0) {
      return 0;
    }

    return weightedTotal / totalWeight;
  }

  Map<String, double> _calculateFavoriteFeatures(
    List<_MusicSignal> signals,
  ) {
    final result =
        <String, double>{};

    final fields = [
      'energy',
      'danceability',
      'valence',
    ];

    for (final field in fields) {
      final value =
          _calculateWeightedAverage(
        signals: signals,
        field: field,
      );

      if (value != null) {
        result[field] = value;
      }
    }

    final bpm =
        _calculateWeightedAverage(
      signals: signals,
      field: 'bpm',
    );

    if (bpm != null) {
      result['bpm'] = bpm;
    }

    return result;
  }

  Future<List<Map<String, dynamic>>>
      _getListeningHistory() async {
    final response = await _supabase
        .from('listening_history')
        .select('''
          id,
          song_id,
          duration_played,
          completed,
          skipped,
          songs(*)
        ''')
        .eq(
          'user_id',
          _userId,
        )
        .order(
          'started_at',
          ascending: false,
        );

    return (response as List)
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _getFavorites() async {
    final response = await _supabase
        .from('favorites')
        .select('''
          song_id,
          songs(*)
        ''')
        .eq(
          'user_id',
          _userId,
        );

    return (response as List)
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _getPlaylistSongs() async {
    final response = await _supabase
        .from('playlist_songs')
        .select('''
          song_id,
          songs(*),
          playlists!inner(user_id)
        ''')
        .eq(
          'playlists.user_id',
          _userId,
        );

    return (response as List)
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>>
      _getOnboardingPreferences() async {
    final response = await _supabase
        .from('user_preferences')
        .select('''
          song_id,
          songs(*)
        ''')
        .eq(
          'user_id',
          _userId,
        );

    return (response as List)
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }

  Future<void> _upsertProfile({
    required String userId,
    required List<String> preferredSubgenres,
    required double? preferredEnergy,
    required double? preferredBpmMin,
    required double? preferredBpmMax,
    required List<String> favoriteArtists,
    required Map<String, double> favoriteFeatures,
  }) async {
    await _supabase
        .from('user_music_profile')
        .upsert({
      'user_id': userId,
      'preferred_subgenres':
          preferredSubgenres,
      'preferred_energy':
          preferredEnergy,
      'preferred_bpm_min':
          preferredBpmMin,
      'preferred_bpm_max':
          preferredBpmMax,
      'favorite_artists':
          favoriteArtists,
      'favorite_features':
          favoriteFeatures,
      'embedding': null,
      'updated_at':
          DateTime.now()
              .toUtc()
              .toIso8601String(),
    });
  }
}

class _MusicSignal {
  final Map<String, dynamic> song;
  final double weight;

  const _MusicSignal({
    required this.song,
    required this.weight,
  });
}

class _WeightedBpm {
  final double bpm;
  final double weight;

  const _WeightedBpm({
    required this.bpm,
    required this.weight,
  });
}