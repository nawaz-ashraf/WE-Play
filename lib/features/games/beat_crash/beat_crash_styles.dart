import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────
class BeatColors {
  static const background    = Color(0xFF0A0A12);
  static const surface       = Color(0xFF13131F);
  static const primary       = Color(0xFF7B61FF);
  static const accent        = Color(0xFF00F5A0);
  static const energy        = Color(0xFFFF3E6C);
  static const warn          = Color(0xFFFFD740);
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);

  // Hit feedback colours
  static const perfect = Color(0xFF00F5A0);
  static const good    = Color(0xFF7B61FF);
  static const miss    = Color(0xFFFF3E6C);

  // Block lane colours (4 lanes)
  static const List<Color> lanes = [
    Color(0xFF7B61FF), // purple
    Color(0xFF00F5A0), // green
    Color(0xFFFF3E6C), // pink
    Color(0xFFFFD740), // amber
  ];
}

// ─────────────────────────────────────────────
//  GAME CONSTANTS
// ─────────────────────────────────────────────
class BeatConst {
  static const int    bpm            = 120;
  static const double sessionSeconds = 30.0;
  static const int    lanes          = 4;

  // Hit windows (seconds from target zone centre)
  static const double perfectWindow = 0.10;
  static const double goodWindow    = 0.20;

  // Block travel time (seconds to fall from top to target)
  static const double fallDuration  = 1.2;

  // Score
  static const int perfectScore = 100;
  static const int goodScore    = 50;

  // Combo thresholds → multiplier
  static const List<int>    comboThresholds   = [5,  10, 20, 30,  50];
  static const List<double> comboMultipliers  = [2,  3,  5,  8,   10];

  // Target zone height from bottom (% of screen)
  static const double targetZoneFromBottom = 0.18;
  static const double targetZoneHeight     = 0.07;

  // Block size
  static const double blockWidth  = 0.18; // fraction of screen width
  static const double blockHeight = 48.0; // px
}

// ─────────────────────────────────────────────
//  HIT RESULT
// ─────────────────────────────────────────────
enum HitResult { perfect, good, miss }

extension HitResultX on HitResult {
  String get label {
    switch (this) {
      case HitResult.perfect: return 'PERFECT';
      case HitResult.good:    return 'GOOD';
      case HitResult.miss:    return 'MISS';
    }
  }

  Color get color {
    switch (this) {
      case HitResult.perfect: return BeatColors.perfect;
      case HitResult.good:    return BeatColors.good;
      case HitResult.miss:    return BeatColors.miss;
    }
  }

  int get points {
    switch (this) {
      case HitResult.perfect: return BeatConst.perfectScore;
      case HitResult.good:    return BeatConst.goodScore;
      case HitResult.miss:    return 0;
    }
  }
}

// ─────────────────────────────────────────────
//  BEAT SCHEDULE  (when blocks appear, in beats)
//  A simple procedural pattern generator
// ─────────────────────────────────────────────
class BeatSchedule {
  /// Returns list of (beat, lane) pairs for the session.
  /// beat = beat number (0-indexed), lane = 0-3
  static List<({int beat, int lane})> generate({
    required int totalBeats,
    required int seed,
  }) {
    final rng = seed;
    final events = <({int beat, int lane})>[];
    // Ensure at least one block per beat, occasionally two
    for (int b = 2; b < totalBeats; b++) {
      // Primary hit every beat
      events.add((beat: b, lane: (b * 31 + rng) % BeatConst.lanes));
      // Double hit every 4 beats
      if (b % 4 == 0) {
        final lane2 = ((b * 31 + rng) + 2) % BeatConst.lanes;
        events.add((beat: b, lane: lane2));
      }
    }
    return events;
  }
}
