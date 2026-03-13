import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'beat_crash_styles.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────
enum BeatGameStatus { idle, playing, over }

class BeatCrashState {
  final int score;
  final int combo;
  final int maxCombo;
  final int coins;
  final int bestScore;
  final double timeLeft;
  final BeatGameStatus status;
  final HitResult? lastHit;
  final double multiplier;

  const BeatCrashState({
    this.score      = 0,
    this.combo      = 0,
    this.maxCombo   = 0,
    this.coins      = 0,
    this.bestScore  = 0,
    this.timeLeft   = BeatConst.sessionSeconds,
    this.status     = BeatGameStatus.idle,
    this.lastHit,
    this.multiplier = 1.0,
  });

  BeatCrashState copyWith({
    int?            score,
    int?            combo,
    int?            maxCombo,
    int?            coins,
    int?            bestScore,
    double?         timeLeft,
    BeatGameStatus? status,
    HitResult?      lastHit,
    double?         multiplier,
  }) =>
      BeatCrashState(
        score:      score      ?? this.score,
        combo:      combo      ?? this.combo,
        maxCombo:   maxCombo   ?? this.maxCombo,
        coins:      coins      ?? this.coins,
        bestScore:  bestScore  ?? this.bestScore,
        timeLeft:   timeLeft   ?? this.timeLeft,
        status:     status     ?? this.status,
        lastHit:    lastHit    ?? this.lastHit,
        multiplier: multiplier ?? this.multiplier,
      );
}

// ─────────────────────────────────────────────
//  NOTIFIER
//  The Flame game calls these methods directly
//  via a reference injected at construction.
// ─────────────────────────────────────────────
class BeatCrashNotifier extends StateNotifier<BeatCrashState> {
  BeatCrashNotifier() : super(const BeatCrashState());

  void startGame() {
    state = BeatCrashState(bestScore: state.bestScore, status: BeatGameStatus.playing);
  }

  void recordHit(HitResult result) {
    if (state.status != BeatGameStatus.playing) return;

    int newCombo = result == HitResult.miss ? 0 : state.combo + 1;
    double mult  = _multiplierForCombo(newCombo);
    int gained   = (result.points * mult).toInt();
    int newScore = state.score + gained;
    int newCoins = (newScore / 200).floor();
    int newMax   = newCombo > state.maxCombo ? newCombo : state.maxCombo;

    state = state.copyWith(
      score:      newScore,
      combo:      newCombo,
      maxCombo:   newMax,
      coins:      newCoins,
      multiplier: mult,
      lastHit:    result,
      bestScore:  newScore > state.bestScore ? newScore : state.bestScore,
    );
  }

  void tick(double dt) {
    if (state.status != BeatGameStatus.playing) return;
    final left = state.timeLeft - dt;
    if (left <= 0) {
      state = state.copyWith(timeLeft: 0, status: BeatGameStatus.over);
    } else {
      state = state.copyWith(timeLeft: left);
    }
  }

  void endGame() {
    state = state.copyWith(status: BeatGameStatus.over);
  }

  /// Public accessor so the FlameGame can check status without
  /// touching the protected [state] field.
  bool get isGameOver => state.status == BeatGameStatus.over;

  double _multiplierForCombo(int combo) {
    double mult = 1.0;
    for (int i = 0; i < BeatConst.comboThresholds.length; i++) {
      if (combo >= BeatConst.comboThresholds[i]) {
        mult = BeatConst.comboMultipliers[i];
      }
    }
    return mult;
  }
}

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────
final beatCrashProvider =
    StateNotifierProvider<BeatCrashNotifier, BeatCrashState>(
  (ref) => BeatCrashNotifier(),
);
