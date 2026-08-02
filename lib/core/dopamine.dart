import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../core/models.dart';
import '../core/state.dart';

/// Dopamine Mode: instant micro-rewards for every healthy action.
/// Haptics + sound + XP bursts are fired by the game controller; this
/// class turns them into device feedback.
class Dopamine {
  Dopamine._();
  static final Dopamine instance = Dopamine._();

  final _player = AudioPlayer();
  bool _soundOn = true;
  bool _hapticsOn = true;
  bool _dopamineOn = true;

  void sync(AppSettings s) {
    _soundOn = s.sounds;
    _hapticsOn = s.haptics;
    _dopamineOn = s.dopamineMode;
  }

  Future<void> play(GameEvent e) async {
    if (!_dopamineOn) return;
    switch (e.type) {
      case GameEventType.levelUp:
      case GameEventType.boss:
      case GameEventType.milestone:
        await _haptic(HapticFeedback.heavyImpact);
        await _sound('levelup.wav');
      case GameEventType.achievement:
        await _haptic(HapticFeedback.heavyImpact);
        await _sound('achievement.wav');
      case GameEventType.water:
        await _haptic(HapticFeedback.selectionClick);
        await _sound('water.wav');
      case GameEventType.meal:
        await _haptic(HapticFeedback.mediumImpact);
        await _sound('xp.wav');
      case GameEventType.xp:
      case GameEventType.confetti:
      case GameEventType.celebration:
        await _haptic(HapticFeedback.selectionClick);
        await _sound('xp.wav');
      case GameEventType.workout:
        await _haptic(HapticFeedback.mediumImpact);
        await _sound('achievement.wav');
    }
  }

  Future<void> _haptic(Future<void> Function() f) async {
    if (_hapticsOn) {
      try {
        await f();
      } catch (_) {}
    }
  }

  Future<void> _sound(String asset) async {
    if (!_soundOn) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/$asset'));
    } catch (_) {}
  }
}
