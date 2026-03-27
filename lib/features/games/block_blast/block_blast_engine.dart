import 'dart:math';
import 'package:flutter/material.dart';
import 'block_blast_styles.dart';

// ─────────────────────────────────────────────
//  BLOCK BLAST – PURE DART ENGINE
// ─────────────────────────────────────────────

class BlockPiece {
  final int             id;
  final List<List<int>> cells;
  final Color           color;
  bool                  placed;

  BlockPiece({
    required this.id,
    required this.cells,
    required this.color,
    this.placed = false,
  });

  int get rows => cells.map((c) => c[0]).reduce(max) + 1;
  int get cols => cells.map((c) => c[1]).reduce(max) + 1;

  BlockPiece copyWith({bool? placed}) => BlockPiece(
        id: id,
        cells: cells,
        color: color,
        placed: placed ?? this.placed,
      );
}

class PlaceResult {
  final int       score;
  final List<int> clearedRows;
  final List<int> clearedCols;
  const PlaceResult({
    required this.score,
    required this.clearedRows,
    required this.clearedCols,
  });
  bool get hasClears => clearedRows.isNotEmpty || clearedCols.isNotEmpty;
}

class BlockBlastEngine {
  final _rng = Random();

  List<BlockPiece> generatePieces() {
    final result = <BlockPiece>[];
    for (int i = 0; i < 3; i++) {
      final shapeIdx = _rng.nextInt(BlockShapes.all.length);
      final colorIdx = _rng.nextInt(BlockColors.blockColors.length);
      result.add(BlockPiece(
        id:    i,
        cells: BlockShapes.all[shapeIdx],
        color: BlockColors.blockColors[colorIdx],
      ));
    }
    return result;
  }

  bool canPlace(List<List<bool>> grid, BlockPiece piece, int row, int col) {
    for (final cell in piece.cells) {
      final r = row + cell[0];
      final c = col + cell[1];
      if (r < 0 || r >= BlockConst.gridSize) return false;
      if (c < 0 || c >= BlockConst.gridSize) return false;
      if (grid[r][c]) return false;
    }
    return true;
  }

  PlaceResult placePiece(
    List<List<bool>>   grid,
    List<List<Color?>> colorGrid,
    BlockPiece         piece,
    int row, int col,
  ) {
    for (final cell in piece.cells) {
      grid[row + cell[0]][col + cell[1]] = true;
      colorGrid[row + cell[0]][col + cell[1]] = piece.color;
    }

    final clearedRows = <int>[];
    for (int r = 0; r < BlockConst.gridSize; r++) {
      if (grid[r].every((v) => v)) clearedRows.add(r);
    }

    final clearedCols = <int>[];
    for (int c = 0; c < BlockConst.gridSize; c++) {
      if (List.generate(BlockConst.gridSize, (r) => grid[r][c]).every((v) => v)) {
        clearedCols.add(c);
      }
    }

    for (final r in clearedRows) {
      for (int c = 0; c < BlockConst.gridSize; c++) {
        grid[r][c] = false;
        colorGrid[r][c] = null;
      }
    }
    for (final c in clearedCols) {
      for (int r = 0; r < BlockConst.gridSize; r++) {
        grid[r][c] = false;
        colorGrid[r][c] = null;
      }
    }

    final cellScore = piece.cells.length * 10;
    final lineScore = (clearedRows.length + clearedCols.length) * 50;
    final combo     = (clearedRows.length + clearedCols.length) > 1 ? 30 : 0;

    return PlaceResult(
      score:       cellScore + lineScore + combo,
      clearedRows: clearedRows,
      clearedCols: clearedCols,
    );
  }

  bool hasValidMove(List<List<bool>> grid, List<BlockPiece> pieces) {
    for (final piece in pieces) {
      if (piece.placed) continue;
      for (int r = 0; r < BlockConst.gridSize; r++) {
        for (int c = 0; c < BlockConst.gridSize; c++) {
          if (canPlace(grid, piece, r, c)) return true;
        }
      }
    }
    return false;
  }
}
