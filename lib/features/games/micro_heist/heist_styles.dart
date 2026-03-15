import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────
class HeistColors {
  static const background = Color(0xFF0A0A12);
  static const surface = Color(0xFF13131F);
  static const primary = Color(0xFF7B61FF);
  static const accent = Color(0xFF00F5A0);
  static const energy = Color(0xFFFF3E6C);
  static const warn = Color(0xFFFFD740);
  static const textPrimary = Color(0xFFF2F2FF);
  static const textSecondary = Color(0xFF9090B0);

  // Grid cells
  static const cellFloor = Color(0xFF0F0F1E);
  static const cellWall = Color(0xFF1A1A30);
  static const cellWallEdge = Color(0xFF2A2A50);
  static const cellLoot = Color(0xFFFFD740);
  static const cellExit = Color(0xFF00F5A0);
  static const cellThief = Color(0xFF7B61FF);
  static const laser = Color(0xFFFF3E6C);
  static const laserGlow = Color(0x55FF3E6C);
  static const laserSafe = Color(0xFF00F5A0);
}

// ─────────────────────────────────────────────
//  GAME CONSTANTS
// ─────────────────────────────────────────────
class HeistConst {
  static const int cols = 9;
  static const int rows = 12;
  static const double cellSize = 38.0; // px per grid cell
  static const double thiefSize = 28.0;
  static const double lootSize = 22.0;
  static const double laserWidth = 3.0;

  // Time bonus: coins per second remaining
  static const double timeBonusMult = 0.15;

  // Laser speeds per difficulty tier (cells/second sweep rate)
  static const List<double> laserSpeeds = [1.2, 1.6, 2.1, 2.7, 3.4];
}

// ─────────────────────────────────────────────
//  CELL TYPES
// ─────────────────────────────────────────────
enum CellType { floor, wall, loot, exit }

// ─────────────────────────────────────────────
//  LASER DIRECTION
// ─────────────────────────────────────────────
enum LaserAxis { horizontal, vertical }

// ─────────────────────────────────────────────
//  LASER DEFINITION
// ─────────────────────────────────────────────
class LaserDef {
  final LaserAxis axis;
  final int fixedIndex; // row (if horizontal) or col (if vertical)
  final int sweepStart; // tile start of sweep range
  final int sweepEnd; // tile end of sweep range
  final double phase; // initial phase 0.0–1.0

  const LaserDef({
    required this.axis,
    required this.fixedIndex,
    required this.sweepStart,
    required this.sweepEnd,
    this.phase = 0.0,
  });
}

// ─────────────────────────────────────────────
//  LEVEL DEFINITION
// ─────────────────────────────────────────────
class LevelDef {
  final List<String>
      grid; // 12 rows × 9 cols, chars: ' '=floor '#'=wall '$'=loot 'E'=exit 'T'=thief start
  final List<LaserDef> lasers;
  final int timeLimitSec;
  final String title;

  const LevelDef({
    required this.grid,
    required this.lasers,
    required this.timeLimitSec,
    required this.title,
  });
}

// ─────────────────────────────────────────────
//  LEVELS  (5 levels, difficulty ramps up)
// ─────────────────────────────────────────────
const List<LevelDef> kLevels = [
  // ── LEVEL 1 ────────────────────────────────
  LevelDef(
    title: 'The Lobby',
    timeLimitSec: 25,
    grid: [
      '#########',
      '#       #',
      '#  ###  #',
      '#  # #  #',
      '#T # #  #',
      '#  # #  #',
      '#    \$  #',
      '#  ###  #',
      '#       #',
      '#  ###  #',
      '#      E#',
      '#########',
    ],
    lasers: [
      LaserDef(
          axis: LaserAxis.horizontal,
          fixedIndex: 3,
          sweepStart: 1,
          sweepEnd: 7,
          phase: 0.0),
    ],
  ),

  // ── LEVEL 2 ────────────────────────────────
  LevelDef(
    title: 'Security Wing',
    timeLimitSec: 22,
    grid: [
      '#########',
      '#T      #',
      '#  ###  #',
      '#  #    #',
      '#  # ## #',
      '#    #  #',
      '#  # #  #',
      '#  # #\$ #',
      '#    #  #',
      '#  ###  #',
      '#      E#',
      '#########',
    ],
    lasers: [
      LaserDef(
          axis: LaserAxis.horizontal,
          fixedIndex: 2,
          sweepStart: 1,
          sweepEnd: 7,
          phase: 0.0),
      LaserDef(
          axis: LaserAxis.vertical,
          fixedIndex: 5,
          sweepStart: 2,
          sweepEnd: 9,
          phase: 0.5),
    ],
  ),

  // ── LEVEL 3 ────────────────────────────────
  LevelDef(
    title: 'The Vault',
    timeLimitSec: 20,
    grid: [
      '#########',
      '#T  #   #',
      '#   #   #',
      '#   # \\\$ #',
      '#   ### #',
      '#       #',
      '# #######',
      '#       #',
      '#  ###  #',
      '#  # #  #',
      '#    # E#',
      '#########',
    ],
    lasers: [
      LaserDef(
          axis: LaserAxis.horizontal,
          fixedIndex: 2,
          sweepStart: 0,
          sweepEnd: 4,
          phase: 0.0),
      LaserDef(
          axis: LaserAxis.vertical,
          fixedIndex: 3,
          sweepStart: 0,
          sweepEnd: 4,
          phase: 0.3),
      LaserDef(
          axis: LaserAxis.vertical,
          fixedIndex: 5,
          sweepStart: 0,
          sweepEnd: 8,
          phase: 0.6),
    ],
  ),

  // ── LEVEL 4 ────────────────────────────────
  LevelDef(
    title: 'Double Cross',
    timeLimitSec: 18,
    grid: [
      '#########',
      '#T      #',
      '# ##### #',
      '#       #',
      '# ##### #',
      '#   \$   #',
      '# ##### #',
      '#       #',
      '# ##### #',
      '#      E#',
      '#       #',
      '#########',
    ],
    lasers: [
      LaserDef(
          axis: LaserAxis.horizontal,
          fixedIndex: 3,
          sweepStart: 0,
          sweepEnd: 8,
          phase: 0.0),
      LaserDef(
          axis: LaserAxis.horizontal,
          fixedIndex: 7,
          sweepStart: 0,
          sweepEnd: 8,
          phase: 0.5),
      LaserDef(
          axis: LaserAxis.vertical,
          fixedIndex: 4,
          sweepStart: 0,
          sweepEnd: 11,
          phase: 0.25),
    ],
  ),

  // ── LEVEL 5 ────────────────────────────────
  LevelDef(
    title: 'Penthouse',
    timeLimitSec: 15,
    grid: [
      '#########',
      '#T  # \$ #',
      '#   #   #',
      '#   ### #',
      '#       #',
      '### # ###',
      '#   #   #',
      '#   # E #',
      '# ###   #',
      '#   # # #',
      '#     # #',
      '#########',
    ],
    lasers: [
      LaserDef(
          axis: LaserAxis.horizontal,
          fixedIndex: 2,
          sweepStart: 0,
          sweepEnd: 4,
          phase: 0.0),
      LaserDef(
          axis: LaserAxis.vertical,
          fixedIndex: 4,
          sweepStart: 0,
          sweepEnd: 5,
          phase: 0.2),
      LaserDef(
          axis: LaserAxis.horizontal,
          fixedIndex: 6,
          sweepStart: 3,
          sweepEnd: 8,
          phase: 0.5),
      LaserDef(
          axis: LaserAxis.vertical,
          fixedIndex: 6,
          sweepStart: 5,
          sweepEnd: 11,
          phase: 0.7),
    ],
  ),
];

// ─────────────────────────────────────────────
//  GRID PARSER
// ─────────────────────────────────────────────
class GridParser {
  static List<List<CellType>> parse(List<String> raw) {
    return raw.map((row) {
      return row.split('').map((c) {
        switch (c) {
          case '#':
            return CellType.wall;
          case '\$':
            return CellType.loot;
          case 'E':
            return CellType.exit;
          default:
            return CellType.floor;
        }
      }).toList();
    }).toList();
  }

  static ({int row, int col}) findThief(List<String> raw) {
    for (int r = 0; r < raw.length; r++) {
      for (int c = 0; c < raw[r].length; c++) {
        if (raw[r][c] == 'T') return (row: r, col: c);
      }
    }
    return (row: 1, col: 1);
  }

  static ({int row, int col})? findLoot(List<String> raw) {
    for (int r = 0; r < raw.length; r++) {
      for (int c = 0; c < raw[r].length; c++) {
        if (raw[r][c] == '\$') return (row: r, col: c);
      }
    }
    return null;
  }

  static ({int row, int col})? findExit(List<String> raw) {
    for (int r = 0; r < raw.length; r++) {
      for (int c = 0; c < raw[r].length; c++) {
        if (raw[r][c] == 'E') return (row: r, col: c);
      }
    }
    return null;
  }
}
