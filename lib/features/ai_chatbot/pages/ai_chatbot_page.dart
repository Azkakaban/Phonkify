import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../music/services/song_service.dart';
import '../../player/services/audio_player_service.dart';

class AiChatbotPage extends StatefulWidget {
  const AiChatbotPage({super.key});

  @override
  State<AiChatbotPage> createState() => _AiChatbotPageState();
}

class _AiChatbotPageState extends State<AiChatbotPage> {
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController =
      ScrollController();

  final SongService _songService = SongService();

  // Conversation stays in memory for the current app session.
  // It is shared across page instances and resets when the app process ends.
  static final List<Map<String, dynamic>> _sessionMessages = [];
  late final List<Map<String, dynamic>> _messages = _sessionMessages;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (_messages.isEmpty) {
      _messages.add({
        'role': 'assistant',
        'content':
            'Halo! Saya Phonkify AI. Saya siap membantu kamu menemukan musik phonk, memberikan rekomendasi lagu, dan menemani perjalanan musikmu.',
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || _isLoading) return;

    _messageController.clear();

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
      });

      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Mengambil katalog lagu dari Supabase
      final songs = await _songService.getSongs();

      // Mengirim maksimal 50 lagu dengan informasi yang diperlukan AI
      final songCatalog = songs.take(50).map((song) {
        return {
          'title': song.title,
          'artist': song.artist,
          'subgenre': song.subgenre,
          'bpm': song.bpm,
          'energy': song.energy,
          'valence': song.valence,
          'duration': song.duration,
        };
      }).toList();

      // Mengambil lagu yang sedang diputar dari AudioPlayerService.
      final currentSong = AudioPlayerService.instance.currentSong;

      final nowPlaying = currentSong == null
          ? null
          : {
              'title': currentSong.title,
              'artist': currentSong.artist,
              'subgenre': currentSong.subgenre,
              'bpm': currentSong.bpm,
              'energy': currentSong.energy,
              'danceability': currentSong.danceability,
              'valence': currentSong.valence,
              'duration': currentSong.duration,
            };

      // Mengirim pesan, katalog, dan lagu yang sedang diputar.
      final response = await Supabase.instance.client.functions.invoke(
        'phonkify-ai',
        body: {
          'message': message,
          'songs': songCatalog,
          'nowPlaying': nowPlaying,
        },
      );

      final reply = response.data['reply'];

      if (reply == null) {
        throw Exception('Respons AI kosong.');
      }

      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': reply.toString(),
        });

      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Maaf, terjadi kesalahan saat menghubungkan ke Phonkify AI. Silakan coba lagi.',
        });
      });

      debugPrint('Phonkify AI Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.headphones,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: isUser
                    ? null
                    : Border.all(
                        color: AppColors.divider,
                      ),
              ),
              child: Text(
                message['content'] ?? '',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ),

          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !_isLoading,
                textCapitalization:
                    TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about music...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: AppColors.divider,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: AppColors.divider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16,
            ),
            color: AppColors.surface,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.headphones,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phonkify AI',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration:
                                const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            'Music Assistant',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              itemCount:
                  _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading &&
                    index == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.headphones,
                          color: AppColors.primary,
                        ),

                        const SizedBox(width: 12),

                        Text(
                          'Phonkify is thinking...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildMessage(_messages[index]);
              },
            ),
          ),

          _buildInput(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
