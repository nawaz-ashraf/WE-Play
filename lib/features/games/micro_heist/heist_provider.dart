import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'heist_styles.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────
enum HeistStatus { idle, playing, busted, levelComplete, gameComplete }

class HeistState {
  final int          level;          // 0-indexed
  final int          score;          // total across all levels
  final int          coins;
  final int          bestScore;
  final double       timeLeft;
  final bool         hasLoot;        // thief is carrying loot
  final HeistStatus  status;
  final int          levelsCleared;

  const HeistState({
    this.level         = 0,
    this.score         = 0,
    this.coins         = 0,
    this.bestScore     = 0,
    this.timeLeft      = 0,
    this.hasLoot       = false,
    this.status        = HeistStatus.idle,
    this.levelsCleared = 0,
  });

  HeistState copyWith({
    int?         level,
    int?         score,
    int?         coins,
    int?         bestScore,
    double?      timeLeft,
    bool?        hasLoot,
    HeistStatus? status,
    int?         levelsCleared,
  }) =>
      HeistState(
        level:         level         ?? this.level,
        score:         score         ?? this.score,
        coins:         coins         ?? this.coins,
        bestScore:     bestScore     ?? this.bestScore,
        timeLeft:      timeLeft      ?? this.timeLeft,
        hasLoot:       hasLoot       ?? this.hasLoot,
        status:        status        ?? this.status,
        levelsCleared: levelsCleared ?? this.levelsCleared,
      );

  LevelDef get currentLevel => kLevels[level.clamp(0, kLevels.length - 1)];
}

// ─────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────
class HeistNotifier extends StateNotifier<HeistState> {
  HeistNotifier() : super(const HeistState());

  void startGame() {
    state = HeistState(
      bestScore: state.bestScore,
      status:    HeistStatus.playing,
      timeLeft:  kLevels[0].timeLimitSec.toDouble(),
    );
  }

  void tick(double dt) {
    if (state.status != HeistStatus.playing) return;
    final left = state.timeLeft - dt;
    if (left <= 0) {
      // Time ran out = busted
      state = state.copyWith(timeLeft: 0, status: HeistStatus.busted);
    } else {
      state = state.copyWith(timeLeft: left);
    }
  }

  /// Called when thief walks onto loot cell
  void pickupLoot() {
    if (!state.hasLoot) {
      state = state.copyWith(hasLoot: true);
    }
  }

  /// Called when thief reaches exit WITH loot
  void completeLevel() {
    if (state.status != HeistStatus.playing) return;

    // Time bonus coins
    final timeBonus = (state.timeLeft * HeistConst.timeBonusMult).floor();
    final levelCoins = 1 + timeBonus;
    final newCoins   = state.coins + levelCoins;
    final newScore   = state.score + 100 + timeBonus * 10;
    final newBest    = newScore > state.bestScore ? newScore : state.bestScore;
    final newCleared = state.levelsCleared + 1;
    final nextLevel  = state.level + 1;

    if (nextLevel >= kLevels.length) {
      // All levels done
      state = state.copyWith(
        score:         newScore,
        coins:         newCoins,
        bestScore:     newBest,
        levelsCleared: newCleared,
        status:        HeistStatus.gameComplete,
      );
    } else {
      state = state.copyWith(
        level:         nextLevel,
        score:         newScore,
        coins:         newCoins,
        bestScore:     newBest,
        hasLoot:       false,
        levelsCleared: newCleared,
        timeLeft:      kLevels[nextLevel].timeLimitSec.toDouble(),
        status:        HeistStatus.levelComplete,
      );
    }
  }

  /// Resume playing after level-complete animation
  void resumeNextLevel() {
    state = state.copyWith(status: HeistStatus.playing);
  }

  void busted() {
    if (state.status != HeistStatus.playing) return;
    state = state.copyWith(status: HeistStatus.busted);
  }

  void restartGame() {
    state = HeistState(bestScore: state.bestScore);
    startGame();
  }

  /// Public accessors so the Flame game can read state
  /// without touching the protected [state] field.
  int get currentLevel => state.level;
  HeistStatus get currentStatus => state.status;
  bool get hasLoot => state.hasLoot;
}

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────
final heistProvider =
    StateNotifierProvider<HeistNotifier, HeistState>(
  (ref) => HeistNotifier(),
);
