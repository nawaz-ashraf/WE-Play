import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'wood_block_engine.dart';
import 'wood_block_styles.dart';
import '../../../core/services/score_persistence_service.dart';

// ─────────────────────────────────────────────
//  WOOD BLOCK – STATE & PROVIDER
// ─────────────────────────────────────────────

enum WoodStatus { idle, playing, over }

class WoodState {
  final List<List<bool>>   grid;
  final List<List<Color?>> colorGrid;
  final List<WoodPiece>    pieces;
  final int                score;
  final int                coins;
  final int                bestScore;
  final WoodStatus         status;
  final List<int>          lastClearedRows;
  final List<int>          lastClearedCols;

  const WoodState({
    required this.grid,
    required this.colorGrid,
    required this.pieces,
    this.score           = 0,
    this.coins           = 0,
    this.bestScore       = 0,
    this.status          = WoodStatus.idle,
    this.lastClearedRows = const [],
    this.lastClearedCols = const [],
  });

  WoodState copyWith({
    List<List<bool>>?   grid,
    List<List<Color?>>? colorGrid,
    List<WoodPiece>?    pieces,
    int?                score,
    int?                coins,
    int?                bestScore,
    WoodStatus?         status,
    List<int>?          lastClearedRows,
    List<int>?          lastClearedCols,
  }) =>
      WoodState(
        grid:            grid            ?? this.grid,
        colorGrid:       colorGrid       ?? this.colorGrid,
        pieces:          pieces          ?? this.pieces,
        score:           score           ?? this.score,
        coins:           coins           ?? this.coins,
        bestScore:       bestScore       ?? this.bestScore,
        status:          status          ?? this.status,
        lastClearedRows: lastClearedRows ?? this.lastClearedRows,
        lastClearedCols: lastClearedCols ?? this.lastClearedCols,
      );
}

class WoodNotifier extends StateNotifier<WoodState> {
  WoodNotifier()
      : super(WoodState(
          grid:      _emptyGrid(),
          colorGrid: _emptyColorGrid(),
          pieces:    const [],
        )) {
    _loadSavedBestScore();
  }

  final _scoreSvc = ScorePersistenceService();
  static const String _gameId = 'wood_block';

  final _engine = WoodBlockEngine();

  static List<List<bool>> _emptyGrid() =>
      List.generate(WoodConst.gridSize, (_) =>
          List.filled(WoodConst.gridSize, false));

  static List<List<Color?>> _emptyColorGrid() =>
      List.generate(WoodConst.gridSize, (_) =>
          List<Color?>.filled(WoodConst.gridSize, null));

  void startGame() {
    state = WoodState(
      grid:      _emptyGrid(),
      colorGrid: _emptyColorGrid(),
      pieces:    _engine.generatePieces(),
      status:    WoodStatus.playing,
    );
  }

  void placePiece(int pieceIndex, int row, int col) {
    if (state.status != WoodStatus.playing) return;
    final piece = state.pieces[pieceIndex];
    if (piece.placed) return;
    if (!_engine.canPlace(state.grid, piece, row, col)) return;

    final grid      = state.grid.map((r) => List<bool>.from(r)).toList();
    final colorGrid = state.colorGrid.map((r) => List<Color?>.from(r)).toList();

    final result = _engine.placePiece(grid, colorGrid, piece, row, col);

    final pieces = state.pieces.map((p) {
      if (p.id == pieceIndex) return p.copyWith(placed: true);
      return p;
    }).toList();

    final newScore = state.score + result.score;
    final newCoins = newScore ~/ WoodConst.coinEvery;
    final newBest  = newScore > state.bestScore ? newScore : state.bestScore;

    final allPlaced = pieces.every((p) => p.placed);
    final newPieces = allPlaced ? _engine.generatePieces() : pieces;

    final remaining = allPlaced
        ? newPieces
        : newPieces.where((p) => !p.placed).toList();
    final isOver = !_engine.hasValidMove(grid, remaining);

    state = state.copyWith(
      grid:            grid,
      colorGrid:       colorGrid,
      pieces:          newPieces,
      score:           newScore,
      coins:           newCoins,
      bestScore:       newBest,
      lastClearedRows: result.clearedRows,
      lastClearedCols: result.clearedCols,
      status:          isOver ? WoodStatus.over : WoodStatus.playing,
    );

    if (newScore > state.bestScore) {
      _scoreSvc.saveBestScore(_gameId, newScore);
    }
  }

  bool canPlaceAt(int pieceIndex, int row, int col) {
    final piece = state.pieces[pieceIndex];
    if (piece.placed) return false;
    return _engine.canPlace(state.grid, piece, row, col);
  }

  Future<void> _loadSavedBestScore() async {
    final saved = await _scoreSvc.loadBestScore(_gameId);
    if (saved > state.bestScore && mounted) {
      state = state.copyWith(bestScore: saved);
    }
  }
}

final woodBlockProvider =
    StateNotifierProvider<WoodNotifier, WoodState>(
  (ref) => WoodNotifier(),
);
