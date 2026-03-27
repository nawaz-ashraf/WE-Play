import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'block_blast_engine.dart';
import 'block_blast_styles.dart';

// ─────────────────────────────────────────────
//  BLOCK BLAST – STATE & PROVIDER
// ─────────────────────────────────────────────

enum BlockStatus { idle, playing, over }

class BlockState {
  final List<List<bool>>   grid;
  final List<List<Color?>> colorGrid;
  final List<BlockPiece>   pieces;
  final int                score;
  final int                coins;
  final int                bestScore;
  final BlockStatus        status;
  final List<int>          lastClearedRows;
  final List<int>          lastClearedCols;

  const BlockState({
    required this.grid,
    required this.colorGrid,
    required this.pieces,
    this.score           = 0,
    this.coins           = 0,
    this.bestScore       = 0,
    this.status          = BlockStatus.idle,
    this.lastClearedRows = const [],
    this.lastClearedCols = const [],
  });

  BlockState copyWith({
    List<List<bool>>?   grid,
    List<List<Color?>>? colorGrid,
    List<BlockPiece>?   pieces,
    int?                score,
    int?                coins,
    int?                bestScore,
    BlockStatus?        status,
    List<int>?          lastClearedRows,
    List<int>?          lastClearedCols,
  }) =>
      BlockState(
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

class BlockNotifier extends StateNotifier<BlockState> {
  BlockNotifier()
      : super(BlockState(
          grid:      _emptyGrid(),
          colorGrid: _emptyColorGrid(),
          pieces:    const [],
        ));

  final _engine = BlockBlastEngine();

  static List<List<bool>> _emptyGrid() =>
      List.generate(BlockConst.gridSize, (_) =>
          List.filled(BlockConst.gridSize, false));

  static List<List<Color?>> _emptyColorGrid() =>
      List.generate(BlockConst.gridSize, (_) =>
          List<Color?>.filled(BlockConst.gridSize, null));

  void startGame() {
    state = BlockState(
      grid:      _emptyGrid(),
      colorGrid: _emptyColorGrid(),
      pieces:    _engine.generatePieces(),
      status:    BlockStatus.playing,
    );
  }

  void placePiece(int pieceIndex, int row, int col) {
    if (state.status != BlockStatus.playing) return;
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
    final newCoins = newScore ~/ BlockConst.coinEvery;
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
      status:          isOver ? BlockStatus.over : BlockStatus.playing,
    );
  }

  bool canPlaceAt(int pieceIndex, int row, int col) {
    final piece = state.pieces[pieceIndex];
    if (piece.placed) return false;
    return _engine.canPlace(state.grid, piece, row, col);
  }
}

final blockBlastProvider =
    StateNotifierProvider<BlockNotifier, BlockState>(
  (ref) => BlockNotifier(),
);
