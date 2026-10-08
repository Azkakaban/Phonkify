import 'package:just_audio/just_audio.dart';

class SharedAudioPlayer {
  SharedAudioPlayer._();

  static final AudioPlayer instance =
      AudioPlayer();
}