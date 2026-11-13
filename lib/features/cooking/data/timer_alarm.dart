import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Avisa que um temporizador terminou (vibração + som).
abstract interface class TimerAlarm {
  Future<void> ring();
  void dispose();
}

class DeviceTimerAlarm implements TimerAlarm {
  AudioPlayer? _player;

  @override
  Future<void> ring() async {
    try {
      await HapticFeedback.vibrate();
      final player = _player ??= AudioPlayer();
      await player.play(AssetSource('sounds/timer.wav'));
    } on Exception {
      // Sem vibração/som neste aparelho: o aviso visual continua.
    }
  }

  @override
  void dispose() => _player?.dispose();
}
