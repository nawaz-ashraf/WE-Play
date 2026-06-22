import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'memory_engine.dart';
import 'memory_styles.dart';
import '../../../core/services/score_persistence_service.dart';

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────
enum MemoryStatus { idle, playing, paused, complete }

class MemoryState {
  final List<MemoryCard>   cards;
  final List<int>          faceUpIndices;  // 0, 1, or 2 indices
  final int                matchedPairs;
  final int                totalPairs;
  final int                moves;
  final int                score;
  final int                coins;
  final int                bestScore;
  final double             timeLeft;
  final MemoryStatus       status;
  final MemoryDifficulty   difficulty;
  final bool               isFlipping;    // locked while flip-back animates

  const MemoryState({
    this.cards          = const [],
    this.faceUpIndices  = const [],
    this.matchedPairs   = 0,
    this.totalPairs     = 0,
    this.moves          = 0,
    this.score          = 0,
    this.coins          = 0,
    this.bestScore      = 0,
    this.timeLeft       = 0,
    this.status         = MemoryStatus.idle,
    this.difficulty     = MemoryDifficulty.easy,
    this.isFlipping     = false,
  });

  MemoryState copyWith({
    List<MemoryCard>?   cards,
    List<int>?          faceUpIndices,
    int?                matchedPairs,
    int?                totalPairs,
    int?                moves,
    int?                score,
    int?                coins,
    int?                bestScore,
    double?             timeLeft,
    MemoryStatus?       status,
    MemoryDifficulty?   difficulty,
    bool?               isFlipping,
  }) =>
      MemoryState(
        cards:         cards         ?? this.cards,
        faceUpIndices: faceUpIndices ?? this.faceUpIndices,
        matchedPairs:  matchedPairs  ?? this.matchedPairs,
        totalPairs:    totalPairs    ?? this.totalPairs,
        moves:         moves         ?? this.moves,
        score:         score         ?? this.score,
        coins:         coins         ?? this.coins,
        bestScore:     bestScore     ?? this.bestScore,
        timeLeft:      timeLeft      ?? this.timeLeft,
        status:        status        ?? this.status,
        difficulty:    difficulty    ?? this.difficulty,
        isFlipping:    isFlipping    ?? this.isFlipping,
      );

  int get totalCards => cards.length;
  double get progress => totalPairs == 0 ? 0 : matchedPairs / totalPairs;
}

// ─────────────────────────────────────────────
//  NOTIFIER
// ─────────────────────────────────────────────
class MemoryNotifier extends StateNotifier<MemoryState> {
  MemoryNotifier() : super(const MemoryState()) {
    _loadSavedBestScore();
  }

  final _scoreSvc = ScorePersistenceService();
  static const String _gameId = 'memory_puzzle';

  final _engine = MemoryEngine();
  Timer? _timer;
  Timer? _flipBackTimer;

  void startGame(MemoryDifficulty difficulty) {
    _timer?.cancel();
    _flipBackTimer?.cancel();

    final cards     = _engine.generateDeck(difficulty);
    final gridSize  = MemoryConst.gridSizes[difficulty]!;
    final pairs     = (gridSize.cols * gridSize.rows) ~/ 2;
    final timeLimit = MemoryConst.timeLimits[difficulty]!;

    state = MemoryState(
      cards:      cards,
      totalPairs: pairs,
      timeLeft:   timeLimit.toDouble(),
      status:     MemoryStatus.playing,
      difficulty: difficulty,
      bestScore:  state.bestScore,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (state.status != MemoryStatus.playing) return;
      final left = state.timeLeft - 0.1;
      if (left <= 0) {
        _timer?.cancel();
        state = state.copyWith(timeLeft: 0, status: MemoryStatus.complete);
      } else {
        state = state.copyWith(timeLeft: left);
      }
    });
  }

  void flipCard(int index) {
    if (state.status != MemoryStatus.playing) return;
    if (state.isFlipping) return;

    final cards          = List<MemoryCard>.from(state.cards);
    final faceUpIndices  = List<int>.from(state.faceUpIndices);

    final result = _engine.flip(cards, index, faceUpIndices);

    switch (result) {
      case FlipResult.ignore:
        return;

      case FlipResult.firstCard:
        state = state.copyWith(
          cards:         cards,
          faceUpIndices: faceUpIndices,
        );
        break;

      case FlipResult.matched:
        final newMatched = state.matchedPairs + 1;
        final newCoins   = state.coins + MemoryConst.coinsPerPair;
        // Score: pairs matched × time bonus
        final timeBonus  = (state.timeLeft / 10).floor();
        final newScore   = state.score + 100 + timeBonus;
        final newMoves   = state.moves + 1;
        final isComplete = newMatched >= state.totalPairs;
        final bonus      = isComplete ? MemoryConst.bonusCoins : 0;
        final newBest    = (newScore + bonus * 10) > state.bestScore
            ? (newScore + bonus * 10)
            : state.bestScore;

        if (isComplete) _timer?.cancel();

        state = state.copyWith(
          cards:         cards,
          faceUpIndices: const [],
          matchedPairs:  newMatched,
          moves:         newMoves,
          score:         newScore + bonus * 10,
          coins:         newCoins + bonus,
          bestScore:     newBest,
          status:        isComplete ? MemoryStatus.complete : MemoryStatus.playing,
        );

        if ((newScore + bonus * 10) > state.bestScore) {
          _scoreSvc.saveBestScore(_gameId, newScore + bonus * 10);
        }
        break;

      case FlipResult.noMatch:
        final newMoves = state.moves + 1;
        state = state.copyWith(
          cards:         cards,
          faceUpIndices: faceUpIndices,
          moves:         newMoves,
          isFlipping:    true,
        );

        // Flip back after delay
        _flipBackTimer = Timer(
          Duration(milliseconds: (MemoryConst.flipBackDelay * 1000).toInt()),
          () {
            final updatedCards = List<MemoryCard>.from(state.cards);
            _engine.flipBack(updatedCards, state.faceUpIndices);
            state = state.copyWith(
              cards:         updatedCards,
              faceUpIndices: const [],
              isFlipping:    false,
            );
          },
        );
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flipBackTimer?.cancel();
    super.dispose();
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
final memoryProvider =
    StateNotifierProvider<MemoryNotifier, MemoryState>(
  (ref) => MemoryNotifier(),
);
