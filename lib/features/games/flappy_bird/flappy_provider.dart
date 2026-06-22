import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'flappy_styles.dart';
import '../../../core/services/score_persistence_service.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────
enum FlappyStatus { idle, playing, dead }

class FlappyState {
  final int          score;
  final int          coins;
  final int          bestScore;
  final FlappyStatus status;
  final double       pipeSpeed;

  const FlappyState({
    this.score      = 0,
    this.coins      = 0,
    this.bestScore  = 0,
    this.status     = FlappyStatus.idle,
    this.pipeSpeed  = FlappyConst.pipeSpeedBase,
  });

  FlappyState copyWith({
    int?          score,
    int?          coins,
    int?          bestScore,
    FlappyStatus? status,
    double?       pipeSpeed,
  }) =>
      FlappyState(
        score:      score      ?? this.score,
        coins:      coins      ?? this.coins,
        bestScore:  bestScore  ?? this.bestScore,
        status:     status     ?? this.status,
        pipeSpeed:  pipeSpeed  ?? this.pipeSpeed,
      );
}

// ─────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────
class FlappyNotifier extends StateNotifier<FlappyState> {
  FlappyNotifier() : super(const FlappyState()) {
    _loadSavedBestScore();
  }

  final _scoreSvc = ScorePersistenceService();
  static const String _gameId = 'flappy_bird';

  void startGame() {
    state = FlappyState(
      bestScore:  state.bestScore,
      status:     FlappyStatus.playing,
      pipeSpeed:  FlappyConst.pipeSpeedBase,
    );
  }

  void addScore() {
    if (state.status != FlappyStatus.playing) return;
    final newScore = state.score + 1;
    final newBest  = newScore > state.bestScore ? newScore : state.bestScore;

    // Speed up every pipe
    final newSpeed = (state.pipeSpeed + FlappyConst.pipeSpeedInc)
        .clamp(0.0, FlappyConst.pipeSpeedMax);

    // Coins every 5 pipes
    final newCoins = state.coins +
        (newScore % FlappyConst.coinEvery == 0 ? 1 : 0);

    state = state.copyWith(
      score:     newScore,
      bestScore: newBest,
      coins:     newCoins,
      pipeSpeed: newSpeed,
    );

    if (newScore > state.bestScore) {
      _scoreSvc.saveBestScore(_gameId, newScore);
    }
  }

  void die() {
    if (state.status != FlappyStatus.playing) return;
    state = state.copyWith(status: FlappyStatus.dead);
  }

  void reset() {
    state = FlappyState(bestScore: state.bestScore);
  }

  Future<void> _loadSavedBestScore() async {
    final saved = await _scoreSvc.loadBestScore(_gameId);
    if (saved > state.bestScore && mounted) {
      state = state.copyWith(bestScore: saved);
    }
  }
}

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────
final flappyProvider =
    StateNotifierProvider<FlappyNotifier, FlappyState>(
  (ref) => FlappyNotifier(),
);
