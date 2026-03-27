import 'dart:math';
import 'package:flutter/material.dart';
import 'wood_block_styles.dart';

// ─────────────────────────────────────────────
//  WOOD BLOCK – PURE DART ENGINE
// ─────────────────────────────────────────────

class WoodPiece {
  final int             id;
  final List<List<int>> cells;
  final Color           color;
  bool                  placed;

  WoodPiece({
    required this.id,
    required this.cells,
    required this.color,
    this.placed = false,
  });

  int get rows => cells.map((c) => c[0]).reduce(max) + 1;
  int get cols => cells.map((c) => c[1]).reduce(max) + 1;

  WoodPiece copyWith({bool? placed}) => WoodPiece(
        id: id,
        cells: cells,
        color: color,
        placed: placed ?? this.placed,
      );
}

class WoodPlaceResult {
  final int       score;
  final List<int> clearedRows;
  final List<int> clearedCols;
  const WoodPlaceResult({
    required this.score,
    required this.clearedRows,
    required this.clearedCols,
  });
  bool get hasClears => clearedRows.isNotEmpty || clearedCols.isNotEmpty;
}

class WoodBlockEngine {
  final _rng = Random();

  List<WoodPiece> generatePieces() {
    final result = <WoodPiece>[];
    for (int i = 0; i < 3; i++) {
      final shapeIdx = _rng.nextInt(WoodShapes.all.length);
      final colorIdx = _rng.nextInt(WoodColors.woodColors.length);
      result.add(WoodPiece(
        id:    i,
        cells: WoodShapes.all[shapeIdx],
        color: WoodColors.woodColors[colorIdx],
      ));
    }
    return result;
  }

  bool canPlace(List<List<bool>> grid, WoodPiece piece, int row, int col) {
    for (final cell in piece.cells) {
      final r = row + cell[0];
      final c = col + cell[1];
      if (r < 0 || r >= WoodConst.gridSize) return false;
      if (c < 0 || c >= WoodConst.gridSize) return false;
      if (grid[r][c]) return false;
    }
    return true;
  }

  WoodPlaceResult placePiece(
    List<List<bool>>   grid,
    List<List<Color?>> colorGrid,
    WoodPiece          piece,
    int row, int col,
  ) {
    for (final cell in piece.cells) {
      grid[row + cell[0]][col + cell[1]] = true;
      colorGrid[row + cell[0]][col + cell[1]] = piece.color;
    }

    final clearedRows = <int>[];
    for (int r = 0; r < WoodConst.gridSize; r++) {
      if (grid[r].every((v) => v)) clearedRows.add(r);
    }

    final clearedCols = <int>[];
    for (int c = 0; c < WoodConst.gridSize; c++) {
      if (List.generate(WoodConst.gridSize, (r) => grid[r][c]).every((v) => v)) {
        clearedCols.add(c);
      }
    }

    for (final r in clearedRows) {
      for (int c = 0; c < WoodConst.gridSize; c++) {
        grid[r][c] = false;
        colorGrid[r][c] = null;
      }
    }
    for (final c in clearedCols) {
      for (int r = 0; r < WoodConst.gridSize; r++) {
        grid[r][c] = false;
        colorGrid[r][c] = null;
      }
    }

    final cellScore = piece.cells.length * 8;
    final lineScore = (clearedRows.length + clearedCols.length) * 60;
    final combo     = (clearedRows.length + clearedCols.length) > 1 ? 40 : 0;

    return WoodPlaceResult(
      score:       cellScore + lineScore + combo,
      clearedRows: clearedRows,
      clearedCols: clearedCols,
    );
  }

  bool hasValidMove(List<List<bool>> grid, List<WoodPiece> pieces) {
    for (final piece in pieces) {
      if (piece.placed) continue;
      for (int r = 0; r < WoodConst.gridSize; r++) {
        for (int c = 0; c < WoodConst.gridSize; c++) {
          if (canPlace(grid, piece, r, c)) return true;
        }
      }
    }
    return false;
  }
}
