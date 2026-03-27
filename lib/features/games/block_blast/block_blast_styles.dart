import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  BLOCK BLAST – COLORS & CONSTANTS
// ─────────────────────────────────────────────

class BlockColors {
  static const background    = Color(0xFF0A0A12);
  static const surface       = Color(0xFF13131F);
  static const primary       = Color(0xFF7B61FF);
  static const accent        = Color(0xFF00F5A0);
  static const energy        = Color(0xFFFF3E6C);
  static const warn          = Color(0xFFFFD740);
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);

  // Grid
  static const gridBg        = Color(0xFF0D0D1A);
  static const cellEmpty     = Color(0xFF111122);
  static const cellBorder    = Color(0xFF1A1A2E);

  // Block piece colors
  static const List<Color> blockColors = [
    Color(0xFF7B61FF), // purple
    Color(0xFF00F5A0), // green
    Color(0xFFFF3E6C), // pink
    Color(0xFFFFD740), // amber
    Color(0xFF4FC3F7), // cyan
    Color(0xFFFF8A65), // orange
    Color(0xFFCE93D8), // lavender
  ];
}

class BlockConst {
  static const int    gridSize  = 8;
  static const double cellSize  = 38.0;
  static const double cellGap   = 3.0;
  static const double cellRadius = 6.0;
  static const int    coinEvery = 100;
}

// 18 block shapes – each is a list of [row, col] offsets
class BlockShapes {
  static const List<List<List<int>>> all = [
    [[0,0]],
    [[0,0],[0,1]],
    [[0,0],[1,0]],
    [[0,0],[1,0],[2,0],[2,1]],
    [[0,1],[1,1],[2,0],[2,1]],
    [[0,0],[0,1],[0,2],[1,1]],
    [[0,1],[0,2],[1,0],[1,1]],
    [[0,0],[0,1],[1,1],[1,2]],
    [[0,0],[0,1],[1,0],[1,1]],
    [[0,0],[0,1],[0,2]],
    [[0,0],[1,0],[2,0]],
    [[0,0],[0,1],[0,2],[0,3]],
    [[0,0],[1,0],[2,0],[3,0]],
    [[0,0],[0,1],[0,2],[0,3],[0,4]],
    [[0,0],[1,0],[2,0],[3,0],[4,0]],
    [[0,0],[0,1],[0,2],[1,0],[2,0]],
    [[0,0],[0,1],[0,2],[1,2],[2,2]],
    [[0,1],[1,0],[1,1],[1,2],[2,1]],
  ];
}
