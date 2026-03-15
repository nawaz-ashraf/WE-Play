import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'snack_styles.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────
enum StackGameStatus { idle, playing, over }

class SnackState {
  final double score;         // = peak tower height in meters
  final int    coins;
  final double bestScore;
  final double timeLeft;
  final int    itemsDropped;
  final bool   wobbling;      // tower is about to fall
  final StackGameStatus status;
  final FoodConfig? nextItem;

  const SnackState({
    this.score       = 0.0,
    this.coins       = 0,
    this.bestScore   = 0.0,
    this.timeLeft    = StackConst.sessionSeconds,
    this.itemsDropped= 0,
    this.wobbling    = false,
    this.status      = StackGameStatus.idle,
    this.nextItem,
  });

  SnackState copyWith({
    double?         score,
    int?            coins,
    double?         bestScore,
    double?         timeLeft,
    int?            itemsDropped,
    bool?           wobbling,
    StackGameStatus?status,
    FoodConfig?     nextItem,
  }) =>
      SnackState(
        score:        score        ?? this.score,
        coins:        coins        ?? this.coins,
        bestScore:    bestScore    ?? this.bestScore,
        timeLeft:     timeLeft     ?? this.timeLeft,
        itemsDropped: itemsDropped ?? this.itemsDropped,
        wobbling:     wobbling     ?? this.wobbling,
        status:       status       ?? this.status,
        nextItem:     nextItem     ?? this.nextItem,
      );
}

// ─────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────
class SnackNotifier extends StateNotifier<SnackState> {
  SnackNotifier() : super(const SnackState());

  void startGame() {
    state = SnackState(
      bestScore: state.bestScore,
      status:    StackGameStatus.playing,
      nextItem:  _pickItem(0),
    );
  }

  void tick(double dt) {
    if (state.status != StackGameStatus.playing) return;
    final left = state.timeLeft - dt;
    if (left <= 0) {
      state = state.copyWith(timeLeft: 0, status: StackGameStatus.over);
    } else {
      state = state.copyWith(timeLeft: left);
    }
  }

  /// Called by the Flame game every frame with the current tower height in meters.
  void updateHeight(double heightM) {
    if (state.status != StackGameStatus.playing) return;
    final coins = (heightM * StackConst.coinPerUnit * 100).floor();
    final best  = heightM > state.bestScore ? heightM : state.bestScore;
    state = state.copyWith(score: heightM, coins: coins, bestScore: best);
  }

  void itemDropped() {
    if (state.status != StackGameStatus.playing) return;
    final n = state.itemsDropped + 1;
    state = state.copyWith(
      itemsDropped: n,
      nextItem:     _pickItem(n),
    );
  }

  void setWobbling(bool w) {
    if (state.wobbling == w) return;
    state = state.copyWith(wobbling: w);
  }

  void towerFell() {
    if (state.status != StackGameStatus.playing) return;
    state = state.copyWith(status: StackGameStatus.over);
  }

  /// Public accessors so the Flame game can read state
  /// without touching the protected [state] field.
  bool get isGameOver => state.status == StackGameStatus.over;
  FoodConfig? get nextItem => state.nextItem;

  FoodConfig _pickItem(int index) =>
      kFoodItems[index % kFoodItems.length];
}

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────
final snackProvider =
    StateNotifierProvider<SnackNotifier, SnackState>(
  (ref) => SnackNotifier(),
);
