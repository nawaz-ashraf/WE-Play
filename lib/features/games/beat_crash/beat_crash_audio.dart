import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Programmatic sound-effect engine for Beat Crash.
///
/// Generates simple WAV tones at runtime so no asset files are needed.
/// Each sound type uses its own [AudioPlayer] to avoid cut-off.
class BeatCrashAudio {
  final Map<String, AudioPlayer> _players = {};
  bool _soundEnabled = true;
  bool _initialized = false;

  void setSoundEnabled(bool v) => _soundEnabled = v;
  bool get soundEnabled => _soundEnabled;

  Future<void> init() async {
    try {
      for (final key in ['perfect', 'good', 'miss', 'combo']) {
        _players[key] = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      }
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  // ── WAV tone generator ───────────────────────
  Uint8List _generateWav({
    required double frequency,
    required double durationMs,
    required double volume,
    bool envelope = true,
  }) {
    const int sampleRate = 22050;
    final int numSamples = (sampleRate * durationMs / 1000).toInt();
    final Uint8List pcm = Uint8List(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      final double env = envelope
          ? (i < numSamples * 0.1
              ? i / (numSamples * 0.1)
              : 1.0 - (i - numSamples * 0.1) / (numSamples * 0.9))
          : 1.0;
      final sample =
          (sin(2 * pi * frequency * t) * 32767 * volume * env).toInt();
      final clamped = sample.clamp(-32768, 32767);
      pcm[i * 2] = clamped & 0xFF;
      pcm[i * 2 + 1] = (clamped >> 8) & 0xFF;
    }

    // Wrap in WAV header
    final header = ByteData(44);
    header.setUint32(0, 0x52494646, Endian.big); // 'RIFF'
    header.setUint32(4, 36 + pcm.length, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big); // 'WAVE'
    header.setUint32(12, 0x666D7420, Endian.big); // 'fmt '
    header.setUint32(16, 16, Endian.little); // chunk size
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint32(36, 0x64617461, Endian.big); // 'data'
    header.setUint32(40, pcm.length, Endian.little);

    final wav = Uint8List(44 + pcm.length);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, wav.length, pcm);
    return wav;
  }

  Future<void> _playTone(String key, Uint8List wav) async {
    if (!_soundEnabled || !_initialized) return;
    try {
      await _players[key]?.stop();
      await _players[key]?.play(BytesSource(wav));
    } catch (_) {}
  }

  // ── PERFECT hit: bright high tone (880 Hz, 120ms) ─
  Future<void> playPerfect() async {
    HapticFeedback.mediumImpact();
    await _playTone(
      'perfect',
      _generateWav(frequency: 880, durationMs: 120, volume: 0.7),
    );
  }

  // ── GOOD hit: mid tone (660 Hz, 100ms) ────────────
  Future<void> playGood() async {
    HapticFeedback.lightImpact();
    await _playTone(
      'good',
      _generateWav(frequency: 660, durationMs: 100, volume: 0.6),
    );
  }

  // ── MISS: low thud (180 Hz, 200ms) ────────────────
  Future<void> playMiss() async {
    HapticFeedback.heavyImpact();
    await _playTone(
      'miss',
      _generateWav(frequency: 180, durationMs: 200, volume: 0.8),
    );
  }

  // ── COMBO milestone: ascending two-note chord ─────
  Future<void> playCombo(int comboCount) async {
    HapticFeedback.heavyImpact();
    final baseFreq = 440.0 + (comboCount * 40.0).clamp(0.0, 400.0);
    await _playTone(
      'combo',
      _generateWav(frequency: baseFreq, durationMs: 180, volume: 0.9),
    );
    await Future.delayed(const Duration(milliseconds: 80));
    await _playTone(
      'good',
      _generateWav(frequency: baseFreq * 1.25, durationMs: 150, volume: 0.7),
    );
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
  }
}
