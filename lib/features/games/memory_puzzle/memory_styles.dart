import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────
class MemoryColors {
  static const background    = Color(0xFF0A0A12);
  static const surface       = Color(0xFF13131F);
  static const primary       = Color(0xFFFF3E6C); // hot pink
  static const accent        = Color(0xFF00F5A0); // neon green
  static const warn          = Color(0xFFFFD740); // amber
  static const purple        = Color(0xFF7B61FF);
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);

  // Card faces
  static const cardBack      = Color(0xFF1A1A2E);
  static const cardBackEdge  = Color(0xFF2A2A50);
  static const cardMatched   = Color(0xFF0A2A1A);
  static const cardMatchEdge = Color(0xFF00F5A0);
  static const cardFlipping  = Color(0xFF2A1A3A);
  static const cardFlipEdge  = Color(0xFFFF3E6C);
}

// ─────────────────────────────────────────────
//  GAME CONSTANTS
// ─────────────────────────────────────────────
class MemoryConst {
  // Grid sizes per difficulty
  static const Map<MemoryDifficulty, ({int cols, int rows})> gridSizes = {
    MemoryDifficulty.easy:   (cols: 4, rows: 3), // 12 cards = 6 pairs
    MemoryDifficulty.medium: (cols: 4, rows: 4), // 16 cards = 8 pairs
    MemoryDifficulty.hard:   (cols: 4, rows: 5), // 20 cards = 10 pairs
  };

  // Time limits (seconds) per difficulty
  static const Map<MemoryDifficulty, int> timeLimits = {
    MemoryDifficulty.easy:   60,
    MemoryDifficulty.medium: 90,
    MemoryDifficulty.hard:   120,
  };

  // Coins per pair matched
  static const int coinsPerPair  = 1;
  static const int bonusCoins    = 5;   // for completing with time left

  // Flip-back delay (seconds) when pair doesn't match
  static const double flipBackDelay = 0.9;

  // Card dimensions
  static const double cardAspect = 0.72; // width/height ratio
  static const double cardGap    = 10.0;
  static const double cardRadius = 14.0;
}

// ─────────────────────────────────────────────
//  DIFFICULTY
// ─────────────────────────────────────────────
enum MemoryDifficulty { easy, medium, hard }

extension MemoryDifficultyX on MemoryDifficulty {
  String get label {
    switch (this) {
      case MemoryDifficulty.easy:   return 'easy';
      case MemoryDifficulty.medium: return 'medium';
      case MemoryDifficulty.hard:   return 'hard';
    }
  }

  Color get color {
    switch (this) {
      case MemoryDifficulty.easy:   return MemoryColors.accent;
      case MemoryDifficulty.medium: return MemoryColors.warn;
      case MemoryDifficulty.hard:   return MemoryColors.primary;
    }
  }
}

// ─────────────────────────────────────────────
//  EMOJI CARD POOL  (20 unique emojis for hard)
// ─────────────────────────────────────────────
const List<String> kCardEmojis = [
  '🔥', '⚡', '💎', '🌙', '⭐',
  '🎯', '🚀', '🎮', '👾', '🦄',
  '🌊', '🍀', '🎸', '🏆', '💀',
  '🐉', '🎲', '🔮', '💫', '🌈',
];

// ─────────────────────────────────────────────
//  CARD MODEL
// ─────────────────────────────────────────────
class MemoryCard {
  final int    id;          // unique per card instance
  final int    pairId;      // shared between two matched cards
  final String emoji;
  bool         isFaceUp  = false;
  bool         isMatched  = false;

  MemoryCard({
    required this.id,
    required this.pairId,
    required this.emoji,
  });
}
