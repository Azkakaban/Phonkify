import 'package:flutter/material.dart';

import '../services/listening_behavior_service.dart';

class ListeningBehaviorTestPage extends StatefulWidget {
  const ListeningBehaviorTestPage({
    super.key,
  });

  @override
  State<ListeningBehaviorTestPage> createState() =>
      _ListeningBehaviorTestPageState();
}

class _ListeningBehaviorTestPageState
    extends State<ListeningBehaviorTestPage> {
  final _service =
      ListeningBehaviorService.instance;

  bool _isLoading = false;
  String? _error;
  List<ListeningBehavior> _behaviors = [];

  Future<void> _loadBehaviors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final behaviors =
          await _service.getListeningBehaviors();

      if (!mounted) return;

      setState(() {
        _behaviors = behaviors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBehaviors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Listening Behavior Test',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_behaviors.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada listening history.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBehaviors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _behaviors.length,
        itemBuilder: (context, index) {
          final behavior =
              _behaviors[index];

          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    behavior.song.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    behavior.song.artist,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Duration Played: '
                    '${behavior.durationPlayed} detik',
                  ),
                  Text(
                    'Completed: '
                    '${behavior.completed}',
                  ),
                  Text(
                    'Skipped: '
                    '${behavior.skipped}',
                  ),
                  Text(
                    'Started At: '
                    '${behavior.startedAt}',
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