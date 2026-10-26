import 'package:supabase_flutter/supabase_flutter.dart';

import '../../music/models/song.dart';

class ListeningBehaviorService {
  ListeningBehaviorService._();

  static final ListeningBehaviorService instance =
      ListeningBehaviorService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  String get _userId {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'User belum login',
      );
    }

    return user.id;
  }

  Future<List<ListeningBehavior>> getListeningBehaviors({
    int limit = 100,
  }) async {
    if (limit <= 0) {
      return [];
    }

    final response = await _supabase
        .from('listening_history')
        .select('''
          id,
          song_id,
          started_at,
          duration_played,
          completed,
          skipped,
          created_at,
          songs(*)
        ''')
        .eq(
          'user_id',
          _userId,
        )
        .order(
          'started_at',
          ascending: false,
        )
        .limit(limit);

    final behaviors =
        <ListeningBehavior>[];

    for (final item in response as List) {
      final map =
          Map<String, dynamic>.from(item);

      final songData =
          map['songs'];

      if (songData is! Map) {
        continue;
      }

      try {
        final song =
            Song.fromMap(
          Map<String, dynamic>.from(
            songData,
          ),
        );

        behaviors.add(
          ListeningBehavior(
            id: map['id'] as String,
            song: song,
            startedAt: DateTime.parse(
              map['started_at'] as String,
            ),
            durationPlayed:
                (map['duration_played'] as num?)
                        ?.toInt() ??
                    0,
            completed:
                map['completed'] as bool? ??
                    false,
            skipped:
                map['skipped'] as bool? ??
                    false,
            createdAt:
                map['created_at'] != null
                    ? DateTime.parse(
                        map['created_at']
                            as String,
                      )
                    : null,
          ),
        );
      } catch (_) {
        // Abaikan record yang tidak valid.
      }
    }

    return behaviors;
  }
}

class ListeningBehavior {
  final String id;
  final Song song;
  final DateTime startedAt;
  final int durationPlayed;
  final bool completed;
  final bool skipped;
  final DateTime? createdAt;

  const ListeningBehavior({
    required this.id,
    required this.song,
    required this.startedAt,
    required this.durationPlayed,
    required this.completed,
    required this.skipped,
    this.createdAt,
  });
}