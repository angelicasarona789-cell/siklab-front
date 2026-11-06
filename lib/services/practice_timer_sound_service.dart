import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class PracticeTimerSoundService {
  static final AudioPlayer _countdownPlayer = AudioPlayer();
  static final AudioPlayer _timeoutPlayer = AudioPlayer();

  static Future<void> playCountdownTick() async {
    try {
      await _countdownPlayer.play(
        AssetSource('audio/countdown_tick.wav'),
        volume: 0.65,
      );
    } catch (error) {
      debugPrint('Could not play practice timer countdown sound: $error');
    }
  }

  static Future<void> playTimeoutRing() async {
    try {
      await _timeoutPlayer.play(
        AssetSource('audio/timeout_ring.wav'),
        volume: 0.8,
      );
    } catch (error) {
      debugPrint('Could not play practice timer timeout sound: $error');
    }
  }
}
