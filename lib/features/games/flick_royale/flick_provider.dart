import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'flick_styles.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────
enum FlickStatus { idle, roundActive, roundOver, matchOver }

class FlickState {
  final int          round;           // 1-based
  final int          playerRoundWins;
  final int          aiRoundWins;
  final int          playerPucksLeft;
  final int          aiPucksLeft;
  final int          score;           // total points this match
  final int          coins;
  final int          bestScore;
  final double       timeLeft;
  final FlickStatus  status;
  final RoundWinner? lastRoundWinner;
  final int          winStreak;       // player wins in a row → harder AI

  const FlickState({
    this.round            = 1,
    this.playerRoundWins  = 0,
    this.aiRoundWins      = 0,
    this.playerPucksLeft  = FlickConst.pucksPerSide,
    this.aiPucksLeft      = FlickConst.pucksPerSide,
    this.score            = 0,
    this.coins            = 0,
    this.bestScore        = 0,
    this.timeLeft         = FlickConst.roundSeconds,
    this.status           = FlickStatus.idle,
    this.lastRoundWinner,
    this.winStreak        = 0,
  });

  FlickState copyWith({
    int?          round,
    int?          playerRoundWins,
    int?          aiRoundWins,
    int?          playerPucksLeft,
    int?          aiPucksLeft,
    int?          score,
    int?          coins,
    int?          bestScore,
    double?       timeLeft,
    FlickStatus?  status,
    RoundWinner?  lastRoundWinner,
    int?          winStreak,
  }) =>
      FlickState(
        round:           round           ?? this.round,
        playerRoundWins: playerRoundWins ?? this.playerRoundWins,
        aiRoundWins:     aiRoundWins     ?? this.aiRoundWins,
        playerPucksLeft: playerPucksLeft ?? this.playerPucksLeft,
        aiPucksLeft:     aiPucksLeft     ?? this.aiPucksLeft,
        score:           score           ?? this.score,
        coins:           coins           ?? this.coins,
        bestScore:       bestScore       ?? this.bestScore,
        timeLeft:        timeLeft        ?? this.timeLeft,
        status:          status          ?? this.status,
        lastRoundWinner: lastRoundWinner ?? this.lastRoundWinner,
        winStreak:       winStreak       ?? this.winStreak,
      );

  int get aiDifficulty =>
      winStreak.clamp(0, FlickConst.aiAccuracy.length - 1);

  bool get playerWonMatch => playerRoundWins > FlickConst.rounds ~/ 2;
  bool get aiWonMatch     => aiRoundWins     > FlickConst.rounds ~/ 2;
}

// ─────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────
class FlickNotifier extends StateNotifier<FlickState> {
  FlickNotifier() : super(const FlickState());

  void startMatch() {
    state = FlickState(
      bestScore:  state.bestScore,
      winStreak:  state.winStreak,
      status:     FlickStatus.roundActive,
      timeLeft:   FlickConst.roundSeconds,
    );
  }

  void tick(double dt) {
    if (state.status != FlickStatus.roundActive) return;
    final left = state.timeLeft - dt;
    if (left <= 0) {
      _endRoundByTime();
    } else {
      state = state.copyWith(timeLeft: left);
    }
  }

  void playerPuckKnockedOff() {
    if (state.status != FlickStatus.roundActive) return;
    final left = state.playerPucksLeft - 1;
    state = state.copyWith(playerPucksLeft: left);
    if (left <= 0) _endRound(RoundWinner.ai);
  }

  void aiPuckKnockedOff() {
    if (state.status != FlickStatus.roundActive) return;
    final left    = state.aiPucksLeft - 1;
    final pts     = 10;
    final newScore= state.score + pts;
    state = state.copyWith(
      aiPucksLeft: left,
      score: newScore,
      bestScore: newScore > state.bestScore ? newScore : state.bestScore,
    );
    if (left <= 0) _endRound(RoundWinner.player);
  }

  void _endRoundByTime() {
    final winner = state.playerPucksLeft > state.aiPucksLeft
        ? RoundWinner.player
        : state.aiPucksLeft > state.playerPucksLeft
            ? RoundWinner.ai
            : RoundWinner.draw;
    _endRound(winner);
  }

  void _endRound(RoundWinner winner) {
    int pWins = state.playerRoundWins;
    int aWins = state.aiRoundWins;
    int coins = state.coins;
    int streak = state.winStreak;

    if (winner == RoundWinner.player) {
      pWins++;
      coins += FlickConst.coinsPerRoundWin;
      streak++;
    } else if (winner == RoundWinner.ai) {
      aWins++;
      streak = 0;
    }

    final matchDone = pWins > FlickConst.rounds ~/ 2 ||
        aWins > FlickConst.rounds ~/ 2 ||
        state.round >= FlickConst.rounds;

    if (matchDone) {
      if (pWins > aWins) coins += FlickConst.coinsPerMatchWin;
      state = state.copyWith(
        playerRoundWins: pWins,
        aiRoundWins:     aWins,
        coins:           coins,
        winStreak:       streak,
        lastRoundWinner: winner,
        status:          FlickStatus.matchOver,
      );
    } else {
      state = state.copyWith(
        round:           state.round + 1,
        playerRoundWins: pWins,
        aiRoundWins:     aWins,
        coins:           coins,
        winStreak:       streak,
        lastRoundWinner: winner,
        status:          FlickStatus.roundOver,
      );
    }
  }

  void startNextRound() {
    state = state.copyWith(
      playerPucksLeft: FlickConst.pucksPerSide,
      aiPucksLeft:     FlickConst.pucksPerSide,
      timeLeft:        FlickConst.roundSeconds,
      status:          FlickStatus.roundActive,
      lastRoundWinner: null,
    );
  }
}

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────
final flickProvider =
    StateNotifierProvider<FlickNotifier, FlickState>(
  (ref) => FlickNotifier(),
);
