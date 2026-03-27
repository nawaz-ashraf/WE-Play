import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  WOOD BLOCK – COLORS & CONSTANTS
// ─────────────────────────────────────────────

class WoodColors {
  static const background    = Color(0xFF0A0A12);
  static const surface       = Color(0xFF13131F);
  static const textPrimary   = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);

  // Board
  static const boardBg       = Color(0xFF1A0E00);
  static const cellEmpty     = Color(0xFF2A1A00);
  static const cellBorder    = Color(0xFF3A2500);
  static const boardFrame    = Color(0xFF5A3000);

  // Wood block colors (warm tones)
  static const List<Color> woodColors = [
    Color(0xFFCD853F), // peru
    Color(0xFFD2691E), // chocolate
    Color(0xFFDEB887), // burlywood
    Color(0xFF8B4513), // saddle brown
    Color(0xFFA0522D), // sienna
    Color(0xFFFF8C42), // orange wood
    Color(0xFFFFB347), // mango
  ];

  // UI accents
  static const primary       = Color(0xFFCD853F);
  static const accent        = Color(0xFFFFD740);
  static const energy        = Color(0xFFFF3E6C);
}

class WoodConst {
  static const int    gridSize   = 9;
  static const double cellSize   = 34.0;
  static const double cellGap    = 2.5;
  static const double cellRadius = 4.0;
  static const int    coinEvery  = 80;
}

class WoodShapes {
  static const List<List<List<int>>> all = [
    [[0,0]],
    [[0,0],[0,1]],
    [[0,0],[1,0]],
    [[0,0],[0,1],[0,2]],
    [[0,0],[1,0],[2,0]],
    [[0,0],[0,1],[0,2],[0,3]],
    [[0,0],[1,0],[2,0],[3,0]],
    [[0,0],[0,1],[0,2],[0,3],[0,4]],
    [[0,0],[1,0],[2,0],[3,0],[4,0]],
    [[0,0],[0,1],[1,0],[1,1]],
    [[0,0],[0,1],[0,2],[1,0],[1,1],[1,2]],
    [[0,0],[0,1],[1,0],[1,1],[2,0],[2,1]],
    [[0,0],[1,0],[2,0],[2,1]],
    [[0,1],[1,1],[2,0],[2,1]],
    [[0,0],[0,1],[0,2],[1,1]],
    [[0,0],[0,1],[1,0]],
    [[0,0],[0,1],[1,1],[1,2]],
    [[0,1],[0,2],[1,0],[1,1]],
  ];
}
