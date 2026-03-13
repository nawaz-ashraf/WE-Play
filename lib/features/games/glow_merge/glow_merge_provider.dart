import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'glow_merge_logic.dart';
import 'coin_service.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────
enum GameStatus { idle, playing, over }

class GlowMergeState {
  final List<List<Blob?>> grid;
  final int score;
  final int coins;
  final int bestScore;
  final GameStatus status;
  final List<MergeEvent> lastMerges;
  final int moves;

  const GlowMergeState({
    required this.grid,
    this.score = 0,
    this.coins = 0,
    this.bestScore = 0,
    this.status = GameStatus.idle,
    this.lastMerges = const [],
    this.moves = 0,
  });

  GlowMergeState copyWith({
    List<List<Blob?>>? grid,
    int? score,
    int? coins,
    int? bestScore,
    GameStatus? status,
    List<MergeEvent>? lastMerges,
    int? moves,
  }) =>
      GlowMergeState(
        grid: grid ?? this.grid,
        score: score ?? this.score,
        coins: coins ?? this.coins,
        bestScore: bestScore ?? this.bestScore,
        status: status ?? this.status,
        lastMerges: lastMerges ?? this.lastMerges,
        moves: moves ?? this.moves,
      );
}

// ─────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────
class GlowMergeNotifier extends StateNotifier<GlowMergeState> {
  final GlowMergeEngine _engine = GlowMergeEngine();

  GlowMergeNotifier()
      : super(GlowMergeState(
          grid: List.generate(4, (_) => List<Blob?>.filled(4, null)),
        ));

  void startGame() {
    final grid = _engine.newGame();
    state = state.copyWith(
      grid: grid,
      score: 0,
      coins: 0,
      status: GameStatus.playing,
      lastMerges: [],
      moves: 0,
    );
  }

  Future<void> swipe(SwipeDirection dir) async {
    if (state.status != GameStatus.playing) return;

    final result = _engine.swipe(state.grid, dir);
    if (!result.moved) return;

    final newScore = state.score + result.scoreGained;
    final newCoins = state.coins + result.coinsGained;
    final newBest = newScore > state.bestScore ? newScore : state.bestScore;
    final isOver = !_engine.hasValidMoves(result.grid);

    state = state.copyWith(
      grid: result.grid,
      score: newScore,
      coins: newCoins,
      bestScore: newBest,
      lastMerges: result.merges,
      moves: state.moves + 1,
      status: isOver ? GameStatus.over : GameStatus.playing,
    );

    if (isOver && newCoins > 0) {
      try {
        final coinService = CoinService();
        await coinService.awardCoins(newCoins);
      } catch (_) {
        // Firebase not configured yet — coins tracked locally only
      }
    }
  }

  void resetMergeEvents() {
    state = state.copyWith(lastMerges: []);
  }
}

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────
final glowMergeProvider =
    StateNotifierProvider<GlowMergeNotifier, GlowMergeState>(
  (ref) => GlowMergeNotifier(),
);
